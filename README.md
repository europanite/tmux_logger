# [tmux_logger](https://github.com/europanite/tmux_logger "tmux_logger")

A simple shellscript for logging tmux panes.

## Features

- Captures all tmux panes across all sessions
- Saves the latest pane content
- Appends snapshots only when content changes
- Stores pane metadata for later inspection

## Requirements

- tmux
- bash
- sha256sum

## Usage

```bash
chmod +x logger.sh
./logger.sh
```

Logs are written under:

```bash
./tmux-logs/<timestamp>/
```

## Output Files

For each pane, the script creates:

- `*.latest.txt` — latest captured pane content
- `*.history.log` — snapshot history
- `*.meta.txt` — pane metadata

## Notes

- The script polls tmux every second
- Only changed pane content is appended to history
- Pane, session, window, and title names are sanitized for filenames

## License

Apache 2.0