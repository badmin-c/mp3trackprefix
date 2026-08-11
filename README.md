# mp3trackprefix

> [!IMPORTANT]
> **Disclaimer:** This tool was created 100% by OpenAI Codex. It is provided
> without warranty; review the code and use it at your own risk, especially
> before modifying valuable or irreplaceable music collections.

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
- [FFmpeg](https://ffmpeg.org/) (`ffmpeg` and `ffprobe`), used for ID3 metadata
  reading and lossless MP3 remuxing with a narrowly targeted title update

On Debian/Ubuntu:

```bash
sudo apt install ffmpeg
```

## Installation

```bash
install -Dm755 mp3trackprefix "$HOME/.local/bin/mp3trackprefix"
```

Ensure `$HOME/.local/bin` is in your `PATH`.

### Windows (WSL, tested)

The recommended way to use `mp3trackprefix` on Windows is through the Windows
Subsystem for Linux (WSL). **The WSL setup has been tested.** If WSL is not yet
available, install it from an elevated PowerShell prompt with `wsl --install`
and complete the short setup of the default Ubuntu distribution; see
[Microsoft's WSL documentation](https://learn.microsoft.com/windows/wsl/install)
for details.

Inside the WSL terminal, install FFmpeg and the script just as on Ubuntu:

```bash
sudo apt update
sudo apt install ffmpeg
install -Dm755 mp3trackprefix "$HOME/.local/bin/mp3trackprefix"
```

Windows drives are mounted below `/mnt`. For example, process music on drive
`D:` with a dry run first:

```bash
mp3trackprefix --dry-run /mnt/d/Music
mp3trackprefix /mnt/d/Music
```

### macOS (untested)

**macOS support has not been tested.** The system-provided Bash and command-line
tools do not meet all requirements, so install current Bash, FFmpeg, and the GNU
utilities with [Homebrew](https://brew.sh/):

```bash
brew install bash ffmpeg findutils coreutils
```

Make the Homebrew and GNU utility directories take precedence for the current
terminal, then run or install the script as described above:

```bash
export PATH="$(brew --prefix)/bin:$(brew --prefix findutils)/libexec/gnubin:$(brew --prefix coreutils)/libexec/gnubin:$PATH"
./mp3trackprefix --dry-run "$HOME/Music"
```

Add that `PATH` setting to your shell configuration if you want it to persist.

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
01-Song Title.mp3
01_Song_Title.mp3
Artist - Album - 01 - Song Title.mp3
Artist - Album - [01] - Song Title.mp3
CD1 - 01 - Song Title.mp3
Song Title - Track 01.mp3
```

No file in the folder is modified unless every file has a positive track number
and usable title, all track numbers are unique, and tag/filename evidence is
consistent. Arbitrary numbers elsewhere in a filename are not guessed as track
numbers. FFmpeg copies every stream without re-encoding, maps the existing
metadata, and overrides only `title`, preserving other metadata and embedded
artwork. The completed temporary file atomically replaces the original.

Problems that cause the complete folder to be skipped include:

- missing or malformed `TRACK` with no safe filename fallback;
- missing `TITLE` that cannot be reconstructed from a recognized filename;
- different track numbers in `TRACK` and the filename;
- duplicate track numbers;
- zero, impossible `track/total`, or otherwise invalid track values;
- a filename matching multiple recognized interpretations inconsistently.

Folder outcomes are `[OK]` (already normalized), `[CHANGED]`, `[WARN]`
(metadata problem), `[SKIPPED]` (dry-run writes suppressed), or `[ERROR]`.
After the counters in the final summary, every folder that could not be processed
correctly is listed again. This includes folders skipped because validation failed
and folders in which writing a title failed; intentional dry-run suppression is
not considered a processing failure.

Exit status is `0` after a clean scan, `1` if one or more folders had incomplete
or conflicting metadata, and `2` for invalid arguments, missing dependencies,
or a fatal write error.
