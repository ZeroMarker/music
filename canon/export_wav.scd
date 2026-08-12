/*
Command-line WAV export.

Run (sclang must be on PATH):
    sclang export_wav.scd

Optional environment variables:
    MUSIC_PROJECT_DIR      project directory (defaults to this file's directory)
    MUSIC_RECORD_PATH      output WAV path (default: <project>.wav in project dir)
    MUSIC_RECORD_DURATION  recording length in seconds (default: 137.2)

Legacy CANON_* names remain supported.
*/

(
var envProjectDir = "MUSIC_PROJECT_DIR".getenv ? "CANON_PROJECT_DIR".getenv;
var projectDir = envProjectDir ? PathName(thisProcess.nowExecutingPath).pathOnly;
var envPath = "MUSIC_RECORD_PATH".getenv ? "CANON_RECORD_PATH".getenv;
var envDuration = "MUSIC_RECORD_DURATION".getenv ? "CANON_RECORD_DURATION".getenv;
var projectName = PathName(projectDir).folderName;

~canonRecordPath = envPath ? (projectDir +/+ (projectName ++ ".wav"));
~canonRecordDuration = if (envDuration.notNil) { envDuration.asFloat } { 137.2 };
thisThread.randSeed = 20260731;
(projectDir +/+ "main.scd").load;
)
