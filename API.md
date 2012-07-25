# WebSocket API

All application messages below are wrapped in the following:

    {
        err : null | string,
        msg : {} | Error,
        type : string
    }

## build_init

    {
        project : string,
        build_id : number,
        commit_id : string,
        timestamp: integer (unix time in seconds)
        modules : number,
        tests : number
    }

## build_finished

    {
        project : string,
        build_id : number,
        success : boolean,
        timestamp: integer (unix time in seconds)
    }

## queue_size

    {
        name: string,
        queue_size: integer
    }

# REST API (prefixed with /api/1)

All responses below are wrapped in the following:

    {
        err : null | string,
        msg : {} | Error,
    }

## /builders

### Request

    null

### Response

    [{
        name : string,
        queue_size: integer
    }]

## /projects

### Request

    null

### Response

    [{
        id : string,
        branch : string,
        repo_url : string,
        build_instructions : [ string ],
        polling_strategy : "ondemand" | {
            time : integer
        }
    }]

## /project

### Request

    string (project id)

### Response

    {
        id : string,
        branch : string,
        repo_url : string,
        build_instructions : [ string ],
        polling_strategy : "ondemand" | {
            time : integer
        }
    }


## /project/new

### Request

    {
        id : string,
        branch : string,
        repo_url : string,
        build_instructions : [ string ],
        polling_strategy : "ondemand" | {
            time : integer
        }
    }

### Response

    null

## /project/update

### Request

    {
        id : string,
        branch : string,
        repo_url : string,
        build_instructions : [ string ],
        polling_strategy : "ondemand" | {
            time : integer
        }
    }

### Response

    null

## /builds

### Request

    string (project id)

### Response

    [{
        id : string,
        succeeded : boolean,
        finished : boolean,
        started : number (unix time in seconds),
        time : number (duration in milliseconds),
        modules : number,
        commit_id : string,
        tests : number
    }]

## /rebuild_now

### Request

    {
        project : string (project id),
        commit : string (commit id)
    }

### Response

    null

## /build_now

### Request

    string (project id)

### Response

    null

## /previous_build

### Request

    number (build id)

### Response

    null | number (id of previous build in the same project)

## /build

### Request

    number (build id)

### Response

        [{
            name : string,
            test_cases : [{
                name : string,
                successful: boolean,
                result : null | {
                    duration : {
                        min : number,
                        max : number,
                        mean : number
                    },
                    used_memory : {
                        min : number,
                        max : number,
                        mean : number
                    }
                    cpu_util : {
                        min : number,
                        max : number,
                        mean : number
                    }
                    cpu_load : {
                        min : number,
                        max : number,
                        mean : number
                    }
                }
            }]
        }]

## /test_builds

### Request

    {
        projectId : string,
        moduleName : string,
        testName : string
    }

### Response

    [{
        build_id: integer,
        duration : {
                        min : number,
                        max : number,
                        mean : number
                    },
        cpu_load : {
                        min : number,
                        max : number,
                        mean : number
                    },
        used_memory : {
                        min : number,
                        max : number,
                        mean : number
                    },
        cpu_util : {
                        min : number,
                        max : number,
                        mean : number
                    }
    }]

