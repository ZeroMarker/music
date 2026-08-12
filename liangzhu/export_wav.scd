/* Command-line WAV export for this project. */
(
var envProjectDir = "MUSIC_PROJECT_DIR".getenv ? "CANON_PROJECT_DIR".getenv;
var projectDir = envProjectDir ? PathName(thisProcess.nowExecutingPath).pathOnly;
var envPath = "MUSIC_RECORD_PATH".getenv ? "CANON_RECORD_PATH".getenv;
var envDuration = "MUSIC_RECORD_DURATION".getenv ? "CANON_RECORD_DURATION".getenv;

~liangzhuRecordPath = envPath ? (projectDir +/+ "liangzhu.wav");
~liangzhuRecordDuration = if (envDuration.notNil) { envDuration.asFloat } { 128 };
thisThread.randSeed = 20260813;
(projectDir +/+ "main.scd").load;
)
