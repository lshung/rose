# ROSE (Rclone Organized Synchronization Expert)

ROSE is a minimal, scriptable CLI to safely synchronize files between your local machine and a cloud storage provider via rclone. It provides:

- Interactive one-time remote configuration
- Safe, review-then-apply sync workflow (using `rclone check` first)
- Directional sync (up: local -> remote, down: remote -> local)
- Per-sync timestamped backup directory to prevent accidental data loss
- Extensible filter rules, with user overrides
- Log management
- List or delete backup easily from the terminal


## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Install](#install)
- [Connect to Rclone remote](#connect-to-rclone-remote)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Sync](#sync)
  - [Backups](#backups)
  - [Logs](#logs)
- [Customization](#customization)
  - [Filter rules](#filter-rules)
  - [Root directories](#root-directories)
  - [Environment and paths](#environment-and-paths)
- [Troubleshooting](#troubleshooting)


## Overview
ROSE wraps `rclone` with a guard‐rail workflow:

1. For a sync run, it optionally performs `rclone check` first and generates a readable report.
2. You confirm the intended actions.
3. The tool performs `rclone sync` with `--checksum` and a timestamped `--backup-dir` so changed/deleted items are stored safely.

Defaults live in `env` and can be overridden in `~/.config/rose/rose.conf`.


## Prerequisites
- Linux with Bash
- `rclone`
- `jq` (used during provider selection)
- Python 3 (for the check report formatter)

ROSE will automatically install the dependencies if you are using the Arch-based, Debian-based, or RedHat-based distro. Otherwise, please manually install the required tools (`rclone`, `jq`, `python3`) using your package manager.


## Install
```bash
rm -rf "$HOME/.local/lib/rose" && mkdir -p "$HOME/.local/lib/rose"
git clone https://github.com/lshung/rose.git "$HOME/.local/lib/rose"
mkdir -p "$HOME/.local/bin/"
ln -sf "$HOME/.local/lib/rose/run" "$HOME/.local/bin/rose"
```

Please make sure that `$HOME/.local/bin` is in your `PATH`, so you can use the command `rose` directly.


## Connect to Rclone remote
You can connect ROSE to a cloud storage by either using ROSE to create the remote, or by pointing ROSE to an already existing rclone remote.

### Option 1: Create a remote using ROSE
```bash
rose config
```

- Follow the prompts to select a provider and complete authorization.
- This creates a remote named `rose` by default.

### Option 2: Use an existing rclone remote
If you already set up a remote via `rclone config`, set its name in your config file:
```bash
mkdir -p ~/.config/rose
${EDITOR:-nano} ~/.config/rose/rose.conf
```

Add or update:
```bash
REMOTE_NAME="<your-existing-remote-name>"
```

### Test the connection
```bash
rose test
```


## Configuration
Create the optional user config file:
```bash
mkdir -p ~/.config/rose
${EDITOR:-nano} ~/.config/rose/rose.conf
```

Examples of useful overrides:
```bash
# ~/.config/rose/rose.conf

# Rclone remote name
REMOTE_NAME="rose"
# Array of root directory pairs, each entry is a comma-separated pair and has the format of 'local_path, remote_path'
ROOT_DIRS=(
    "${XDG_DATA_HOME:-$HOME/.local/share}/rose/Data, ${REMOTE_NAME}:Rose/Data"
    # Add more directory pairs if desired, for example:
    # "$HOME/Music, ${REMOTE_NAME}:Music"
)
# The direction for sync, but can be overridden by the explicit command option
SYNC_DIRECTION="up"    # Or "down"
# Run 'rclone check' before the real sync
SYNC_CHECK="yes"       # Or "no" to skip pre-check (use with caution)
# Log rotation
LOG_FILE_COUNT=30
# Backup directory on remote
REMOTE_BACKUP_DIR="$REMOTE_NAME:rose/Backup"
# Backup directory on local
LOCAL_BACKUP_DIR="$HOME/.local/share/rose/Backup"
```


## Usage
Show global help:
```bash
rose --help
```

Or show help of individual module, for example:
```bash
rose sync --help
```

### Sync
Synchronize all directory pairs in `ROOT_DIRS`.
```bash
# Default direction (from `~/.config/rose/rose.conf` or `env`, default is 'up')
rose sync

# Explicit directions
rose sync --direction up      # Local -> Remote
rose sync --direction down    # Remote -> Local

# Skip the safety pre-check (not recommended unless you know what you're doing)
rose sync --no-check
```

Workflow when pre-check is enabled:
- Runs `rclone check`.
- Shows the report.
- Confirms before executing the real sync.
- Live sync runs:
  - Up: backups stored under `$REMOTE_BACKUP_DIR/<timestamp>`
  - Down: backups stored under `$LOCAL_BACKUP_DIR/<timestamp>`

Terminal requirement: width ≥ 100 columns (enforced to keep the report readable).

### Backups
List backups on remote or local.
```bash
rose backup --list                    # List on the default source (remote)
rose backup --list --source local     # List on local
rose backup --list --source remote    # List on remote
```

Delete backups on remote or local
```bash
rose backup --delete path/inside/Backup                    # Delete on the default source (remote)
rose backup --delete path/inside/Backup --source remote    # Delete on local
rose backup --delete path/inside/Backup --source local     # Delete on remote
```

The path provided for `rose backup --delete` does not contain the value of $REMOTE_BACKUP_DIR, or $LOCAL_BACKUP_DIR, or '/' at be beginning. You should copy and paste exactly from `rose backup --list`

### Logs
```bash
rose log --dir       # Show the log directory path
rose log --last      # Print content of the last log file
rose log --remove    # Remove all log files
```


## Customization
### Filter rules
Default rules live at `filter-rules.txt`. A user-level override can be added at `~/.config/rose/filter-rules.txt`. The effective rules are concatenated together, not overridden.

Rule syntax (same as `rclone`):
- Lines starting with `-` exclude
- Lines starting with `+` include
- Lines starting with `#` are comments

### Root directories
Set pairs of local and remote roots in `ROOT_DIRS`. Each entry is a comma-separated pair:
```bash
ROOT_DIRS=(
    "/local/path, ${REMOTE_NAME}:Remote/Path"
)
```

During a sync, each pair is processed in order. You can add multiple pairs.

### Environment and paths
Key defaults (can be overridden in `~/.config/rose/rose.conf`):
- `REMOTE_NAME`: Rclone remote identifier
- Paths for config, logs, state, data, backups
- `SYNC_DIRECTION` and `SYNC_CHECK`
- `CHECK_REPORT_REMOVE_IDENTICAL` to hide identical lines in reports

Please see the file `env` for the exact variable names.


## Troubleshooting
- Ensure `~/.local/bin` is on your `PATH` to use the `rose` command.
- Verify `rclone`, `jq`, and `python3` are installed and available.
- Use `rose log --last` to inspect the most recent run; logs live under `$HOME/.local/state/rose/logs`.
