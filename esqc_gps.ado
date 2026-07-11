*! version 1.2.0  11jul2026
*! Author: Attique Ur Rehman, Enterprise Analysis Unit, World Bank
*! Developed with help of gpt-5.6 sol ultra
program define esqc_gps, rclass
    version 16.0

    syntax [if] [in], ///
        SHAPEfile(string asis) ///
        COUNtry(string asis) ///
        LATitude(varname numeric) ///
        LONGitude(varname numeric) ///
        ADMIN1(varname) ///
        ADMIN2(varname) ///
        [ ID(varname) ///
          AI KEYFile(string asis) MODEL(string) ///
          NOVISION NOWEBSEARCH BASEMAP(string) REASONING(string) ///
          BATCHSize(integer 10) TIMEOUT(integer 7200) ///
          PYTHON(string asis) WORKER(string asis) JAR(string asis) ///
          CACHE(string asis) MAPGEOJSON(string asis) MAPHTML(string asis) NOMAP ///
          AILOG(string asis) AILOGPAYLOAD RERUN ///
          SNAPTOLerance(real 0) ASSUMEWGS84 ///
          COUNTRYFIELD(string) ADMIN1FIELD(string) ADMIN2FIELD(string) ///
          KEEPFILES VERBOSE REPLACE ]

    local model = strlower(strtrim(`"`model'"'))
    if `"`model'"' == "" local model "gpt-5.6-luna"
    if !inlist(`"`model'"', "gpt-5.6", "gpt-5.6-sol", "gpt-5.6-terra", "gpt-5.6-luna") {
        di as err "model() must be gpt-5.6, gpt-5.6-sol, gpt-5.6-terra, or gpt-5.6-luna"
        exit 198
    }

    local reasoning = strlower(strtrim(`"`reasoning'"'))
    if `"`reasoning'"' == "" local reasoning "medium"
    if !inlist(`"`reasoning'"', "none", "low", "medium", "high", "xhigh", "max") {
        di as err "reasoning() must be none, low, medium, high, xhigh, or max"
        exit 198
    }

    local basemap = strlower(strtrim(`"`basemap'"'))
    if `"`basemap'"' == "" local basemap "google_hybrid"
    if !inlist(`"`basemap'"', "osm", "google_hybrid", "google_sat", "google_road") {
        di as err "basemap() must be osm, google_hybrid, google_sat, or google_road"
        exit 198
    }

    if `"`nomap'"' != "" & `"`maphtml'"' != "" {
        di as err "maphtml() and nomap may not be combined"
        exit 198
    }
    if `"`nomap'"' == "" & `"`maphtml'"' == "" {
        local maphtml `"`c(pwd)'/esqc_gps_map.html"'
    }
    if `"`nomap'"' != "" local maphtml ""

    if `batchsize' < 1 | `batchsize' > 50 {
        di as err "batchsize() must be between 1 and 50"
        exit 198
    }
    if `timeout' < 30 | `timeout' > 86400 {
        di as err "timeout() must be between 30 and 86400 seconds"
        exit 198
    }
    if missing(`snaptolerance') | `snaptolerance' < 0 | `snaptolerance' > 100 {
        di as err "snaptolerance() must be between 0 and 100 kilometres"
        exit 198
    }

    if `"`ai'"' != "" & `"`keyfile'"' == "" {
        di as err "ai requires keyfile()"
        exit 198
    }
    if `"`ai'"' == "" & (`"`keyfile'"' != "" | `"`ailogpayload'"' != "" | ///
            `"`novision'"' != "" | `"`nowebsearch'"' != "") {
        di as err "keyfile(), ailogpayload, novision, and nowebsearch require ai"
        exit 198
    }

    if `"`countryfield'"' == "" local countryfield "NAM_0"
    if `"`admin1field'"' == "" local admin1field "NAM_1"
    if `"`admin2field'"' == "" local admin2field "NAM_2"

    local jar_mode "adopath"
    local jar_path `"`jar'"'
    if `"`jar_path'"' == "" {
        capture quietly findfile esqc_gps.jar
        if _rc {
            di as err "esqc_gps.jar was not found on the Stata adopath"
            di as err "Install the complete esqc_gps package or specify jar()."
            exit 601
        }
        local jar_path `"`r(fn)'"'
    }
    else {
        local jar_mode "classpath"
    }
    capture confirm file `"`jar_path'"'
    if _rc {
        di as err "JAR file not found: `jar_path'"
        exit 601
    }

    // Stata's jars() option searches the ado-path.  Passing findfile's
    // resolved Windows path back to jars() can leave the plugin class path
    // empty on some Stata builds.  Probe the documented bare-name form first,
    // then fall back to an exact classpath when needed.
    local java_loader ""
    local java_rc_primary = -1
    local java_rc_fallback = -1
    if `"`jar_mode'"' == "adopath" {
        capture quietly javacall org.worldbank.esqc.GpsSfi probe, ///
            jars(esqc_gps.jar)
        local java_rc_primary = _rc
        if `java_rc_primary' == 0 {
            local java_loader "jars"
        }
        else {
            capture quietly javacall org.worldbank.esqc.GpsSfi probe, ///
                classpath(`"`jar_path'"')
            local java_rc_fallback = _rc
            if `java_rc_fallback' == 0 local java_loader "classpath"
        }
    }
    else {
        capture quietly javacall org.worldbank.esqc.GpsSfi probe, ///
            classpath(`"`jar_path'"')
        local java_rc_primary = _rc
        if `java_rc_primary' == 0 local java_loader "classpath"
    }

    if `"`java_loader'"' == "" {
        di as err "esqc_gps could not load org.worldbank.esqc.GpsSfi"
        di as err "JAR located by Stata: `jar_path'"
        di as err "Replace esqc_gps.ado and esqc_gps.jar together from the same release."
        di as err "Then type discard (or restart Stata) before retrying."
        di as err "Java loader diagnostics: primary r(`java_rc_primary'), fallback r(`java_rc_fallback')"
        exit 5100
    }
    if `"`worker'"' != "" {
        capture confirm file `"`worker'"'
        if _rc {
            di as err "worker() file not found: `worker'"
            exit 601
        }
    }
    if `"`ai'"' != "" {
        capture confirm file `"`keyfile'"'
        if _rc {
            di as err "keyfile() not found: `keyfile'"
            exit 601
        }
    }

    local outvars ///
        esqc_gps_status esqc_gps_flag esqc_gps_admin1 esqc_gps_admin2 ///
        esqc_gps_a3a_status esqc_gps_a3x_status esqc_gps_detail
    local collisions
    foreach variable of local outvars {
        capture confirm variable `variable'
        if !_rc local collisions `collisions' `variable'
    }
    if `"`collisions'"' != "" & `"`replace'"' == "" {
        di as err "output variable(s) already exist:`collisions'"
        di as err "Specify replace to replace the complete esqc_gps result set."
        exit 110
    }

    marksample touse, novarlist
    quietly count if `touse'
    local selected = r(N)

    tempvar esqc_id
    if `"`id'"' == "" {
        quietly generate str24 `esqc_id' = string(_n, "%21.0f")
    }
    else {
        capture confirm string variable `id'
        if !_rc quietly generate strL `esqc_id' = `id'
        else quietly generate strL `esqc_id' = string(`id', "%21.0g")
    }

    local ai_bool = cond(`"`ai'"' != "", "true", "false")
    local vision_bool = cond(`"`novision'"' == "", "true", "false")
    local web_bool = cond(`"`nowebsearch'"' == "", "true", "false")
    local payload_bool = cond(`"`ailogpayload'"' != "", "true", "false")
    local rerun_bool = cond(`"`rerun'"' != "", "true", "false")
    local wgs_bool = cond(`"`assumewgs84'"' != "", "true", "false")
    local keep_bool = cond(`"`keepfiles'"' != "", "true", "false")
    local verbose_bool = cond(`"`verbose'"' != "", "true", "false")

    tempfile gps_config
    tempname cfg
    file open `cfg' using `"`gps_config'"', write text
    file write `cfg' "shapefile" _tab `"`shapefile'"' _n
    file write `cfg' "country" _tab `"`country'"' _n
    file write `cfg' "ai" _tab "`ai_bool'" _n
    file write `cfg' "keyfile" _tab `"`keyfile'"' _n
    file write `cfg' "model" _tab "`model'" _n
    file write `cfg' "vision" _tab "`vision_bool'" _n
    file write `cfg' "websearch" _tab "`web_bool'" _n
    file write `cfg' "basemap" _tab "`basemap'" _n
    file write `cfg' "reasoning" _tab "`reasoning'" _n
    file write `cfg' "batchsize" _tab "`batchsize'" _n
    file write `cfg' "timeout" _tab "`timeout'" _n
    file write `cfg' "python" _tab `"`python'"' _n
    file write `cfg' "worker" _tab `"`worker'"' _n
    file write `cfg' "cache" _tab `"`cache'"' _n
    file write `cfg' "mapgeojson" _tab `"`mapgeojson'"' _n
    file write `cfg' "maphtml" _tab `"`maphtml'"' _n
    file write `cfg' "ailog" _tab `"`ailog'"' _n
    file write `cfg' "ailogpayload" _tab "`payload_bool'" _n
    file write `cfg' "rerun" _tab "`rerun_bool'" _n
    file write `cfg' "snaptolerance" _tab "`snaptolerance'" _n
    file write `cfg' "assumewgs84" _tab "`wgs_bool'" _n
    file write `cfg' "countryfield" _tab `"`countryfield'"' _n
    file write `cfg' "admin1field" _tab `"`admin1field'"' _n
    file write `cfg' "admin2field" _tab `"`admin2field'"' _n
    file write `cfg' "keepfiles" _tab "`keep_bool'" _n
    file write `cfg' "verbose" _tab "`verbose_bool'" _n
    file close `cfg'

    preserve
    if `"`replace'"' != "" {
        foreach variable of local outvars {
            capture drop `variable'
        }
    }

    if `"`verbose'"' != "" {
        di as txt "  esqc_gps: Java bridge `jar_path' via `java_loader'()"
    }
    if `"`java_loader'"' == "jars" {
        capture noisily javacall org.worldbank.esqc.GpsSfi run ///
            `latitude' `longitude' `admin1' `admin2' `esqc_id' if `touse', ///
            jars(esqc_gps.jar) args(`"`gps_config'"')
    }
    else {
        capture noisily javacall org.worldbank.esqc.GpsSfi run ///
            `latitude' `longitude' `admin1' `admin2' `esqc_id' if `touse', ///
            classpath(`"`jar_path'"') args(`"`gps_config'"')
    }
    local rc = _rc
    if `rc' {
        restore
        exit `rc'
    }
    restore, not

    return scalar N = `selected'
    return local model "`model'"
    return local country `"`country'"'
    return local shapefile `"`shapefile'"'
    return local ai "`ai_bool'"
    return local maphtml `"`maphtml'"'

    if `"`maphtml'"' != "" {
        di as result `"  esqc_gps HTML map: `maphtml'"'
    }

    foreach status in ok mismatch reported_not_found no_reported_location outside_country invalid missing {
        quietly count if `touse' & esqc_gps_status == "`status'"
        return scalar N_`status' = r(N)
    }
end
