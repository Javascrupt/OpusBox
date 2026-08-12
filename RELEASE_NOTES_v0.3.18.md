# OpusBox v0.3.18

This is a major stability and reliability update.

The previous public build had several problems with large playlists, missed tracks, Picard tagging, and repeat runs. v0.3.18 contains a substantial rewrite of those workflows.

## Highlights

- Added automatic second-pass recovery for missed tracks
- Fixed large playlists stopping after watchdog recovery limits
- Added targeted retry of only unresolved playlist entries
- Fixed recovery being blocked by stale yt-dlp archive entries
- Improved live download and recovery progress tracking
- Added YouTube authentication and `cookies.txt` support
- Added browser-session verification before marking YouTube authentication as connected
- Added Chrome to Firefox authentication fallback
- Added manual exported-cookie support
- Added reliable post-download MusicBrainz Picard tagging
- Added sequential Picard batch worker
- Added fresh timestamped Picard logs for every tagging run
- Added Picard queue completion tracking
- Added missing/stale-file protection during tagging
- Fixed PowerShell argument-binding and generated-worker issues
- Improved Picard batch counter accuracy
- Reduced unnecessary Picard windows
- Added YouTube video-ID based track identity
- Added duplicate prevention when playlist positions change
- Added local track identity manifest
- Added yt-dlp archive synchronization
- Added duplicate-track reporting

## Download Recovery

OpusBox now checks the files actually present on disk after the primary download pass.

If tracks are missing, it automatically runs a second targeted pass containing only those missing tracks.

During testing, a playlist that initially produced 852 files recovered to 1044 files after the second pass, leaving only 12 unresolved playlist entries.

## Duplicate Prevention

Older builds relied too heavily on playlist indexes. If YouTube changed the position of a track between runs, OpusBox could mistakenly download the same song again under a new index.

v0.3.18 now uses the YouTube video ID as the primary track identity. Playlist position is used for ordering and filenames, but not for deciding whether the song already exists.

This prevents repeat runs from creating large numbers of duplicate songs.

## Picard Tagging

The Picard workflow has been rebuilt around a sequential external worker.

Large libraries are processed in batches instead of being submitted all at once. Each run creates its own log, worker script, and file list under `%APPDATA%\OpusBox`.

The queue continues even if an individual file disappears or cannot be found.

The workflow has been tested through a full 42-batch Picard tagging run ending successfully with `Queue complete.`

## YouTube Authentication

OpusBox normally works without authentication.

If YouTube returns a bot/login challenge, OpusBox supports automatic browser-cookie import, Chrome, Firefox fallback, manually exported Netscape-format `cookies.txt` files, and validation before marking a session as connected.

## Release Assets

- `OpusBox-v0.3.18.exe`
- `OpusBox-v0.3.18-source.zip`

## Notes

This build has been heavily tested with a playlist containing more than 1,000 entries.

There may still be unavailable, private, deleted, or region-restricted YouTube videos that cannot be downloaded. OpusBox reports those separately instead of treating the entire job as failed.
