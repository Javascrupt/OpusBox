# OpusBox

A Windows GUI for downloading and syncing YouTube / YouTube Music playlists as Opus using yt-dlp, with resume protection, watchdog recovery, and optional MusicBrainz Picard integration.

## Features

- YouTube and YouTube Music playlist support
- Automatically resolves `music.youtube.com` playlist links
- Downloads YouTube audio as Opus
- Resume support using yt-dlp download archives
- Skips tracks that were already completed
- Automatic retry handling
- 20-second network socket timeout
- 3-minute no-progress watchdog
- Automatically restarts yt-dlp after a detected stall
- Maximum of 3 watchdog restarts to prevent infinite loops
- Failed-track reporting
- Live completed-track progress
- Shows the most recently completed playlist item
- Optional MusicBrainz Picard integration
- Batch tagging workflow for large playlists
- "Tag Existing Music" workflow for already-downloaded Opus files
- Settings saved under `%APPDATA%\OpusBox`

## How It Works

Typical workflow:

```text
YouTube / YouTube Music
        ↓
      OpusBox
        ↓
      yt-dlp
        ↓
   Opus audio files
        ↓
MusicBrainz Picard (optional)
        ↓
 Local music library
```

For YouTube Music URLs, OpusBox lets yt-dlp resolve the corresponding regular YouTube playlist URL and then continues the normal workflow.

## Requirements

- Windows
- Windows PowerShell
- [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- [FFmpeg](https://ffmpeg.org/)
- [MusicBrainz Picard](https://picard.musicbrainz.org/) (optional)

OpusBox was originally built around the yt-dlp and FFmpeg binaries installed by Stacher, but paths can be configured in the application.

Typical Stacher paths:

```text
C:\Users\<username>\.stacher\yt-dlp.exe
C:\Users\<username>\.stacher\ffmpeg.exe
C:\Users\<username>\.stacher\ffprobe.exe
```

## Why Opus?

YouTube commonly serves high-quality Opus audio. Converting that audio to FLAC does not restore lost information; it only creates a larger file.

OpusBox therefore keeps YouTube audio as Opus.

If a genuine lossless source is available elsewhere, keeping the original FLAC is preferable.

## Resume / Sync Protection

Each playlist folder contains:

```text
.opusbox-download-archive.txt
```

yt-dlp records successfully completed items in this archive.

When the same playlist is run again, already archived tracks are skipped automatically. This makes OpusBox useful as an additive playlist sync tool.

**Do not delete the archive file** if you want reliable resume behavior.

Removing a track from the online playlist does not currently delete the local copy.

## Watchdog

Some yt-dlp stalls are not caught by a normal socket timeout.

OpusBox therefore monitors completed-track progress. If no new track completes for **3 minutes**, it:

1. Detects the stall.
2. Terminates the stuck yt-dlp process.
3. Restarts the same download.
4. Reuses the existing download archive.
5. Skips everything already completed.
6. Continues from there.

The watchdog allows up to **3 automatic restarts** before stopping to avoid an infinite retry loop.

Example:

```text
WATCHDOG: No completed track for 180 seconds.
WATCHDOG: Killing stalled yt-dlp process; automatic restart 1 of 3.
Watchdog restart 1 of 3: resuming from download archive.
```

## Progress Display

A status such as:

```text
361 / 1056 tracks complete
Latest: 531 - Hide & Seek
```

contains two different values:

- `361` is the number of successfully completed / archived tracks.
- `531` is the original playlist position of the most recently completed file.

These values can differ because playlist entries may be unavailable, skipped, previously archived, private, deleted, or failed.

## Failure Reporting

When failures are detected, OpusBox can write:

```text
OpusBox-Failed-Tracks.txt
```

inside the playlist folder.

Failed tracks are not added to the yt-dlp archive, so a later sync can attempt them again.

## MusicBrainz Picard

Picard can be used to improve metadata such as:

- Title
- Artist
- Album
- Album artist
- Track number
- Release information
- MusicBrainz IDs
- Artwork

For large mixed playlists, OpusBox avoids treating the entire playlist as one album and instead supports smaller batch-based processing.

## Tag Existing Music

Use **Tag Existing Music** to process already-downloaded Opus files through the Picard workflow.

This is useful when:

- Automatic tagging was disabled during the original download
- A large playlist was downloaded first and will be tagged later
- Existing metadata needs cleanup

## Automatic Tagging During Sync

Before downloading, OpusBox snapshots the Opus files already present in the destination folder.

After the run, only files that are new are selected for automatic Picard processing. Existing library files do not need to be rescanned every sync.

## Folder Example

```text
Music\
└── Favorites tracks\
    ├── 001 - Song Name.opus
    ├── 002 - Another Song.opus
    ├── ...
    ├── .opusbox-download-archive.txt
    └── OpusBox-Failed-Tracks.txt
```

## Settings

Settings are stored under:

```text
%APPDATA%\OpusBox\settings.json
```

Saved values include tool paths, output location, automatic tagging preference, and whether the output folder should open after completion.

## Known yt-dlp / Stacher Warning

Some systems may show a `virtual_file.log` permission warning. This does not always mean the audio download failed.

OpusBox keeps stdout and stderr separate during playlist metadata parsing so this warning does not corrupt preview data.

## Project Structure

```text
OpusBox/
├── README.md
├── LICENSE
├── .gitignore
├── src/
│   └── OpusBox.ps1
└── docs/
    └── OpusBox_README.docx
```

Compiled Windows builds are best published through **GitHub Releases** rather than committed directly to the source tree.

## Future Ideas

- Duplicate detection
- Prefer genuine lossless copies over lossy duplicates
- Prefer studio versions over live versions
- Duplicate review screen
- Separate playlist-position and completed-track progress
- Better exact Picard success/failure reporting
- Detect removed online playlist items without automatically deleting local files
- Optional FLAC source lookup before falling back to YouTube Opus
- Library health scanning
- Automatic metadata validation

## License

MIT License. See `LICENSE`.

## Note

OpusBox is a personal/open-source utility built with assistance from AI coding tools and iterative human testing, design, debugging, and feature decisions.
