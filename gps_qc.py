version 16.0
clear all
set more off

* Edit these paths and variable names for the survey export.
use "export.dta", clear

* Deterministic Admin2 boundary and reported-location check.
* The interactive HTML map is written automatically; maphtml() selects its path.
esqc_gps, ///
    shapefile("WB_GAD_ADM2.zip") ///
    country("Australia") ///
    latitude(gps__Latitude) ///
    longitude(gps__Longitude) ///
    admin1(a3a) ///
    admin2(a3x) ///
    maphtml("qc/esqc_gps_map.html")

return list
confirm file "qc/esqc_gps_map.html"
tabulate esqc_gps_status, missing
list technicalid esqc_gps_status esqc_gps_admin1 esqc_gps_admin2 ///
    esqc_gps_detail if esqc_gps_flag, noobs abbreviate(24)

* Optional AI refinement. The key file contains the API key on its first
* nonblank line. OpenAI requests always use store=true; full local audit
* logging is always active and is located with esqc_gps_log.
/*
esqc_gps, ///
    shapefile("WB_GAD_ADM2.zip") ///
    country("Australia") ///
    latitude(gps__Latitude) ///
    longitude(gps__Longitude) ///
    admin1(a3a) ///
    admin2(a3x) ///
    id(technicalid) ///
    ai keyfile("O:/secure/openai.key") ///
    model("gpt-5.6-luna") reasoning(medium) ///
    cache("qc") ///
    maphtml("qc") ///
    mapgeojson("qc") ///
    replace rerun verbose

esqc_gps_log
*/
