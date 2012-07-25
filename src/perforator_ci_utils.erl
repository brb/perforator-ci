%% @doc Various stuff.

%% @author Martynas <martynasp@gmail.com>

-module(perforator_ci_utils).

-include("perforator_ci.hrl").

-export([
    timestamp/0,
    get_env/3,
    sh/1,
    sh/2,
    repo_path/1,
    to_bin/1
]).

%% ============================================================================
%% API
%% ============================================================================

-spec timestamp() -> perforator_ci_types:timestamp().
timestamp() ->
    {Mega, Sec, _} = erlang:now(),
    (Mega * 1000000 + Sec).

%% @doc Returns application env variable or default unless it exists.
get_env(App, Key, Default) ->
    case application:get_env(App, Key) of
        undefined -> Default;
        {ok, Val} -> Val
    end.

%% @doc Exec given command.
%% @throws {exec_error, {Command, ErrCode, Output}}.
-spec sh(list(), list()) -> list().
sh(Command, Opts0) ->
    Port = open_port({spawn, Command}, Opts0 ++ [
        exit_status, {line, 255}, stderr_to_stdout
    ]),

    case sh_receive_loop(Port, []) of
        {ok, Data} -> Data;
        {error, {ErrCode, Output}} ->
            throw({exec_error, {Command, ErrCode, Output}})
    end.

sh(Command) ->
    sh(Command, []).

sh_receive_loop(Port, Acc) ->
    receive
        {Port, {data, {eol, Line}}} -> sh_receive_loop(Port, [Line ++ "\n"|Acc]);
        {Port, {data, {noeol, Line}}} ->
            sh_receive_loop(Port, [Line|Acc]);
        {Port, {exit_status, 0}} ->
            {ok, lists:flatten(lists:reverse(Acc))};
        {Port, {exit_status, E}} ->
            {error, {E, lists:flatten(lists:reverse(Acc))}}
    end.

%% @doc Returns project repository path
repo_path(ProjectID) ->
    filename:join(
        perforator_ci_utils:get_env(perforator_ci, repos_path, ?REPOS_DIR),
        binary_to_list(ProjectID)
    ).

%% @doc No comments.
to_bin(X) when is_integer(X) ->
    list_to_binary(integer_to_list(X));
to_bin(X) when is_list(X) ->
    list_to_binary(X);
to_bin(X) when is_atom(X) ->
    list_to_binary(atom_to_list(X));
to_bin(X) when is_binary(X) ->
    X;
to_bin(X) ->
    list_to_binary(?FMT("~p", [X])).
