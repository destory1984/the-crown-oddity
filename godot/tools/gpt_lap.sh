#!/usr/bin/env bash
# Run one Codex (GPT) playtest lap that plays the game by hand through Open Godot MCP.
# usage: bash tools/gpt_lap.sh ORDER_FILE LOG_FILE   (the Godot editor must be open on this project: bridge 127.0.0.1:6970)
cd "$(dirname "$0")/.." || exit 1
EXE="${OPEN_GODOT_MCP:-$HOME/.local/bin/open-godot-mcp.exe}"
args=(-c 'windows.sandbox="unelevated"' --sandbox workspace-write
  -c "mcp_servers.godot.command=\"$EXE\""
  -c 'mcp_servers.godot.args=["--projects","."]'
  -c 'mcp_servers.godot.env={PYTHONIOENCODING="utf-8"}'
  -c 'mcp_servers.godot.tool_timeout_sec=120')
for t in godot_health godot_game godot_exec godot_input godot_screenshot godot_runtime_state godot_log godot_game_time; do
  args+=(-c "mcp_servers.godot.tools.$t.approval_mode=\"approve\"")
done
codex exec --skip-git-repo-check "${args[@]}" -C . - < "$1" > "$2" 2>&1
