%% `perforator_ci` is a continious performance integration tool which
%% uses `perforator` output statistics. It can nicely track and show
%% performance tests degradations.
%%
%% `perforator_ci` consists of 3 "major" objects:
%% * projects (`perforator_ci_project`)
%% * builders (`perforator_ci_builder`)
%% * web backend
%%
%% Each project tracks changes on a repository branch and asks builders to
%% build changes. Currently, only Git is supported.
%%
%% Builders (only one per host, because more builders can screw up `perforator`
%% results) try to execute list of commands, including command used for
%% generating perf reports, and send results to projects.
%%
%% Project keeps track of build results and publishes them to web backend (on
%% demand).
%%
%% That's it. Want to sleep.
%%
%% @author Martynas <martynasp@gmail.com>

-module(perforator_ci).

-include("perforator_ci.hrl").

%% API
-export([
    start_project/1,
    update_project/1,
    get_builders/0
]).

-export([start/0, stop/0, init/0]).

%% ============================================================================
%% API
%% ============================================================================

%% @doc Stores project in DB and starts project handler process.
-spec start_project(#project{}) -> ok.
start_project(#project{id=ID, repo_url=RUrl, repo_backend=Mod}=P) ->
    % Store project in DB:
    ?error("WTF", [P]),
    ok = perforator_ci_db:write_project(P),
    % Clone project repo:
    Mod:clone(RUrl, perforator_ci_utils:repo_path(ID)), 
    % Check, maybe project is already running, so there is no need to start a
    % new instance:
    case perforator_ci_project:is_project_running(ID) of
        true -> ok; % do nothing, already started
        false -> {ok, _} = perforator_ci_project_sup:start_project(ID)
    end,

    ok.

%% @doc Updates project info in DB and in project handler.
-spec update_project(#project{}) -> ok.
update_project(#project{id=ID}=P) ->
    % Update DB:
    ok = perforator_ci_db:write_project(P),
    % Restart project handler, so that changes could happen:
    exit(perforator_ci_project:get_pid(ID), '$restart'),

    ok.

%% @doc Returns builders list (nodes where they reside) with their queue size.
-spec get_builders() -> [{node(), integer()}].
get_builders() ->
    [{B, perforator_ci_builder:get_queue_size(B)} ||
        B <-perforator_ci_builder:get_builders()].

%% ============================================================================
%% Start/Init
%% ============================================================================

%% @doc Starts the app with its deps.
%% Tries to reduce noise.
start() ->
    ?mute(begin
        application:start(compiler),
        application:start(syntax_tools),
        application:start(lager)
    end),
    ?silent(error, begin
        pg2:start(),
        application:start(mnesia),
        application:start(gproc),
        application:start(cowboy),
        application:start(perforator_ci)
    end).

%% @doc Stops the app and its deps.
stop() ->
    ?silent(error, begin
        application:stop(perforator_ci),
        application:stop(cowboy),
        application:stop(gproc),
        application:stop(mnesia)
    end),
    ?mute(begin
        application:stop(lager),
        application:stop(syntax_tools),
        application:stop(compiler)
    end).

%% @doc Creates mnesia schema and tables.
%% See perforator_ci_db:init/0 for more info.
init() ->
    perforator_ci_db:init().
