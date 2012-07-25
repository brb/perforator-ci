%% @author Martynas <martynasp@gmail.com>
%% @todo Fix names

-module(perforator_ci_json_tests).

-include_lib("eunit/include/eunit.hrl").

-include("perforator_ci.hrl").

-compile(export_all).

%% ============================================================================

from_project_new_test() ->
    JSON = <<"
        {
            \"id\": \"id\",
            \"branch\" : \"branch\",
            \"repo_url\" : \"url\",
            \"build_instructions\" : [ \"one\", \"two\" ],
            \"polling_strategy\": {\"time\": 10}
        }
    ">>,

    ?assertEqual(
        {<<"id">>, "url", "branch", perforator_ci_git, {time, 10},
            ["one", "two"], []},
        from(project_new, dec(JSON))).

from_project_update_test() ->
    JSON = <<"
        {
            \"id\": \"id\",
            \"branch\" : \"branch\",
            \"repo_url\" : \"url\",
            \"build_instructions\" : [ \"one\", \"two\" ],
            \"polling_strategy\": \"ondemand\"
        }
    ">>,

    ?assertEqual(
        {<<"id">>, "url", "branch", perforator_ci_git, on_demand,
            ["one", "two"], []},
        from(project_update, dec(JSON))).

to_build_test() ->
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
    JSON = perforator_ci_json:to(build, #project_build{info=Data}),
    _Enc = jiffy:encode(JSON). %% it happens -- good enough.

to_test_runs_test() ->
    Data = [{1,[{failures,1},{duration,[{min,3},{max,4},{mean,6}]}]}],
    JSON = perforator_ci_json:to(test_runs, Data),
    _Enc = jiffy:encode(JSON). %% it happens -- good enough.

%% ============================================================================
%% Helpers
%% ============================================================================

from(Type, Data) ->
    perforator_ci_json:from(Type, Data).

dec(JSON) ->
    jiffy:decode(JSON).
