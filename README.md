# mp3trackprefix

`mp3trackprefix` is a conservative Linux command-line tool that prefixes each
MP3's ID3 `TITLE` with its track number. It is intended for players such as the
Mazda 6e that alphabetize songs by title rather than ordering them by the ID3
track field.

```text
TITLE=In the Air Tonight     -> TITLE=01 In the Air Tonight
TRACK=1/12                  -> TRACK=1/12 (unchanged)
```

Only `TITLE` is written. Filenames, track/disc/album/artist tags, cover art, and
all other metadata are left intact.

## Requirements

- Linux or another environment with GNU-style `find` and `sort`
- Bash 4.4 or newer
- [ExifTool](https://exiftool.org/) (`exiftool`), used for Unicode-safe ID3
  reading and narrowly targeted title updates

On Debian/Ubuntu:

```bash
sudo apt install libimage-exiftool-perl
```

## Installation

```bash
install -Dm755 mp3trackprefix "$HOME/.local/bin/mp3trackprefix"
```

Ensure `$HOME/.local/bin` is in your `PATH`.

## Usage

```bash
mp3trackprefix /media/usb/Music
mp3trackprefix --verbose /media/usb/Music
mp3trackprefix --help
mp3trackprefix --version
```

Each directory containing MP3 files is treated as one album. Scanning is
recursive, but files in parent and child directories are validated as separate
albums. Track tags such as `1`, `01`, `1/12`, and `01/12` are supported. Albums
use at least two-digit prefixes and automatically expand to three or more digits
when needed for lexical sorting.

The operation is idempotent: prefixes such as `01 Song`, `01 - Song`,
`01. Song`, and `01_ Song` are normalized to `01 Song`, not duplicated.

## Dry run

Always consider previewing removable media first:

```bash
mp3trackprefix --dry-run /media/usb/Music
```

Example output:

```text
[DRY-RUN] 01 - In the Air Tonight.mp3
          TITLE: "In the Air Tonight"
           ->    "01 In the Air Tonight"
[SKIPPED] /media/usb/Music/Phil Collins/Face Value
          Tracks: 12
          Dry-run; titles that would change: 12
```

Here `[SKIPPED]` means writes were intentionally suppressed by dry-run, not
that validation failed. The per-file lines show exactly what would be written.

## Folder validation and safety

Before changing a folder, the program reads **every** MP3 in it. A file's track
tag is authoritative, but an unambiguous filename track is also checked. A
filename can supply a missing track/title only for deliberately narrow formats:

```text
01 - Song Title.mp3
01. Song Title.mp3
01 Song Title.mp3
01_Song_Title.mp3
Artist - Album - 01 - Song Title.mp3
Artist - Album - [01] - Song Title.mp3
CD1 - 01 - Song Title.mp3
```

No file in the folder is modified unless every file has a positive track number
and usable title, all track numbers are unique, and tag/filename evidence is
consistent. Arbitrary numbers elsewhere in a filename are not guessed as track
numbers. ExifTool is invoked with a `Title` assignment only, preserving other
metadata and embedded artwork.

Problems that cause the complete folder to be skipped include:

- missing or malformed `TRACK` with no safe filename fallback;
- missing `TITLE` that cannot be reconstructed from a recognized filename;
- different track numbers in `TRACK` and the filename;
- duplicate track numbers;
- zero, impossible `track/total`, or otherwise invalid track values;
- a filename matching multiple recognized interpretations inconsistently.

Folder outcomes are `[OK]` (already normalized), `[CHANGED]`, `[WARN]`
(metadata problem), `[SKIPPED]` (dry-run writes suppressed), or `[ERROR]`.

Exit status is `0` after a clean scan, `1` if one or more folders had incomplete
or conflicting metadata, and `2` for invalid arguments, missing dependencies,
or a fatal write error.
