/*
Command-line WAV export.

Run (sclang must be on PATH):
    sclang export_wav.scd

Optional environment variables:
    CANON_PROJECT_DIR      project directory (defaults to this file's directory)
    CANON_RECORD_PATH      output WAV path (default: canon_in_d.wav in project dir)
    CANON_RECORD_DURATION  recording length in seconds (default: 137.2)
*/

(
var envProjectDir = "CANON_PROJECT_DIR".getenv;
var projectDir = envProjectDir ? PathName(thisProcess.nowExecutingPath).pathOnly;
var envPath = "CANON_RECORD_PATH".getenv;
var envDuration = "CANON_RECORD_DURATION".getenv;

~canonRecordPath = envPath ? (projectDir +/+ "canon_in_d.wav");
~canonRecordDuration = if (envDuration.notNil) { envDuration.asFloat } { 137.2 };
thisThread.randSeed = 20260731;
(projectDir +/+ "main.scd").load;
)
