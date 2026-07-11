version 16.0
clear all
set more off

* Run this do-file from the esqc_gps source-package root.
adopath ++ "."

capture findfile esqc_gps.ado
assert _rc == 0
capture findfile esqc_gps.jar
assert _rc == 0
capture findfile esqc_gps_log.ado
assert _rc == 0
capture confirm file "tests/fixtures/test_adm2.zip"
assert _rc == 0

clear
input double(lat lon) str20 a3a str20 a3x str12 tid
10.5 10.5 "North" "Alpha" "one"
10.5 10.5 "South" "Alpha" "two"
10.5 10.5 ""      ""      "three"
20.0 20.0 ""      ""      "four"
.    10.5 "North" "Alpha" "five"
10.5 10.5 "North + South" "Alpha" "union"
end

local pyopt
if `"$ESQC_GPS_PYTHON"' != "" {
    local pyopt `"python("$ESQC_GPS_PYTHON")"'
}

local mapfile "tests/esqc_gps_smoke_map.html"
capture erase "`mapfile'"

esqc_gps, ///
    shapefile("tests/fixtures/test_adm2.zip") ///
    country("Testland") ///
    latitude(lat) longitude(lon) ///
    admin1(a3a) admin2(a3x) id(tid) ///
    maphtml("`mapfile'") ///
    `pyopt'

local N = r(N)
local N_ok = r(N_ok)
local N_mismatch = r(N_mismatch)
local N_no_reported = r(N_no_reported_location)
local N_outside = r(N_outside_country)
local N_missing = r(N_missing)
local returned_map `"`r(maphtml)'"'

confirm file "`mapfile'"
if `"`returned_map'"' == "" {
    display as error "r(maphtml) was empty"
    exit 9
}

assert `N' == 6
assert `N_ok' == 2
assert `N_mismatch' == 1
assert `N_no_reported' == 1
assert `N_outside' == 1
assert `N_missing' == 1

assert esqc_gps_status == "ok" in 1
assert esqc_gps_flag == 0 in 1
assert esqc_gps_admin1 == "North" in 1
assert esqc_gps_admin2 == "Alpha" in 1
assert esqc_gps_a3a_status == "match" in 1
assert esqc_gps_a3x_status == "match" in 1

assert esqc_gps_status == "mismatch" in 2
assert esqc_gps_flag == 1 in 2
assert esqc_gps_a3a_status == "mismatch" in 2
assert esqc_gps_a3x_status == "match" in 2

assert esqc_gps_status == "no_reported_location" in 3
assert esqc_gps_status == "outside_country" in 4
assert esqc_gps_status == "missing" in 5
assert esqc_gps_status == "ok" in 6
assert esqc_gps_a3a_status == "match" in 6
assert strpos(esqc_gps_detail, "a3a 'North + South' includes North") > 0 in 6

* Existing outputs must fail unless the complete result set is replaced.
capture noisily esqc_gps, ///
    shapefile("tests/fixtures/test_adm2.zip") ///
    country("Testland") ///
    latitude(lat) longitude(lon) ///
    admin1(a3a) admin2(a3x) id(tid) ///
    maphtml("`mapfile'") ///
    `pyopt'
assert _rc == 110

esqc_gps, ///
    shapefile("tests/fixtures/test_adm2.zip") ///
    country("Testland") ///
    latitude(lat) longitude(lon) ///
    admin1(a3a) admin2(a3x) id(tid) ///
    maphtml("`mapfile'") ///
    replace `pyopt'
assert esqc_gps_status == "ok" in 1
confirm file "`mapfile'"

capture erase "`mapfile'"
noi display as result "esqc_gps Stata smoke test passed (6 artificial observations and HTML map)."
