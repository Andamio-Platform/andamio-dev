# Navigate the Andamio API spec

## Before we start

The Andamio API has over a hundred endpoints. You don't need to remember them — you need to find the one you want in under a minute. The OpenAPI spec is the map.

## Where the spec lives

`specs/andamio-api.yaml` in the `andamio-dev` repository. If you have the plugin installed, it's on disk. Otherwise, it's in the public repo at [github.com/Andamio-Platform/andamio-dev](https://github.com/Andamio-Platform/andamio-dev).

Don't read it top to bottom. Jump in, find what you need, jump out.

## Three ways to find an endpoint

**grep.** Fastest when you know part of the path. Every endpoint starts with `/v2/`:

```bash
grep -n "/v2/course/student" specs/andamio-api.yaml
```

Path declarations sit under the `paths:` key — look for lines like `  /v2/course/student/credentials/list:`.

**IDE search.** Fuzzy-search for keywords ("credentials," "enrollment," "task," "assess"). Better when you don't remember the exact path fragment.

**Spec viewer.** Swagger UI, Redoc, Stoplight Studio, or the VS Code OpenAPI extension. Worth it for serious exploration; overkill for one-off lookups.

## Reading an endpoint entry

```yaml
/v2/course/student/credentials/list:
  post:
    tags:
      - course / student
    summary: List all courses the student is enrolled in with credential status
    parameters:
      - $ref: "#/components/parameters/XAPIKey"
      - $ref: "#/components/parameters/Authorization"
    responses:
      "200":
        description: Success
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/StudentCourseCredentialsResponse"
```

| Part | What to read | Notes |
|------|-------------|-------|
| **Path** | `/v2/course/student/credentials/list` | Combined with `api.andamio.io` for the full URL |
| **Method** | `post:` | Even reads can be POST in Andamio (request body filtering). Don't assume reads are GETs. |
| **Summary** | One-line description | Usually accurate enough to confirm the endpoint fits your task |
| **Parameters** | Auth headers, query params | `XAPIKey` + `Authorization` = needs both API key and JWT |
| **Responses** | `"200"` schema via `$ref` | Follow the JSON Pointer to `#/components/schemas/...` for the full shape |

`$ref` references point to schema definitions elsewhere in the file. Most editors and spec viewers follow them automatically.

## A worked lookup

Task: find the endpoint that lists public courses.

1. `grep -n "course/list" specs/andamio-api.yaml`
2. Find `/v2/course/list` in the `paths:` section. Summary: "List all public courses."
3. Method: GET. Parameter: `XAPIKey`. Response: `CourseListResponse`.
4. Follow the `$ref` to see the response shape: `data` array + `meta` object.

Under a minute with grep. Under five with a spec viewer.

## Your turn

Find the endpoint that returns the list of all valid `tx_type` values. Report its path and HTTP method.

You'll need this endpoint in Lesson 300.4. Finding it now is practice for the workflow you'll use every time.

## Rubric

The endpoint is `/v2/tx/types`. Method: `GET`. Takes an API key parameter. Response: a list of transaction type entries, each with a name and a build endpoint path.

If you also noticed that the response ties each `tx_type` to an endpoint path, you've anticipated what Lesson 300.4 teaches.

## What you just did

You have a workflow: grep the spec, read the entry, follow the refs. When the spec and other documentation disagree, the spec wins — it's what the API is actually serving.
