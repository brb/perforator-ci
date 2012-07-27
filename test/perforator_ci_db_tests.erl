%% @author Martynas <martynasp@gmail.com>

-module(perforator_ci_db_tests).

-include_lib("eunit/include/eunit.hrl").

-include("perforator_ci.hrl").

-compile(export_all).

%% ===========================================================================

db_test_() ->
    {foreach, 
        fun () ->
            perforator_ci:init(),
            perforator_ci:start()
        end,
        fun (_) -> perforator_ci:stop() end,
        [
            {"Write project", fun test_write_project/0},
            {"Create build", fun test_create_build/0},
            {"Get test runs", fun test_get_test_builds/0}
        ]
    }.

%% ============================================================================

test_write_project() ->
    ?assertEqual(ok, perforator_ci_db:write_project(#project{id= <<"1">>})),
    ?assertMatch(#project{id= <<"1">>}, perforator_ci_db:get_project(<<"1">>)),

    ?assertEqual(
        ok,
        perforator_ci_db:write_project(
            #project{id= <<"1">>, info=[{repo_url, "r"}]})
    ),
    ?assertMatch(
        #project{id= <<"1">>, info=[{repo_url, "r"}]},
        perforator_ci_db:get_project(<<"1">>)
    ).

test_create_build() ->
    ?assertMatch(
        #project_build{id=1, local_id=1},
        perforator_ci_db:create_build({42, 123, <<"cid0">>, []})),
    ?assertMatch(
        #project_build{id=2, local_id=1},
        perforator_ci_db:create_build({666, 123, <<"cid1">>, []})),
    ?assertMatch(
        #project_build{id=3, local_id=2},
        perforator_ci_db:create_build({42, 123, <<"cid2">>, []})),

    ?assertMatch(
        1,
        perforator_ci_db:get_previous_build_id(3)),
    ?assertMatch(
        undefined,
        perforator_ci_db:get_previous_build_id(1)),

    ?assertMatch(
        #project_build{commit_id= <<"cid2">>},
        perforator_ci_db:get_last_build(42)),
    ?assertMatch(
        [#project_build{id=2}],
        perforator_ci_db:get_unfinished_builds(666)),

    ?assertEqual(ok, perforator_ci_db:finish_build(2, [omg], false)),
    ?assertMatch(
        #project_build{id=2, finished=failure, info=[omg]},
        perforator_ci_db:get_build(2)),
    ?assertMatch(
        [],
        perforator_ci_db:get_unfinished_builds(666)).

test_get_test_builds() ->
        ?assertMatch(
            #project_build{id=1},
            perforator_ci_db:create_build({42, 123, <<"cid0">>, []})),
        Data = [{suites, [{<<"test_suite_1">>, [{test_cases,
            [{<<"test_case_1">>, [
                {successful, true},
                {result, [
                    {failures, 1},
                    {duration, [
                        {min, 3},
                        {max, 4},
                        {mean, 6}
                    ]}
                ]}
            ]}]
        }]}]}],
        ?assertEqual(ok, perforator_ci_db:finish_build(1, Data, true)),
        timer:sleep(100),
        Results = perforator_ci_db:get_test_builds(42, <<"test_suite_1">>,
            <<"test_case_1">>),
        ?assertNotEqual([], Results).

