%% ============================================================================
%% Record definitions
%% ============================================================================

-record(project, {
    id :: perforator_ci_types:project_id(), % unique
    info :: [perforator_ci_types:project_info()] % see 'perforator_ci_types'
    % for possible values.
}).

-record(project_build, {
    id=0 :: perforator_ci_types:build_id(), % unique
    commit_id :: perorator_ci_types:commit_id(), % secondary index
    project_id=0 :: perforator_ci_types:project_id(), % secondary index
    local_id=0 :: perforator_ci_types:build_id(), % id in a project scope

    state=pending :: finished | failed | pending,

    timestamp :: perforator_ci_types:timestamp(),

    info=[] :: list(), % @todo specify
    finished=false :: boolean() | failure
}).

%% ============================================================================
%% Defaults
%% ============================================================================

-define(HTTP_PORT, 8080).
-define(LIST_COUNT, 10).
-define(REPOS_DIR, "priv/repos").
-define(BUILDER_REPOS_DIR, "priv/builder_repos").

%% ============================================================================
%% Log utils
%% ============================================================================

% Use these only for pretty prints in tests/console!
-define(DEFAULT_INFO(Msg), [
    {pid, self()},
    {source, ?FILE ++ ":" ++ integer_to_list(?LINE)},
    {message, Msg}
]).

-define(error(Msg, Opts),
    error_logger:error_report(?DEFAULT_INFO(Msg) ++ Opts)).

-define(warning(Msg, Opts),
    error_logger:warning_report(?DEFAULT_INFO(Msg) ++ Opts)).

-define(info(Msg, Opts),
    error_logger:info_report(?DEFAULT_INFO(Msg) ++ Opts)).

% Mute chatty expressions
-define(silent(Level, Expr), ( % Level = info | warning | error | alert ...
    fun() ->
        Lager_OldLevel = lager:get_loglevel(lager_console_backend),
        lager:set_loglevel(lager_console_backend, Level),
        error_logger:tty(false),
        try
            timer:sleep(10),
            Expr,
            timer:sleep(10)
        after
            lager:set_loglevel(lager_console_backend, Lager_OldLevel),
            error_logger:tty(true)
        end
    end)()).

-define(mute(Expr), (
    fun () ->
        error_logger:tty(false),
        timer:sleep(10),
        Expr,
        error_logger:tty(true)
    end)()).

%% ============================================================================
%% Stuff
%% ============================================================================

-define(FMT(Msg, Args), lists:flatten(io_lib:format(Msg, Args))).
-define(BIN(X), perforator_ci_utils:to_bin(X)).
-define(ETRACE(X),
    {element(1, X),
        fun () ->
            try
                (element(2, X))()
            catch
                C:R ->
                    ?error("screw you, eunit.", [{c, C}, {r, R},
                        {trace, erlang:get_stacktrace()}])
            end
        end
    }).
