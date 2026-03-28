#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${HOME}/tmux-logs"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${BASE_DIR}/${RUN_ID}"
STATE_DIR="${OUT_DIR}/.state"

mkdir -p "$OUT_DIR" "$STATE_DIR"

sanitize() {
  printf '%s' "$1" | tr '/ \t:' '____' | tr -cd '[:alnum:]_.@%=-'
}

echo "snapshot dir: $OUT_DIR"

while true; do
  tmux list-panes -a -F '#{pane_id}'$'\t''#{session_name}'$'\t''#{window_index}'$'\t''#{pane_index}'$'\t''#{window_name}'$'\t''#{pane_title}' 2>/dev/null |
  while IFS=$'\t' read -r pane_id session_name window_index pane_index window_name pane_title; do
    [ -n "${pane_id:-}" ] || continue

    safe_session="$(sanitize "$session_name")"
    safe_window="$(sanitize "$window_name")"
    safe_title="$(sanitize "$pane_title")"
    safe_pane="${pane_id#%}"

    base="${OUT_DIR}/${safe_session}__w${window_index}_p${pane_index}__${safe_pane}__${safe_window}__${safe_title}"
    latest_file="${base}.latest.txt"
    history_file="${base}.history.log"
    meta_file="${base}.meta.txt"
    hash_file="${STATE_DIR}/${safe_pane}.sha256"

    if ! tmux capture-pane -p -J -S -3000 -t "$pane_id" > "${latest_file}.tmp" 2>/dev/null; then
      rm -f "${latest_file}.tmp"
      continue
    fi

    if [ ! -f "$meta_file" ]; then
      {
        echo "pane_id=$pane_id"
        echo "session_name=$session_name"
        echo "window_index=$window_index"
        echo "pane_index=$pane_index"
        echo "window_name=$window_name"
        echo "pane_title=$pane_title"
        echo "started_at=$(date '+%F %T')"
      } > "$meta_file"
    fi

    new_hash="$(sha256sum "${latest_file}.tmp" | awk '{print $1}')"
    old_hash=""
    [ -f "$hash_file" ] && old_hash="$(cat "$hash_file")"

    mv "${latest_file}.tmp" "$latest_file"

    if [ "$new_hash" != "$old_hash" ]; then
      {
        printf '\n===== SNAPSHOT %s =====\n' "$(date '+%F %T')"
        cat "$latest_file"
        printf '\n'
      } >> "$history_file"
      printf '%s' "$new_hash" > "$hash_file"
    fi
  done

  sleep 1
done