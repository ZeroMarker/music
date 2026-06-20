/*
Command-line WAV export.

Run:
"C:\Program Files\SuperCollider-3.14.1\sclang.exe" "D:\canon\export_wav.scd"
*/

(
var envProjectDir = "CANON_PROJECT_DIR".getenv;
var projectDir = envProjectDir ? PathName(thisProcess.nowExecutingPath).pathOnly;
var envPath = "CANON_RECORD_PATH".getenv;
var envDuration = "CANON_RECORD_DURATION".getenv;

~canonRecordPath = envPath ? (projectDir +/+ "canon_in_d.wav");
~canonRecordDuration = if (envDuration.notNil) { envDuration.asFloat } { 137.2 };
(projectDir +/+ "main.scd").load;
)
