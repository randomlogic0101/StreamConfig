#!/usr/bin/env bash
set -euxo pipefail

echo "Starting EXWM container..."

export DISPLAY=":99"
export VNC_PORT=5900

# -----------------------------
# Font setup
# -----------------------------
FONT_DIRS=(
    "/home/$USERNAME/.local/share/fonts"
    "/usr/local/share/fonts"
    "/usr/share/fonts"
    "/home/$USERNAME/.fonts"
)

# Maybe this will fix the font issue. This is a pain...
echo "Rebuilding font cache from host..."
for dir in "${FONT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Caching fonts in: $dir"
        fc-cache -fv "$dir"
    else
        echo "Skipping non-existent directory: $dir"
    fi
done

# -----------------------------
# Start Xvfb
# -----------------------------
echo "Starting Xvfb on $DISPLAY..."
#Xvfb "$DISPLAY" -screen 0 2560x1600x24 -dpi 96 -nolisten tcp &
Xvfb "$DISPLAY" -screen 0 2560x1600x24 -dpi 125 &
XVFB_PID=$!

# -----------------------------
# Wait for Xvfb to be ready
# -----------------------------
echo "Waiting for Xvfb..."
until xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; do
    sleep 0.5
done
echo "Xvfb is ready"

# -----------------------------
# Start x11vnc (THIS WAS MISSING)
# -----------------------------
echo "Starting x11vnc..."
x11vnc \
  -display "$DISPLAY" \
  -nopw \
  -forever \
  -shared \
  -rfbport "$VNC_PORT" \
  -listen 0.0.0.0 \
  -xkb \
  -noxrecord -noxfixes -noxdamage &
VNC_PID=$!

# -----------------------------
# Confirm VNC is actually listening
# -----------------------------
echo "Waiting for VNC port..."
until ss -tln | grep -q ":$VNC_PORT"; do
    sleep 0.2
done
echo "VNC is listening on port $VNC_PORT"

# -----------------------------
# Start Emacs EXWM
# -----------------------------
echo "Starting Emacs (EXWM)..."
emacs --display="$DISPLAY" --no-splash &

# -----------------------------
# Keep container alive
# -----------------------------
echo "Container fully started."
wait
