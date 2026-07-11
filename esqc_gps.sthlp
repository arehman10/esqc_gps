{smcl}
{* *! version 1.2.0  11jul2026}{...}
{vieweralsosee "esqc" "help esqc"}{...}
{viewerjumpto "Syntax" "esqc_gps##syntax"}{...}
{viewerjumpto "Description" "esqc_gps##description"}{...}
{viewerjumpto "Options" "esqc_gps##options"}{...}
{viewerjumpto "Results" "esqc_gps##results"}{...}
{viewerjumpto "Security and data flow" "esqc_gps##security"}{...}
{viewerjumpto "Examples" "esqc_gps##examples"}{...}
{viewerjumpto "Java loader troubleshooting" "esqc_gps##javaloader"}{...}
{viewerjumpto "Requirements" "esqc_gps##requirements"}{...}

{title:Title}

{phang}
{bf:esqc_gps} {hline 2} standalone Admin2 GPS quality control through Stata's
Java/SFI integration, with optional GPT-5.6 Luna review{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:esqc_gps} {ifin}{cmd:,}
{opth shape:file(string)}
{opth cou:ntry(string)}
{opth lat:itude(varname)}
{opth lon:gitude(varname)}
{opth admin1(varname)}
{opth admin2(varname)}
[{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opth shape:file(path)}}Admin2 boundary input: a .shp file, ZIP, or directory{p_end}
{synopt:{opth cou:ntry(string)}}country value to select from the boundary layer; use {cmd:country("")} only when the layer contains exactly one country{p_end}
{synopt:{opth lat:itude(varname)}}numeric latitude variable{p_end}
{synopt:{opth lon:gitude(varname)}}numeric longitude variable{p_end}
{synopt:{opth admin1(varname)}}reported Admin1/state/province/region variable{p_end}
{synopt:{opth admin2(varname)}}reported Admin2/city/town/locality variable{p_end}

{syntab:Identity and replacement}
{synopt:{opth id(varname)}}survey identifier copied to the private worker input and result detail; observation number remains the authoritative row key{p_end}
{synopt:{opt replace}}replace the complete seven-variable ESQC GPS output set{p_end}

