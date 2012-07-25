%% @doc Wrapper for mnesia.

%% @author Martynas <martynasp@gmail.com>

-module(perforator_ci_db).

-include_lib("stdlib/include/qlc.hrl").
-include("perforator_ci.hrl").

%% API
-export([
    write_project/1,

    get_project/1,
    get_projects/0,
    get_builds/1,
    get_test_builds/3,

    create_build/1,
    get_last_build/1,
    get_unfinished_builds/1,
    finish_build/3,
    get_build/1,
    get_previous_build_id/1,

    wait_for_db/0,
    init/0,
    create_tables/0,
    dump/1
]).

%% ============================================================================
%% API
%% ============================================================================

%% @doc Create/modify a project.
-spec write_project(#project{}) -> ok.
write_project(#project{}=P) ->
    transaction(fun () -> ok = mnesia:write(P) end).

%% @doc Creates new build
-spec create_build({
        perforator_ci_types:project_id(), perforator_ci_types:timestamp(),
        perforator_ci_types:commit_id(), list()}) ->
            #project_build{}.
create_build({ProjectID, TS, CommitID, Info}) ->
    transaction(
        fun () ->
            % Get next global and local id
            ID =
                case mnesia:last(project_build) of
                    '$end_of_table' -> 1;
                    N when is_integer(N) -> N + 1
                end,
            LID =
                case mnesia:index_read(project_build, ProjectID,
                        #project_build.project_id) of
                    [] -> 1;
                    Bs when is_list(Bs) ->
                        #project_build{local_id=LN} =
                            hd(sort_builds(Bs, desc)),
                        LN + 1
                end,
            % Write
            Build =
                #project_build{
                    id = ID,
                    local_id = LID,
                    project_id = ProjectID,
                    timestamp = TS,
                    commit_id = CommitID,
                    info = Info
                },
            ok = mnesia:write(Build),

            Build
        end).

%% @doc Returns all unfinished (sorted) builds.
-spec get_unfinished_builds(perforator_ci_types:project_id()) ->
        [#project_build{}].
get_unfinished_builds(ProjectID) ->
    sort_builds(transaction(
        fun () ->
            mnesia:index_match_object(
                #project_build{project_id=ProjectID, finished=false, _='_'},
                #project_build.project_id
            )
        end
    ), asc).

%% @doc Returns all test runs of a single test case.
%% @todo do proper specs
-spec get_test_builds(perforator_ci_types:project_id(), TestSuite::binary(),
    TestName::binary()) ->
        [TestData :: term()].
%% @todo refactor this to return all test data, not only test data relevant for
%% HTTP request.
get_test_builds(ProjectId, SuiteName, TestName) ->
    Builds = [B || #project_build{finished=F}=B <- get_builds(ProjectId),
        F =:= true],
    MappedBuilds = [{Build#project_build.id, Build#project_build.info} ||
            Build <- Builds],
    lists:flatmap(fun ({BuildId, TestData}) ->
        TestSuites = proplists:get_value(suites, TestData, []),
        SuiteData = proplists:get_value(SuiteName, TestSuites, []),
        TestCases = proplists:get_value(test_cases, SuiteData, []),
        TestCase = proplists:get_value(TestName, TestCases, []),
        case proplists:get_value(result, TestCase) of
            undefined -> [];
            Result -> [{BuildId, Result}]
        end
    end, MappedBuilds).

%% @doc Returns last project build.
-spec get_last_build(perforator_ci_types:project_id()) ->
        #project_build{} | undefined.
get_last_build(ProjectID) ->
    transaction(
        fun () ->
            case mnesia:index_read(project_build, ProjectID,
                    #project_build.project_id) of
                [] -> undefined;
                Bs when is_list(Bs) -> hd(sort_builds(Bs, desc))
            end
        end).

-spec get_previous_build_id(perforator_ci_types:build_id()) ->
        perforator_ci_types:build_id() | undefined.
get_previous_build_id(ID) ->
    transaction(
        fun () ->
            [#project_build{local_id=LID, project_id=PID}] =
                mnesia:read(project_build, ID),
            case mnesia:index_match_object(
                    #project_build{project_id=PID, local_id=LID-1, _='_'},
                    #project_build.project_id) of
                [#project_build{id=ID1}] -> ID1;
                [] -> undefined;
                _ -> undefined
            end
        end).

%% @doc Updates build status to finished and appends info.
%% @throws {build_not_found, BuildID}.
-spec finish_build(perforator_ci_types:build_id(), list(), boolean()) -> ok.
finish_build(BuildID, Info, Success) ->
    transaction(
        fun () ->
            case mnesia:read(project_build, BuildID) of
                [#project_build{}=B] ->
                    Finished =
                        if
                            Success -> true;
                            true -> failure
                        end,
                    ok = mnesia:write(
                        B#project_build{
                            finished = Finished,
                            info = Info
                        });
                [_] ->
                    throw({build_not_found, BuildID})
            end
        end).

%% @doc Returns #project.
%% @throws {project_not_found, ID}.
-spec get_project(perforator_ci_types:project_id()) -> #project{}.
get_project(ID) ->
    transaction(
        fun () ->
            case mnesia:read(project, ID) of
                [] -> throw({project_not_found, ID});
                [#project{}=P] -> P
            end
        end).

%% @doc Returns #project_build.
%% @throws {build_not_found, ID}.
-spec get_build(perforator_ci_types:build_id()) -> #project_build{}.
get_build(ID) ->
    transaction(
        fun () ->
            case mnesia:read(project_build, ID) of
                [] -> throw({build_not_found, ID});
                [#project_build{}=B] -> B
            end
        end).

%% @doc Returns project builds.
get_builds(ProjectID) ->
    sort_builds(
        transaction(
            fun () ->
                mnesia:index_read(project_build, ProjectID,
                        #project_build.project_id)
            end), desc).

%% @doc Returns #project's.
-spec get_projects() -> [#project{}].
get_projects() ->
    transaction(fun () -> mnesia:match_object(#project{_='_'}) end).

%% @doc Wait till all tables are reachable.
wait_for_db() ->
    mnesia:wait_for_tables([project, project_build], 42000). % @todo Fix

%% ============================================================================
%% DB Init
%% ============================================================================

%% @doc Creates mnesia schema and tables.
%% WARNING: destroys all data!!!
init() ->
    mnesia:stop(),
    % Schema
    mnesia:delete_schema([node()]),
    mnesia:create_schema([node()]),

    ok = mnesia:start(),

    create_tables().

create_tables() ->
    mnesia:delete_table(project),
    {atomic, ok} = mnesia:create_table(project, [
        {type, ordered_set},
        {attributes, record_info(fields, project)},
        {disc_copies, [node()]}
    ]),

    % @todo Maybe add project_build to #project.builds
    mnesia:delete_table(project_build),
    {atomic, ok} = mnesia:create_table(project_build, [
        {type, ordered_set},
        {attributes, record_info(fields, project_build)},
        {index, [#project_build.project_id, #project_build.commit_id]},
        {disc_copies, [node()]}
    ]),

    ok.

%% ============================================================================
%% Helpers
%% ============================================================================

%% @doc Executes transaction with given funs or fun.
%% @throws {aborted_transaction, term()}.
-spec transaction([fun()] | fun()) -> term().
transaction(Funs) when is_list(Funs) ->
    Fun = fun () -> [F() || F <- Funs] end,
    transaction(Fun);

transaction(Fun) ->
    case mnesia:transaction(Fun) of
        {atomic, Return} -> Return;
        {aborted, Reason} -> throw({aborted_transaction, Reason})
    end.

-spec sort_builds([#project_build{}], asc|desc) -> [#project_build{}].
sort_builds(Builds, Order) ->
    Fun =
        case Order of
            asc ->
                fun (#project_build{id=A}, #project_build{id=B}) -> A < B end;
            desc ->
                fun (#project_build{id=A}, #project_build{id=B}) -> A >= B end
        end,

    lists:sort(Fun, Builds).

%% @doc dump table
dump(Table) ->
    Fun = fun() ->
        qlc:eval(qlc:q([R || R <- mnesia:table(Table)]))
    end,
    transaction(Fun).
