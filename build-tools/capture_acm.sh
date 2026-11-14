#!/bin/sh
set -u
end=$(( $(date +%s) + 90 ))
while [ "$(date +%s)" -lt "$end" ]; do
    found=0
    for dev in /dev/ttyACM*; do
        [ -c "$dev" ] || continue
        found=1
        stty -F "$dev" 115200 raw -echo 2>/dev/null || continue
        echo "--- ACM console on $dev at $(date) ---"
        timeout 12s cat "$dev" 2>/dev/null || true
    done
    [ "$found" -eq 1 ] || sleep 0.2
done
