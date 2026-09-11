#!/bin/zsh
# Small helper for talking to the Duet 2 Ethernet over its HTTP API.
#   scripts/duet.sh pull            # download every file in 0:/sys into ./sys
#   scripts/duet.sh push [files...] # upload given files (default: all of ./sys) with CRC + read-back check
#   scripts/duet.sh gcode 'M115'    # send a G-code and print the reply
#   scripts/duet.sh model 'heat.heaters[0]'   # query the object model
# The Duet address comes from $DUET_HOST or from a .duet-host file in the repo root (gitignored,
# one line, e.g. 10.0.1.22). Set DUET_PASSWORD if you changed it from the default "reprap".
# The Duet's HTTP session lasts 8 s and the W5500 has few sockets, so we reconnect before every
# request and pause between bulk transfers.
set -e
cd "$(dirname "$0")/.."
host="${DUET_HOST:-$( [ -f .duet-host ] && head -n1 .duet-host )}"
[ -n "$host" ] || { echo "duet.sh: set DUET_HOST or put the Duet address in .duet-host" >&2; exit 1; }
H="http://$host"
PW="${DUET_PASSWORD:-reprap}"
now() { date +%Y-%m-%dT%H:%M:%S; }
conn() { curl -s -m 10 "$H/rr_connect?password=$PW&time=$(now)" >/dev/null; }
enc() { python3 -c 'import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))' "$1"; }
crc() { python3 -c 'import zlib,sys;print("%08x"%(zlib.crc32(open(sys.argv[1],"rb").read())&0xffffffff))' "$1"; }
case "$1" in
  pull)
    conn; curl -s -m 20 "$H/rr_filelist?dir=0:/sys" | python3 -c 'import json,sys;print("\n".join(f["name"] for f in json.load(sys.stdin)["files"] if f["type"]=="f"))' | while read -r f; do
      conn; curl -s -m 60 "$H/rr_download?name=0:/sys/$f" -o "sys/$f"; echo "pulled $f"; sleep 1; done ;;
  push)
    shift; files=("$@"); [ ${#files} -eq 0 ] && files=(sys/*)
    for f in "${files[@]}"; do b=$(basename "$f")
      conn; r=$(curl -s -m 120 -X POST --data-binary "@$f" "$H/rr_upload?name=0:/sys/$b&time=$(now)&crc32=$(crc "$f")"); sleep 2
      conn; if [ "$r" = '{"err":0}' ] && curl -s -m 120 "$H/rr_download?name=0:/sys/$b" | cmp -s - "$f"; then echo "ok $b"; else echo "FAILED $b: $r"; exit 1; fi; sleep 1
    done ;;
  gcode)
    # Guard: refuse motion / extrusion / temperature / macro commands while a print is running,
    # unless DUET_FORCE=1. (2026-09-11: a setup script queued G1 Z50 into a running print.)
    if [ -z "$DUET_FORCE" ] && echo "$2" | grep -qiE '^(G0|G1|G28|G29|G30|G32|M98|M104|M109|M140|M190|M568|M32|M83|M82|G91|G90)\b'; then
      conn; st=$(curl -s -m 20 "$H/rr_model?key=state.status" | python3 -c 'import json,sys;print(json.load(sys.stdin)["result"])' 2>/dev/null)
      case "$st" in processing|paused|pausing|resuming|busy) echo "REFUSED: printer is '$st' - not sending '$2' (set DUET_FORCE=1 to override)"; exit 2;; esac
    fi
    conn; curl -s -m 20 "$H/rr_gcode?gcode=$(enc "$2")" >/dev/null; sleep "${3:-2}"; conn; curl -s -m 20 "$H/rr_reply"; echo ;;
  model)
    conn; curl -s -m 20 "$H/rr_model?key=$(enc "$2")&flags=d99" | python3 -m json.tool ;;
  *) sed -n '2,8p' "$0"; exit 1 ;;
esac