{syntab:AI review}
{synopt:{opt ai}}enable optional AI refinement after deterministic GIS checking{p_end}
{synopt:{opth keyf:ile(path)}}text file whose first nonblank line is the OpenAI API key; required with {cmd:ai}{p_end}
{synopt:{opth model(string)}}one of {cmd:gpt-5.6}, {cmd:gpt-5.6-sol}, {cmd:gpt-5.6-terra}, or {cmd:gpt-5.6-luna}; default {cmd:gpt-5.6-luna}{p_end}
{synopt:{opth reasoning(string)}}{cmd:none}, {cmd:low}, {cmd:medium}, {cmd:high}, {cmd:xhigh}, or {cmd:max}; default {cmd:medium}{p_end}
{synopt:{opt nowebsearch}}do not expose the web-search tool during reported-place alignment{p_end}
{synopt:{opt novision}}do not fetch map tiles or send map images for outside-country review{p_end}
{synopt:{opth basemap(string)}}{cmd:osm}, {cmd:google_hybrid}, {cmd:google_sat}, or {cmd:google_road}; default {cmd:google_hybrid}{p_end}
{synopt:{opt batchs:ize(#)}}AI alignment cases per request, 1--50; default 10{p_end}

{syntab:Runtime}
{synopt:{opth timeout(#)}}child-process timeout in seconds, 30--86400; default 7200{p_end}
{synopt:{opth python(path)}}Python executable or command; otherwise the bridge probes Python 3/Python{p_end}
{synopt:{opth worker(path)}}use an external reviewed worker instead of the copy embedded in the JAR; intended for development{p_end}
{synopt:{opth jar(path)}}exact path to the bridge JAR; when omitted, the bare {cmd:esqc_gps.jar} name is resolved on the ado-path through {cmd:jars()}; an explicit path uses {cmd:classpath()}{p_end}
{synopt:{opt keepfiles}}retain the private Java run directory for diagnosis; it contains sensitive location data{p_end}
{synopt:{opt verbose}}show the tail of the worker log after success{p_end}

{syntab:Boundary policy}
{synopt:{opth snaptol:erance(#)}}maximum boundary-gap snap distance in kilometres, 0--100; default 0{p_end}
{synopt:{opt assumewgs84}}treat a layer without .prj as EPSG:4326; use only after independent CRS verification{p_end}
{synopt:{opth countryf:ield(name)}}boundary country field; default {cmd:NAM_0}{p_end}
{synopt:{opth admin1f:ield(name)}}boundary Admin1 field; default {cmd:NAM_1}{p_end}
{synopt:{opth admin2f:ield(name)}}boundary Admin2 field; default {cmd:NAM_2}{p_end}

{syntab:Optional files}
{synopt:{opth cache(path)}}versioned persistent JSON result cache; no persistent cache is used when omitted{p_end}
{synopt:{opt rerun}}ignore cache reads for this run and refresh entries after success{p_end}
{synopt:{opth maphtml(path)}}write a single-file interactive HTML result map with embedded points and boundaries; default {cmd:esqc_gps_map.html} in the working directory{p_end}
{synopt:{opt nomap}}suppress the default HTML map{p_end}
{synopt:{opth mapgeojson(path)}}also write point GeoJSON plus a simplified {it:_boundaries.geojson} sidecar{p_end}
{synopt:{opth ailog(path)}}optional secondary AI-call summary JSONL; the mandatory full audit log is written separately{p_end}
{synopt:{opt ailogpayload}}also log truncated request and response payloads; requires {cmd:ai} and secure storage{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:esqc_gps} checks the observations selected by {it:if} and {it:in} against
Admin2 boundary polygons and writes results directly into the dataset currently
loaded in Stata.  The deterministic pass validates coordinates, selects the
country layer, performs point-in-polygon checking, derives Admin1/Admin2, and
compares the reported location fields.  {cmd:a3a} is treated as a union: when
it lists several Admin1 areas, the field matches if the GPS Admin1 is any one
of them.  {cmd:a3x} matches only when the reported district/locality contains
the GPS point.{p_end}

{pstd}
The command follows a fail-closed two-language contract.  The ado wrapper
protects the caller with {cmd:preserve}/{cmd:restore}.  A Java 11 SFI bridge
exports only the selected rows, launches the reviewed Python worker, validates
the success marker and the exact 11-column result file, stages seven shadow
variables, and publishes them only after every row is valid.  A child failure,
timeout, malformed CSV, row mismatch, or SFI write error leaves the caller's
dataset unchanged.{p_end}

{pstd}
AI is off by default.  With {cmd:ai}, GPT-5.6 Luna is used only after the
deterministic pass.  Deterministic Admin1 {cmd:match}/{cmd:mismatch} results
and deterministic a3x {cmd:match} results are locked.  AI reviews unresolved
a3a values and both unresolved and apparent a3x mismatches using the exact
coordinates.  This allows a high-confidence correction when an a3x value is a
lower-level locality or a same-name place that the Admin2 layer could not
represent correctly.  Only a {cmd:high}-confidence AI match may clear a
deterministic a3x mismatch; lower confidence remains flagged.  Sharing the same
parent Admin2/LGA is not sufficient: the GPS point itself must be inside the
reported a3x area.  Vision remains limited to {cmd:outside_country} polygon
false positives because imagery is not an authoritative locality boundary.{p_end}

{pstd}
The Responses API request uses strict JSON Schema through {cmd:text.format},
hard-coded {cmd:store=true}, a 30-minute GPT-5.6 prompt-cache option,
{cmd:parallel_tool_calls=false}, and the selected reasoning effort.  The Java
bridge ignores inherited API-key and endpoint environment variables; AI
requires an explicit {cmd:keyfile()}.{p_end}

{marker options}{...}
{title:Options}

{phang}
{opth shapefile(path)} accepts a shapefile, a ZIP containing the required
sidecars, or a directory.  ZIP extraction rejects absolute paths, parent
traversal, symlinks, more than 10,000 members, and more than 4 GiB expanded.
When a directory or ZIP contains several .shp files, a name containing
{cmd:adm2} is preferred; otherwise the first sorted shapefile is used.{p_end}

{phang}
{opth country(string)} is matched after case/spacing/accent normalization.
When empty, the worker auto-detects only if exactly one nonempty country value
exists in the selected field.{p_end}

{phang}
{opth latitude(varname)} and {opth longitude(varname)} must be numeric.  Missing
coordinates produce status {cmd:missing}; nonfinite/out-of-range coordinates
and (0,0) produce {cmd:invalid}.{p_end}

{phang}
{opth admin1(varname)} and {opth admin2(varname)} may be string or numeric.
Numeric values are exported using Stata's formatted value.  Admin1 supports
common normalized variants, codes, and set/union labels.  The deterministic
a3x pass uses the available Admin2 polygons; optional AI review handles
spelling variants and lower-level places such as towns or suburbs.  A shared
parent council/county does not by itself establish a3x containment.{p_end}

{phang}
{opth id(varname)} is informational.  The bridge always generates a unique
one-based row id from the Stata observation number, so duplicate or missing
survey identifiers cannot reorder writes.{p_end}

{phang}
{opt replace} drops all existing ESQC GPS output variables inside the protected
copy before Java starts.  Without it, any existing output variable causes
error {cmd:r(110)}.{p_end}

{phang}
{opt ai} sends unresolved a3a cases and unresolved/apparent-mismatch a3x cases to OpenAI.  It requires
{opth keyfile(path)}.  The key is supplied only to the child process, is not
written to the worker configuration or outputs, and is scrubbed from displayed
transport errors.{p_end}

{phang}
{opth model(string)} defaults to {cmd:gpt-5.6-luna}.  Model names are checked
against the exact GPT-5.6 allowlist rather than accepting an arbitrary string.{p_end}

{phang}
{opth reasoning(string)} controls GPT-5.6 reasoning effort.  {cmd:medium} is the
default.  Higher settings can increase latency and token use.{p_end}

{phang}
{opt nowebsearch} removes the Responses API web-search tool.  It does not stop
the case text itself from being sent to OpenAI.  {opt novision} prevents map
tile requests and image upload.  Specify both for the most restrictive AI data
flow supported by this command.{p_end}

{phang}
{opth basemap(string)} selects the initial HTML-map basemap and the tile source used by vision.
{cmd:google_hybrid} (Google Hybrid) is the default.  The HTML also provides Google Satellite, Google Roads, and OpenStreetMap layer choices.
Map tiles require internet access and must be reviewed for provider terms and organizational policy.{p_end}

{phang}
{opth cache(path)} is opt-in.  Cache keys include worker version, boundary
content hashes, field policy, row id, coordinates, reported values, AI model,
reasoning, web/vision settings, and snap tolerance.  {opt rerun} bypasses reads
without disabling the successful refresh.{p_end}

{phang}
{opth maphtml(path)} writes an interactive Leaflet HTML map containing all finite-coordinate results and simplified Admin2 boundaries. Points are colored by final status, can be filtered, and show the concise QC detail in a popup. Point and boundary data are embedded in the HTML; basemap tiles and the Leaflet library load from the internet. When omitted, the command writes {cmd:esqc_gps_map.html} in {cmd:c(pwd)}. {opt nomap} disables this output. If {it:path} is an existing directory, the file is written as {it:esqc_gps_map.html} inside that directory.{p_end}

{phang}
{opth mapgeojson(path)} optionally writes the same finite-coordinate points plus a simplified {it:_boundaries.geojson} sidecar. An existing directory target receives safe default filenames. These files may contain sensitive survey locations.{p_end}

{phang}
{opth ailog(path)} writes an optional secondary AI-call summary containing timestamp, module, model, status, latency, row ids, token usage, and request/response hashes. {opt ailogpayload} additionally writes truncated payloads. This option does not control the mandatory full audit log, which is always active and is located with {help esqc_gps_log:{cmd:esqc_gps_log}}. An unavailable secondary log path generates a warning without discarding otherwise valid QC results.{p_end}

{phang}
{opth snaptolerance(#)} is 0 by default.  A positive value treats a point just
outside all polygons as belonging to the nearest Admin2 when its geodesic
boundary distance is within the specified kilometres.  Use only under an
explicit reviewed boundary-gap policy.{p_end}

{phang}
{opt assumewgs84} bypasses a missing .prj file.  Without it, missing or invalid
CRS metadata fails the run.  Projected layers with a valid .prj are transformed
to EPSG:4326 with pyproj before GPS matching.{p_end}

{marker results}{...}
{title:Variables created}

{p2colset 5 31 33 2}{...}
{p2col:{cmd:esqc_gps_status}}final status: {cmd:ok}, {cmd:mismatch},
{cmd:reported_not_found}, {cmd:no_reported_location},
{cmd:outside_country}, {cmd:invalid}, or {cmd:missing}{p_end}
{p2col:{cmd:esqc_gps_flag}}0 only when final status is {cmd:ok}; otherwise 1{p_end}
{p2col:{cmd:esqc_gps_admin1}}GPS-derived Admin1{p_end}
{p2col:{cmd:esqc_gps_admin2}}GPS-derived Admin2{p_end}
{p2col:{cmd:esqc_gps_a3a_status}}reported Admin1 status: {cmd:match},
{cmd:mismatch}, {cmd:not_found}, or {cmd:missing}; multi-value labels are
evaluated as a union, so one containing member is sufficient for {cmd:match}{p_end}
{p2col:{cmd:esqc_gps_a3x_status}}reported Admin2/locality status using the
same four values; {cmd:match} means the reported place contains the GPS point{p_end}
{p2col:{cmd:esqc_gps_detail}}concise final explanation, for example
{cmd:OK: GPS in Tweed (A), New South Wales; a3a 'NSW + ACT' includes New South Wales; a3x 'Mooball' contains GPS.}
When AI materially reviews a field, one short reason may be appended.{p_end}
{p2colreset}{...}

{pstd}
{cmd:esqc_gps_status=ok} means all nonmissing reported fields agree with the
GPS-derived location.  When vision clears an outside-country polygon false
positive, the reviewed nearest Admin2 and reported fields must still produce
that same final result.  {cmd:no_reported_location}
is deliberately flagged because valid coordinates alone do not verify the
reported location fields.{p_end}

{title:Stored results}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:r(N)}}number of selected observations{p_end}
{p2col:{cmd:r(N_ok)}}number with final status {cmd:ok}{p_end}
{p2col:{cmd:r(N_mismatch)}}number with status {cmd:mismatch}{p_end}
{p2col:{cmd:r(N_reported_not_found)}}number with status {cmd:reported_not_found}{p_end}
{p2col:{cmd:r(N_no_reported_location)}}number with status {cmd:no_reported_location}{p_end}
{p2col:{cmd:r(N_outside_country)}}number with status {cmd:outside_country}{p_end}
{p2col:{cmd:r(N_invalid)}}number with status {cmd:invalid}{p_end}
{p2col:{cmd:r(N_missing)}}number with status {cmd:missing}{p_end}
{p2col:{cmd:r(model)}}selected model string{p_end}
{p2col:{cmd:r(country)}}country option{p_end}
{p2col:{cmd:r(shapefile)}}boundary input path{p_end}
{p2col:{cmd:r(ai)}}{cmd:true} or {cmd:false}{p_end}
{p2col:{cmd:r(maphtml)}}HTML map path, or empty when {cmd:nomap} was specified{p_end}
{p2colreset}{...}

{marker security}{...}
{title:Security and data flow}

{pstd}
Deterministic mode does not contact OpenAI.  AI mode sends coordinates,
GPS-derived boundary names, and reported location values for unresolved a3a
or unresolved/apparent-mismatch a3x cases.
Web search may be used unless {cmd:nowebsearch} is supplied.  Vision contacts
the selected map-tile provider and sends composed images to OpenAI unless
{cmd:novision} is supplied.{p_end}

{pstd}
Every OpenAI request specifies {cmd:store=true}. Mandatory full JSONL audit logging starts before QC or network activity and fails closed if a durable local audit file cannot be created. Use {help esqc_gps_log:{cmd:esqc_gps_log}} to locate it. Credentials are redacted, but coordinates, prompts, responses, map artifacts, and outputs can remain sensitive. Do not use {cmd:keepfiles}, {cmd:maphtml()}, {cmd:mapgeojson()}, {cmd:cache()}, or {cmd:ailogpayload} in an unprotected location. Provider storage and logging require organizational data-governance approval.{p_end}

{marker examples}{...}
{title:Examples}

{pstd}{bf:1. Deterministic run with automatic HTML map}{p_end}
{phang2}{cmd:. esqc_gps, shapefile("admin2.zip") country("Pakistan") latitude(gps__Latitude) longitude(gps__Longitude) admin1(a3a) admin2(a3x)}{p_end}

{pstd}{bf:2. GPT-5.6 Luna refinement}{p_end}
{phang2}{cmd:. esqc_gps, shapefile("admin2.zip") country("Pakistan") latitude(gps__Latitude) longitude(gps__Longitude) admin1(a3a) admin2(a3x) id(technicalid) ai keyfile("O:/secure/openai.key") model("gpt-5.6-luna")}{p_end}

{pstd}{bf:3. AI without web search or map vision}{p_end}
{phang2}{cmd:. esqc_gps, shapefile("admin2.zip") country("Pakistan") latitude(gps__Latitude) longitude(gps__Longitude) admin1(a3a) admin2(a3x) ai keyfile("O:/secure/openai.key") nowebsearch novision}{p_end}

{pstd}{bf:4. Selected records, cache, map output, and replacement}{p_end}
{phang2}{cmd:. esqc_gps if complete==1, shapefile("admin2.zip") country("Pakistan") latitude(lat) longitude(lon) admin1(region) admin2(city) cache("qc/gps_cache.json") maphtml("qc/esqc_gps_map.html") mapgeojson("qc/gps_points.geojson") replace}{p_end}

{marker javaloader}{...}
{title:Java loader troubleshooting}

{pstd}
Since version 1.0.1, the command probes the bridge before preserving or changing the dataset.
For the normal installation it uses the documented ado-path form
{cmd:jars(esqc_gps.jar)}.  If needed, it falls back to the exact path returned
by {cmd:findfile} through {cmd:classpath()}.  An explicit {cmd:jar()} path is
always loaded through {cmd:classpath()}.{p_end}

{pstd}
After installing or replacing the files, type:{p_end}

{phang2}{cmd:discard}{p_end}
{phang2}{cmd:which esqc_gps}{p_end}
{phang2}{cmd:findfile esqc_gps.jar}{p_end}
{phang2}{cmd:display `"`r(fn)'"'}{p_end}
{phang2}{cmd:javacall org.worldbank.esqc.GpsSfi probe, jars(esqc_gps.jar)}{p_end}

{pstd}
The probe must finish without an error.  If it reports
{cmd:ClassNotFoundException}, replace {cmd:esqc_gps.ado},
{cmd:esqc_gps.sthlp}, and {cmd:esqc_gps.jar} together from the same release,
then run {cmd:discard} or restart Stata.  Use {cmd:java query} to inspect the JVM
used by Stata.{p_end}

{marker requirements}{...}
{title:Requirements}

{pstd}
Stata 16 or later; Java 11 or later; Python 3.10 or later.  The Python
environment needs pyshp, Shapely 2.x, and pyproj.  AI mode additionally needs
httpx; vision needs Pillow.  truststore is recommended on corporate networks,
with certifi as a fallback.  Install the supplied {it:requirements.txt} into the
Python environment selected by {cmd:python()}.{p_end}

{pstd}
{cmd:esqc_gps.jar} must be on the Stata adopath or supplied through {cmd:jar()}.
The final {it:tests/stata_smoke.do} acceptance test must be run in the target
Stata installation; the distributed automated Java tests use a mock SFI rather
than a licensed Stata runtime.{p_end}

{title:Author and status}

{pstd}
{bf:Author:} Attique Ur Rehman, Enterprise Analysis Unit, World Bank.{p_end}

{pstd}
Developed with help of gpt-5.6 sol ultra.{p_end}

{pstd}
Version 1.2.0.  The command is a quality-control aid; survey teams remain
responsible for reviewing the boundary source, CRS, snapping policy,
AI/data-sharing policy, and final disposition of every flagged case.{p_end}


{marker audit}{...}
{title:Mandatory API storage and full audit logging}

{pstd}
All OpenAI Responses requests are forced to {cmd:store=true} at both the request-construction and HTTP-transport layers. Full JSONL audit logging is always active and cannot be reduced or disabled. The worker opens and synchronizes the audit file before QC or network activity; a log-creation failure stops the run. Use {help esqc_gps_log:{cmd:esqc_gps_log}} to locate the latest file. Secrets are redacted, while binary map/image bodies are retained in a sibling artifact directory and referenced by SHA-256.{p_end}
