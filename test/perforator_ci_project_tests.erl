%% @author Martynas <martynasp@gmail.com>

-module(perforator_ci_project_tests).

-include_lib("eunit/include/eunit.hrl").

-include("perforator_ci.hrl").

-compile(export_all).

-define(REPO, "test.git").
-define(REPOS, "repos").

%% ============================================================================

project_test_() ->
    {foreach, 
        fun () ->
            application:load(perforator_ci),
            application:set_env(perforator_ci, repo_path, ?REPOS),

            perforator_ci_utils:sh(?FMT("rm -rf ~p", [?REPO])),
            perforator_ci_utils:sh(?FMT("rm -rf ~p", [?REPOS])),

            perforator_ci_utils:sh(?FMT("git init ~p", [?REPO])),
            perforator_ci_utils:sh(?FMT("mkdir ~p", [?REPOS])),

            perforator_ci:init(),
            perforator_ci:start()
        end,
        fun (_) ->
            perforator_ci:stop()
        end,
        [
            ?ETRACE({"Start project/recovery", fun test_start_project/0}),
            {"Ping -> build", fun test_ping_and_build/0}
        ]
    }.

%% ============================================================================

test_start_project() ->
    ok = perforator_ci:start_project(
        #project{
            id = <<"1">>,
            info = [
                {repo_url, ?REPO},
                {branch, "origin/master"},
                {repo_backend,  perforator_ci_git},
                {polling, {time, 5000}}
            ]
        }),
    ok = perforator_ci:start_project(
        #project{
            id = <<"1">>,
            info = [
                {repo_url, ?REPO},
                {branch, "origin/master"},
                {repo_backend,  perforator_ci_git},
                {polling, {time, 5000}}
            ]
        }),

    ?assertMatch(
        [_], % exactly one child is started
        supervisor:which_children(perforator_ci_project_sup)
    ),

    ?silent(error,
        begin
            application:stop(perforator_ci),
            application:start(perforator_ci),
            timer:sleep(50)
        end),

    ?assertMatch(
        [_], % the same child is up
        supervisor:which_children(perforator_ci_project_sup)
    ),
    ?assert(perforator_ci_project:is_project_running(<<"1">>)).

test_ping_and_build() ->
    ok = meck:new(perforator_ci_git, [no_link, passthrough]),
    meck:expect(perforator_ci_git, check_for_updates,
        fun
            (_, _, <<"random_commit_id">>) -> undefined;
            (_, _, _) -> <<"random_commit_id">>
        end),
    ok = meck:new(perforator_ci_builder, [no_link, passthrough]),
    ok = meck:expect(perforator_ci_builder, build, 2, ok),

    ok = perforator_ci:start_project(
        #project{
            id = <<"1">>,
            info = [
                {repo_url, ?REPO},
                {branch, "origin/master"},
                {repo_backend, perforator_ci_git},
                {polling, {time, 50}}
            ]
        }),
    timer:sleep(100),

    ?assert(meck:validate(perforator_ci_git)),
    ?assert(meck:validate(perforator_ci_builder)),

    ?assertMatch(
        [#project_build{id=1, commit_id= <<"random_commit_id">>}],
        perforator_ci_db:get_unfinished_builds(<<"1">>)
    ),

    ok = gen_server:call(perforator_ci_project:get_pid(<<"1">>),
        {build_finished, 1, [omg], true}),
    timer:sleep(50),

    ?assertMatch([], perforator_ci_db:get_unfinished_builds(<<"1">>)),

    ok = meck:unload([perforator_ci_builder, perforator_ci_git]).
