{smcl}
{* *! version 1.2.0 11jul2026}{...}
{title:Title}

{phang}
{bf:esqc_gps_log} {hline 2} locate the latest mandatory ESQC GPS full audit log

{title:Syntax}

{p 8 17 2}
{cmd:esqc_gps_log} [{cmd:,} {opt show}]

{title:Description}

{pstd}
{cmd:esqc_gps_log} reports the JSONL file written by the most recent
{cmd:esqc_gps} Python worker run. Full logging is always enabled. The log
contains the sanitized run configuration, input/output-file snapshots,
stdout, stderr, errors, complete textual HTTP request and response bodies,
request timing, response headers, and OpenAI usage/tool metadata when returned.
Authorization headers, API keys, passwords, cookies, and token values are
redacted. Binary image bodies are preserved byte-for-byte in the sibling
{cmd:_artifacts} directory and referenced by SHA-256 from the JSONL log.

{pstd}
The {opt show} option types the latest JSONL log into Stata's Results window.
For a large log, omit {opt show} and open the reported file in an editor.

{title:Stored results}

{pstd}{cmd:esqc_gps_log} stores:

{synoptset 20 tabbed}{...}
{synopt:{cmd:r(logfile)}}absolute path of the latest JSONL audit log{p_end}
{synopt:{cmd:r(logdir)}}audit-log directory{p_end}

{title:Author}

{pstd}
Attique Ur Rehman, Enterprise Analysis Unit, World Bank.
Developed with help of gpt-5.6 sol ultra.{p_end}
