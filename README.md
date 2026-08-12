# OpusBox README Update

# OpusBox

OpusBox is a Windows desktop app for downloading YouTube and YouTube Music playlists as Opus audio files and optionally tagging them with MusicBrainz Picard.

It is designed around large music libraries, resumable downloads, automatic recovery, and a simple desktop workflow.

## Features

* Download full YouTube and YouTube Music playlists
* Output audio as Opus
* Embed metadata and artwork
* Resume interrupted downloads
* Automatically retry missed tracks
* Detect and recover tracks skipped during the first download pass
* Optional MusicBrainz Picard tagging
* Sequential Picard batch processing for large libraries
* Automatic tagging logs
* YouTube cookie authentication support
* Duplicate prevention using YouTube video IDs
* Detailed unresolved-track and duplicate-track reports

## Download Workflow

OpusBox first downloads the playlist normally using yt-dlp.

Completed downloads are recorded in a resume archive so future runs can skip tracks that were already downloaded.

After the main download pass finishes, OpusBox checks which playlist tracks are actually present on disk.

If tracks are missing, OpusBox automatically performs a targeted second pass containing only the missing tracks.

This second pass bypasses stale archive entries so a track can still be recovered even if yt-dlp previously marked it as downloaded.

## Duplicate Protection

Beginning with v0.3.18, OpusBox uses the YouTube video ID as the identity of a track instead of relying only on playlist position.

This prevents duplicate downloads when playlist indexes shift between runs.

OpusBox maintains a hidden track identity map inside the playlist folder:

`.opusbox-track-map.json`

Successful yt-dlp downloads are also recorded in:

`.opusbox-download-map.tsv`

These files allow OpusBox to keep the local library, playlist, and yt-dlp resume archive synchronized.

If duplicate video IDs are detected, OpusBox creates:

`OpusBox-Duplicate-Tracks.txt`

OpusBox does not automatically delete duplicate files.

## MusicBrainz Picard Tagging

After downloading, OpusBox can send the downloaded music to MusicBrainz Picard.

Large libraries are processed in sequential batches so Picard is not overloaded.

The default batch size is 25 tracks.

Each tagging run creates its own worker files and log under:

`%APPDATA%\OpusBox`

Example:

`picard-queue-20260811-211628-123.log`

`picard-queue-20260811-211628-123.ps1`

`picard-queue-20260811-211628-123-files.json`

The log tracks each batch and ends with:

`Queue complete.`

when tagging has finished successfully.

If a queued file is missing, OpusBox logs a warning and continues processing the rest of the library instead of stopping the entire tagging job.

## YouTube Authentication

OpusBox normally works without signing into YouTube.

In some cases, YouTube may return:

`Sign in to confirm you're not a bot`

If that happens, open:

**Advanced settings → YouTube authentication**

and use **Connect YouTube** or select an exported `cookies.txt` file.

OpusBox verifies the session before marking it as connected.

Authentication is only needed when YouTube requires it.

### If Automatic Connection Fails

Chrome may prevent yt-dlp from reading browser cookies because of Windows DPAPI or Chrome app-bound encryption.

OpusBox will attempt Firefox as a fallback.

If browser cookie import still fails, export a fresh Netscape-format `cookies.txt` file from a signed-in YouTube browser session and select it manually in OpusBox.

Treat exported cookies like a password or active login session.

Do not upload your cookies file to GitHub or share it with anyone.

## Recovery and Reports

If tracks remain unavailable after the automatic recovery pass, OpusBox creates:

`OpusBox-Failed-Tracks.txt`

The report lists playlist entries that still do not have a corresponding local Opus file.

Some unavailable tracks may be:

* deleted videos
* private videos
* region-restricted videos
* videos removed from YouTube
* videos temporarily unavailable to yt-dlp

## Requirements

OpusBox uses:

* yt-dlp
* FFmpeg / FFprobe
* MusicBrainz Picard

The application is currently designed for Windows.

## Current Version

**v0.3.18**

This release includes major reliability improvements for large playlists, second-pass recovery, Picard tagging, YouTube authentication, progress tracking, and duplicate prevention.

## License

MIT License
