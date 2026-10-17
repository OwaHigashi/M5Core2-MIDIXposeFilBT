#!/usr/bin/env bash
# Build / upload wrapper for M5Core2-MIDIXposeFilBT (Git Bash version of build.cmd).
#   ./build.sh                  -> compile, then list the COM ports (comports.ps1)
#   ./build.sh --upload -p COM4 -> compile + upload
set -e
SKETCH_DIR="$(cd "$(dirname "$0")" && pwd)"
# arduino-cli.exe on Windows wants a native path, not /d/...
if command -v cygpath >/dev/null 2>&1; then
  SKETCH_DIR="$(cygpath -m "$SKETCH_DIR")"
fi
COMPILE=(arduino-cli compile --fqbn m5stack:esp32:m5stack_core2)
if [ $# -gt 0 ]; then
  exec "${COMPILE[@]}" "$@" "$SKETCH_DIR"
fi
rc=0
"${COMPILE[@]}" "$SKETCH_DIR" || rc=$?
if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SKETCH_DIR/comports.ps1" || true
  echo "  upload: ./build.sh --upload -p COMx"
fi
exit $rc
