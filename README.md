# `esqc_gps`: standalone GPS quality control for Stata

**Author:** Attique Ur Rehman, Enterprise Analysis Unit, World Bank  
**Development assistance:** Developed with help of gpt-5.6 sol ultra.

`esqc_gps` turns the supplied Python GPS checker into a Stata 16+ command. It follows the same production pattern as ESQC's existing AI-assisted ISIC workflow:

## Quick GitHub installation

After the repository files are uploaded to the root of `arehman10/esqc_gps`, install from Stata with:

```stata
net install esqc_gps, from("https://raw.githubusercontent.com/arehman10/esqc_gps/main/") replace
```

Then verify:

```stata
which esqc_gps
which esqc_gps_log
help esqc_gps
```

See [`GITHUB_UPLOAD.md`](GITHUB_UPLOAD.md) for the one-time repository upload steps. Python dependencies are installed separately; see [Requirements](#requirements).

## Troubleshooting `r(601)` during GitHub installation

If Stata reports that `esqc_gps.pkg` was not found, the package files are not
at the repository root. Confirm that this raw URL opens and begins with `v 3`:

```text
https://raw.githubusercontent.com/arehman10/esqc_gps/main/esqc_gps.pkg
```

If it returns `404: Not Found`, extract the GitHub package and upload its
**contents** directly to the root of the `main` branch. Also confirm that
`stata.toc` begins with `v 3`; it must not contain `.gitignore` rules or other
unrelated content. See [`GITHUB_UPLOAD.md`](GITHUB_UPLOAD.md).

## How it works

1. an `.ado` command validates Stata syntax and protects the active dataset with `preserve`/`restore`;
2. a Java 11 Stata Function Interface (SFI) bridge exports only selected observations;
3. an embedded Python worker performs deterministic GIS checks and, when explicitly enabled, a second AI review with `gpt-5.6-luna` through the OpenAI Responses API;
4. Java validates the entire 11-column result contract before writing seven shadow variables and atomically publishing them in Stata.

The deterministic boundary check always runs first. `a3a` is treated as a union of allowed Admin1 areas: if a value contains several members, the GPS passes whenever it falls in any one of them. `a3x` is an exact-coordinate containment check: the reported district, town, suburb, locality, or other named area must contain the GPS point. A shared parent Admin2/LGA is useful context but is not proof of containment. AI is optional. It reviews unresolved a3a values, unresolved or apparent-mismatch a3x values, and `outside_country` boundary flags. Deterministic Admin1 decisions and deterministic a3x matches remain locked; only a high-confidence coordinate-aware AI match may clear a deterministic a3x mismatch caused by hierarchy or same-name ambiguity. Vision remains limited to outside-country polygon review because imagery does not define authoritative locality boundaries.

## Files

| File | Purpose |
|---|---|
| `esqc_gps.ado` | Stata command wrapper |
| `esqc_gps.sthlp` | Stata help file |
| `esqc_gps.jar` | Java 11 SFI bridge plus embedded Python worker |
| `esqc_gps_log.ado` / `.sthlp` | Locate and inspect the latest mandatory full audit log |
| `resources/gps_qc.py` | Reviewed Python worker source |
| `src/org/worldbank/esqc/GpsSfi.java` | Reviewed Java source |
| `requirements.txt` | Python runtime dependencies |
| `tools/build_jar.py` | Deterministic JAR builder and validator |
| `tools/validate_release.py` | Package and source-contract validator |
| `tests/` | Offline worker, Java/SFI-mock, and Stata smoke tests |
| `GITHUB_UPLOAD.md` | One-time instructions for uploading this package to the GitHub repository |

## Requirements

- Stata 16 or later
- Java 11 or later available to Stata
- Python 3.10 or later
- Python packages listed in `requirements.txt`

Install the Python dependencies into the same Python environment that Stata will launch:

```text
python -m pip install -r requirements.txt
```

When several Python installations are present, pass the executable explicitly through `python()`.

## Install in Stata

For a local installation, copy these five files to a directory on the Stata adopath:

```text
esqc_gps.ado
esqc_gps.sthlp
esqc_gps.jar
esqc_gps_log.ado
esqc_gps_log.sthlp
```

For example, place them in the personal PLUS directory shown by:

```stata
sysdir
```

Then verify:

```stata
which esqc_gps
help esqc_gps
```

The GitHub installation places the Stata wrapper, help files, and Java bridge on the ado-path. Install the Python dependencies separately into the Python environment that Stata will launch:

```text
python -m pip install pyshp shapely pyproj httpx pillow truststore certifi
```

## Deterministic use

```stata
use "export.dta", clear

esqc_gps, ///
    shapefile("WB_GAD_ADM2.zip") ///
    country("Australia") ///
    latitude(gps__Latitude) ///
    longitude(gps__Longitude) ///
    admin1(a3a) ///
    admin2(a3x)
```

The active dataset receives:

```text
esqc_gps_status
esqc_gps_flag
esqc_gps_admin1
esqc_gps_admin2
esqc_gps_a3a_status
esqc_gps_a3x_status
esqc_gps_detail
```

`esqc_gps_flag` is 0 only for final status `ok`; every other status is 1 and should be reviewed.

For example, when the GPS is in New South Wales, `a3a="NSW + ACT"` is a match because New South Wales is one member of that union. The extra ACT member does not create a mismatch. A concise successful detail is:

```text
OK: GPS in Tweed (A), New South Wales; a3a 'NSW + ACT' includes New South Wales; a3x 'Mooball' contains GPS.
```

## GPT-5.6 Luna use

AI is deliberately opt-in. Put the API key alone on the first nonblank line of a restricted text file, then run:

```stata
esqc_gps, ///
    shapefile("WB_GAD_ADM2.zip") ///
    country("Australia") ///
    latitude(gps__Latitude) ///
    longitude(gps__Longitude) ///
    admin1(a3a) ///
    admin2(a3x) ///
    id(technicalid) ///
    ai ///
    keyfile("O:/secure/openai.key") ///
    model("gpt-5.6-luna") ///
    reasoning(medium)
```

`gpt-5.6-luna` is the command's AI default. The exact supported model allowlist is:

```text
gpt-5.6
gpt-5.6-sol
gpt-5.6-terra
gpt-5.6-luna
```

The worker calls `POST /v1/responses` directly and uses:

- strict JSON Schema Structured Outputs through `text.format`;
- `store: true` on every request;
- `prompt_cache_key` plus `prompt_cache_options={mode: implicit, ttl: 30m}`;
- `parallel_tool_calls: false`;
- the requested reasoning effort;
- optional low-context `web_search` for coordinate-aware locality alignment;
- image input only for conservative review of `outside_country` cases; a high-confidence boundary clear is followed by nearest-Admin2 and reported-field evaluation.

The AI alignment prompt receives the exact coordinates, GPS-derived Admin1/Admin2 context, reported values, the country-specific Admin1 list, uniquely resolved `a3a` members, and lock indicators. It explicitly distinguishes parent-area membership from locality containment: two suburbs can share the same council or county while only one contains the point. Structured output includes per-field confidence and a short reason. Post-processing keeps Admin1 decisions locked, requires high confidence to clear a deterministic a3x mismatch, and never lets lower confidence clear a flag.

No OpenAI Python SDK is required.

## Data-flow and privacy controls

AI mode sends case-specific location information to OpenAI for unresolved a3a cases and unresolved/apparent-mismatch a3x cases. With web search enabled, the model may use the web-search tool. Vision is used only for `outside_country`: the worker first requests map tiles from the selected tile provider and then sends the composed images to OpenAI.

Use the following when a more restrictive data-flow policy is needed:

```stata
esqc_gps, ///
    shapefile("WB_GAD_ADM2.zip") country("Australia") ///
    latitude(gps__Latitude) longitude(gps__Longitude) ///
    admin1(a3a) admin2(a3x) ///
    ai keyfile("O:/secure/openai.key") ///
    model("gpt-5.6-luna") ///
    nowebsearch novision
```

Important controls:

- AI is off unless `ai` is specified.
- `ai` requires `keyfile()`; inherited `OPENAI_API_KEY`, `ESQC_AI_KEY`, and endpoint overrides are removed by the Java bridge.
- The key is passed only to the child process and is not written to the configuration file, result file, or log.
- `store` is hard-coded to `true` at request construction and is enforced again immediately before HTTP transmission.
- Full JSONL audit logging is mandatory, starts before QC or network activity, and fails closed if a durable local audit file cannot be created. Use `esqc_gps_log` to locate it.
- `ailog()` is an optional secondary AI-call summary. `ailogpayload` adds truncated payloads to that secondary log; neither option reduces the mandatory full audit.
- Google Hybrid is the default map source. Google Satellite, Google Roads, and OpenStreetMap remain selectable and must be reviewed for organizational policy and provider terms.

## Boundary inputs and CRS

`shapefile()` accepts:

- a `.shp` file;
- a ZIP containing a shapefile and sidecars; or
- a directory containing a shapefile.

The default field names are `NAM_0`, `NAM_1`, and `NAM_2`. Override them with `countryfield()`, `admin1field()`, and `admin2field()`.

A `.prj` CRS sidecar is required. Projected boundaries are transformed to EPSG:4326 with `pyproj`. `assumewgs84` bypasses the missing-CRS failure only when the layer has already been independently verified as longitude/latitude WGS84.

ZIP extraction rejects absolute paths, `..` traversal, symlinks, more than 10,000 members, and expanded archives larger than 4 GiB.

The default `snaptolerance(0)` does not snap points outside polygons. A positive value, in kilometres, can be used only where reviewed boundary-gap policy permits it.

## Result statuses

| Final status | Meaning |
|---|---|
| `ok` | Every nonmissing reported field agrees with the GPS-derived location. A vision-cleared boundary false positive reaches `ok` only after the reported fields also agree with the reviewed nearest Admin2. |
| `mismatch` | At least one reported field does not contain the GPS-derived location. For multi-value `a3a`, this means the GPS Admin1 is in none of the resolved members. |
| `reported_not_found` | At least one reported field could not be confidently placed. |
| `no_reported_location` | Both reported location fields are empty, though coordinates are valid and inside the boundary. |
| `outside_country` | The point is outside all selected-country Admin2 polygons after any configured tolerance/review. |
| `invalid` | Coordinates are nonfinite, out of range, or `(0,0)`. |
| `missing` | Latitude or longitude is missing. |

Field-level values in `esqc_gps_a3a_status` and `esqc_gps_a3x_status` are `match`, `mismatch`, `not_found`, or `missing` when the point falls inside a country polygon. `a3a=match` means the GPS Admin1 is one of the listed members. `a3x=match` means the reported place contains the exact GPS point, not merely that both share the same parent Admin2/LGA. `esqc_gps_detail` stays concise; when AI materially reviews a field, at most one short decision reason is appended.

## Atomic Stata writes

The Java bridge uses the observation number as a generated `row_id`; duplicate or missing survey IDs therefore cannot reorder results. It validates:

- the success marker and worker version;
- the exact 11-column CSV header;
- row count, row order, and row IDs;
- allowed status values and the 0/1 flag contract;
- finite coordinates and complete CSV parsing.

Only after validation does it create seven shadow variables. Publication is a second phase; any SFI failure rolls back the shadows. The `.ado` wrapper adds `preserve`/`restore`, so child failure, malformed output, row mismatch, timeout, or write failure leaves the caller's dataset unchanged.

Existing result variables cause `r(110)` unless `replace` is specified.

## Optional outputs and repeatability

```stata
esqc_gps, ///
    shapefile("WB_GAD_ADM2.zip") country("Australia") ///
    latitude(gps__Latitude) longitude(gps__Longitude) ///
    admin1(a3a) admin2(a3x) ///
    cache("O:/qc/esqc_gps_cache.json") ///
    maphtml("O:/qc/esqc_gps_map.html") ///
    mapgeojson("O:/qc/esqc_gps_points.geojson")
```

- `cache()` enables a versioned persistent cache. Without it, there is no persistent result cache.
- `rerun` ignores cache reads for the current run while refreshing entries after success.
- `maphtml()` writes an interactive single-file result map; when omitted, `esqc_gps_map.html` is written automatically in Stata's current working directory. `nomap` suppresses it.
- `mapgeojson()` additionally writes point features and a simplified `_boundaries.geojson` sidecar.
- `keepfiles` preserves the private Java run directory for diagnosis; it can contain survey location data and must be protected.

## Build and tests

Rebuild the JAR:

```text
python tools/build_jar.py
```

The build compiles with `javac --release 11`, excludes Stata SFI stubs, embeds the reviewed worker, records source SHA-256 values, fixes ZIP metadata, and validates Java class-file major version 55. Repeated builds with the same sources are byte-identical on the same toolchain.

Run offline tests:

```text
python -m unittest -v tests.test_worker tests.test_java_bridge
python tools/validate_release.py
```

Run the final acceptance test in the target Stata installation from the source root:

```stata
do tests/stata_smoke.do
```

The automated tests use only artificial coordinates, polygons, and mocked API responses. A live OpenAI call and a live map-tile call were not required for package validation.

## Author and acknowledgement

**Attique Ur Rehman**  
Enterprise Analysis Unit, World Bank

Developed with help of **gpt-5.6 sol ultra**.

The software is a quality-control aid. The author and the World Bank do not replace the survey team's responsibility for validating source boundaries, coordinate reference systems, data-sharing policy, and final case disposition.

## Integration into the full ESQC repository

This package is intentionally standalone. To fold it into the main ESQC distribution:

1. add `esqc_gps.ado` and `esqc_gps.sthlp` to the package manifest;
2. compile `GpsSfi.java` alongside the existing ESQC Java sources;
3. embed `resources/gps_qc.py` at `/resources/gps_qc.py` in the main JAR;
4. change the wrapper's JAR lookup from `esqc_gps.jar` to the main `esqc.jar`, or keep the standalone JAR as a separate runtime;
5. retain the exact `sfi11` worker contract and the atomic shadow-variable publication tests.

The QC result remains a review aid. Survey teams remain responsible for the boundary source, CRS, tolerance, AI/data-sharing policy, and final case disposition.


## Interactive HTML GPS map (1.2.0)

Every successful `esqc_gps` run now writes `esqc_gps_map.html` in Stata's current working directory unless `nomap` is supplied. Use `maphtml("path/to/map.html")` to choose another target. The map embeds the result points and simplified Admin2 boundaries, uses Google Hybrid by default, includes Google Satellite/Road and OpenStreetMap layer choices, status filters, and concise popups. The path is returned in `r(maphtml)`.

`cache()`, `ailog()`, `maphtml()`, and `mapgeojson()` now accept either a file path or an existing directory. A directory target receives a safe default filename, preventing the Windows directory-replacement error seen with paths such as `C:\Temp\GPS_QC`.

Admin2 spelling matching is conservative but now accepts a unique close variant within the GPS-derived Admin1, including `Gondia`/`Gondiya`.

## Mandatory storage and full audit logging (1.1.1 onward)

Every OpenAI Responses request is forced to `store=true` at both the payload and transport layers. Full JSONL audit logging is always enabled and fails closed if a durable log cannot be opened. Run `esqc_gps_log` in Stata to locate the latest log. API keys and authorization material are redacted; binary request assets are retained in a hash-addressed sibling artifact directory. See `README_1.1.1_FULL_AUDIT.md` for the audit-record schema and retention details.
