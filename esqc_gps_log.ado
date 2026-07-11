*! esqc_gps_log 1.2.0 11jul2026
*! Author: Attique Ur Rehman, Enterprise Analysis Unit, World Bank
*! Developed with help of gpt-5.6 sol ultra
program define esqc_gps_log, rclass
    version 16.0
    syntax [, SHOW]

    local base : environment LOCALAPPDATA
    if `"`base'"' == "" {
        local xdg : environment XDG_STATE_HOME
        if `"`xdg'"' != "" {
            local logdir `"`xdg'/esqc_gps/logs"'
        }
        else {
            local home : environment HOME
            if `"`home'"' == "" {
                local home : environment USERPROFILE
            }
            if `"`home'"' == "" {
                di as err "Could not determine the user log directory."
                exit 603
            }
            if c(os) == "Windows" {
                local logdir `"`home'/AppData/Local/esqc_gps/logs"'
            }
            else {
                local logdir `"`home'/.local/state/esqc_gps/logs"'
            }
        }
    }
    else {
        local logdir `"`base'/esqc_gps/logs"'
    }

    local pointer `"`logdir'/latest.txt"'
    capture confirm file `"`pointer'"'
    if _rc {
        di as err "No ESQC GPS audit log has been recorded yet."
        di as txt "Expected pointer: `pointer'"
        exit 601
    }

    tempname fh
    file open `fh' using `"`pointer'"', read text
    file read `fh' line
    file close `fh'
    local logfile `"`line'"'

    capture confirm file `"`logfile'"'
    if _rc {
        di as err "The latest-log pointer refers to a missing file:"
        di as err `"`logfile'"'
        exit 601
    }

    return local logfile `"`logfile'"'
    return local logdir `"`logdir'"'
    di as txt "Latest full ESQC GPS audit log:"
    di as result `"`logfile'"'

    if "`show'" != "" {
        type `"`logfile'"'
    }
end
