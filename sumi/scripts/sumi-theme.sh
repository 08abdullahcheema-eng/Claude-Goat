# sumi-theme <name> [wall.jpg] [layout]   switch theme (sumi iso kiri hagane summit),
#                                        optionally with one of its wallpapers and a bar layout
# sumi-theme --wall <wall.jpg>   change only the wallpaper of the current theme
# sumi-theme --layout <layout>   change only the bar layout: islands capsule rail side ridge notch pill bottom corners, or auto
# sumi-theme --restore  re-apply the saved theme (wallpaper, borders, kitty, lock screen)
# sumi-theme --init     write the theme files if missing, touch nothing that is running
set -u
SHELL_DIR="${SUMI_SHELL_DIR:-$HOME/.config/quickshell/sumi}"
CONF="$HOME/.config/sumi"
mkdir -p "$CONF"

mode="${1:---restore}"
case "$mode" in
  --restore|--init) ;;
  --wall)
    printf '%s' "${2:-}" > "$CONF/wall"
    mode="--restore"
    ;;
  --layout)
    case "${2:-auto}" in
      islands|capsule|rail|side|ridge|notch|pill|bottom|corners) printf '%s' "$2" > "$CONF/layout" ;;
      auto|"") rm -f "$CONF/layout" ;;
      *) echo "unknown layout: $2 (islands capsule rail side ridge notch pill bottom corners auto)" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  *)
    src="$SHELL_DIR/themes/$mode.json"
    if [ ! -f "$src" ]; then echo "unknown theme: $mode (have: $(ls "$SHELL_DIR/themes" | sed 's/.json//' | tr '\n' ' '))" >&2; exit 1; fi
    cp "$src" "$CONF/theme.json.tmp" && mv "$CONF/theme.json.tmp" "$CONF/theme.json"
    chmod u+w "$CONF/theme.json"
    # a theme switch resets the wallpaper unless one was named
    if [ -n "${2:-}" ]; then printf '%s' "$2" > "$CONF/wall"; else rm -f "$CONF/wall"; fi
    # and the bar layout: a named one, or the theme's own
    case "${3:-}" in
      islands|capsule|rail|side|ridge|notch|pill|bottom|corners) printf '%s' "$3" > "$CONF/layout" ;;
      *) rm -f "$CONF/layout" ;;
    esac
    mode="--restore"
    ;;
esac

if [ ! -f "$CONF/theme.json" ]; then
  cp "$SHELL_DIR/themes/sumi.json" "$CONF/theme.json"; chmod u+w "$CONF/theme.json"
fi

t="$CONF/theme.json"
get() { jq -r ".$1" "$t"; }
name=$(get name)
# a theme that no longer exists (removed in an update) falls back to sumi
if [ ! -f "$SHELL_DIR/themes/$name.json" ]; then
  cp "$SHELL_DIR/themes/sumi.json" "$t"; chmod u+w "$t"; rm -f "$CONF/wall"; name=sumi
fi
w0=$(jq -r '.walls[0] // empty' "$t")
wall="$SHELL_DIR/assets/walls/${w0:-wall-$name.jpg}"
wf=$(cat "$CONF/wall" 2>/dev/null || true)
# only one of the theme's own wallpapers (so "sumi" never picks up a "summit" picture)
if [ -n "$wf" ] && jq -e --arg w "$wf" '.walls | index($w)' "$t" >/dev/null 2>&1 && [ -f "$SHELL_DIR/assets/walls/$wf" ]; then
  wall="$SHELL_DIR/assets/walls/$wf"
fi
[ -f "$wall" ] || wall="$SHELL_DIR/assets/walls/wall-sumi-ink.jpg"
hex() { get "$1" | tr -d '#'; }
dark=$(get dark)
if [ "$dark" = "true" ]; then ink=$(hex bg); else ink=$(hex hi); fi

# lock screen colours (sourced by hyprlock.conf)
cat > "$CONF/hyprlock-colors.conf.tmp" <<EOC
\$sumi_wall = $wall
\$sumi_ink = rgb($ink)
\$sumi_bg = rgba($(hex bg)d9)
\$sumi_fg = rgb($(hex fg))
\$sumi_hi = rgb($(hex hi))
\$sumi_mute = rgb($(hex mute))
\$sumi_dim = rgb($(hex dim))
\$sumi_line = rgb($(hex line2))
\$sumi_accent = rgb($(hex accent))
\$sumi_gold = rgb($(hex gold))
\$sumi_green = rgb($(hex green))
EOC
mv "$CONF/hyprlock-colors.conf.tmp" "$CONF/hyprlock-colors.conf"

# kitty colours (included at the end of kitty.conf)
{
  echo "# written by sumi-theme ($name)"
  echo "foreground $(get fg)"
  echo "background $(get bg)"
  echo "cursor $(get hi)"
  echo "selection_foreground $(get hi)"
  echo "selection_background $(get sel)"
  echo "url_color $(get blue)"
  echo "active_border_color $(get accent)"
  echo "inactive_border_color $(get line2)"
  echo "active_tab_background $(get accent)"
  echo "active_tab_foreground $(get onAccent)"
  echo "inactive_tab_background $(get bg1)"
  echo "inactive_tab_foreground $(get dim)"
  for i in $(seq 0 15); do echo "color$i $(jq -r ".ansi[$i]" "$t")"; done
} > "$CONF/kitty.conf.tmp"
mv "$CONF/kitty.conf.tmp" "$CONF/kitty.conf"

