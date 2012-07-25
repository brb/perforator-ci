%% @author Martynas <martynasp@gmail.com>

-module(perforator_ci_types).

-export_type([
    project_id/0,
    polling_strategy/0,
    build_instructions/0,

    repo_url/0,
    branch/0,
    repo_backend/0,

    build_id/0,
    build_local_id/0,
    commit_id/0,
    timestamp/0,

    pubsub_group/0
]).

%% ============================================================================

-type project_id() :: binary().
-type polling_strategy() :: {time, integer()} | on_demand. % Time is in ms!
-type build_instructions() :: list().

-type repo_url() :: list().
-type branch() :: list().
-type repo_backend() :: perforator_git_backend. % maybe CVS one day

-type build_id() :: integer().
-type build_local_id() :: integer().
-type commit_id() :: binary() | undefined.
-type timestamp() :: integer().

-type pubsub_group() :: perforator_ci_project | perforator_ci_builder.

-type test_results() :: term(). %% @todo