# lock screen layout of the theme
lock="$SHELL_DIR/locks/$name.conf"; [ -f "$lock" ] || lock="$SHELL_DIR/locks/sumi.conf"
cp "$lock" "$CONF/hyprlock-theme.conf.tmp" && chmod u+w "$CONF/hyprlock-theme.conf.tmp" && mv "$CONF/hyprlock-theme.conf.tmp" "$CONF/hyprlock-theme.conf"

# active window border: the theme's gradient (it turns on focus changes, see borderangle), else the accent
border=$(jq -r '.border // empty' "$t"); [ -n "$border" ] || border="rgb($(hex accent))"

# Hyprland part of the theme (sourced by hyprland.conf): borders and the theme's animations
{
  echo "# written by sumi-theme ($name)"
  echo "general {"
  echo "  col.active_border = $border"
  echo "  col.inactive_border = rgb($(hex line))"
  echo "}"
  jq -r '.bezier[]? | "bezier = " + .' "$t"
  jq -r '.animation[]? | "animation = " + .' "$t"
} > "$CONF/hypr-theme.conf.tmp"
mv "$CONF/hypr-theme.conf.tmp" "$CONF/hypr-theme.conf"

# login screen (SDDM): the same wallpaper, logo and colours, in a folder the greeter can read
# (/var/lib/sumi, created by sumi-login.nix). Skipped quietly when the folder is not there.
L="${SUMI_LOGIN_DIR:-/var/lib/sumi}"
if [ -d "$L" ] && [ -w "$L" ]; then
  cp "$wall" "$L/login-wall.jpg.tmp" 2>/dev/null && mv "$L/login-wall.jpg.tmp" "$L/login-wall.jpg"
  logo="$SHELL_DIR/assets/$(get logo)"; [ -f "$logo" ] || logo="$SHELL_DIR/assets/logo-sumi.svg"
  cp "$logo" "$L/logo.svg.tmp" 2>/dev/null && mv "$L/logo.svg.tmp" "$L/logo.svg"
  case "$name" in hagane) rad=4 ;; sumi|summit) rad=16 ;; *) rad=24 ;; esac
  q() { get "$1" | sed 's/"/\\"/g'; }
  cat > "$L/palette.qml.tmp" <<EOQ
import QtQuick
// written by sumi-theme ($name), read by the Sumi login screen
Item {
    property string name: "$name"
    property string label: "$(q label)"
    property string kanji: "$(q kanji)"
    property color bg: "$(get bg)"
    property color bg1: "$(get bg1)"
    property color line: "$(get line)"
    property color mute: "$(get mute)"
    property color dim: "$(get dim)"
    property color fg: "$(get fg)"
    property color hi: "$(get hi)"
    property color accent: "$(get accent)"
    property color accent2: "$(get accent2)"
    property color error: "$(get error)"
    property string head: "$(q fontHead)"
    property string body: "$(q fontBody)"
    property real radius: $rad
}
EOQ
  mv "$L/palette.qml.tmp" "$L/palette.qml"
  chmod a+r "$L/login-wall.jpg" "$L/logo.svg" "$L/palette.qml" 2>/dev/null || true
fi

if [ "$mode" = "--init" ]; then exit 0; fi

# live parts: only when a Hyprland session is running
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  hyprctl keyword general:col.active_border "$border" >/dev/null 2>&1 || true
  hyprctl keyword general:col.inactive_border "rgb($(hex line))" >/dev/null 2>&1 || true
  batch=$( { jq -r '.bezier[]? | "keyword bezier " + .' "$t"; jq -r '.animation[]? | "keyword animation " + .' "$t"; } | paste -sd ';' - )
  [ -n "$batch" ] && hyprctl --batch "$batch" >/dev/null 2>&1 || true
fi
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
  old=$(pgrep -x swaybg || true)
  setsid -f swaybg -i "$wall" -m fill >/dev/null 2>&1
  # let the new wallpaper map before removing the old one (no black flash)
  if [ -n "$old" ]; then (sleep 0.6; kill $old 2>/dev/null) & fi
fi
# keyboard follows the theme accent (PredatorSense panel option)
kb=/sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi/four_zoned_kb
if [ -w "$kb/per_zone_mode" ] && grep -q '"followTheme": true' "$CONF/predator.json" 2>/dev/null; then
  a=$(hex accent)
  br=$(cut -d, -f5 "$kb/per_zone_mode" 2>/dev/null || echo 70)
  [ -n "$br" ] || br=70
  printf '0,1,%s,1,%d,%d,%d' "$br" "0x${a:0:2}" "0x${a:2:2}" "0x${a:4:2}" > "$kb/four_zone_mode" 2>/dev/null || true
  printf '%s,%s,%s,%s,%s' "$a" "$a" "$a" "$a" "$br" > "$kb/per_zone_mode" 2>/dev/null || true
fi
for p in kitty .kitty-wrapped; do pkill -USR1 -x "$p" 2>/dev/null || true; done
exit 0
