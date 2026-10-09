# sumi-theme <name>   switch theme (sumi, kin, ai, washi)
# sumi-theme --restore  re-apply the saved theme (wallpaper, borders, kitty, lock screen)
# sumi-theme --init     write the theme files if missing, touch nothing that is running
set -u
SHELL_DIR="${SUMI_SHELL_DIR:-$HOME/.config/quickshell/sumi}"
CONF="$HOME/.config/sumi"
mkdir -p "$CONF"

mode="${1:---restore}"
case "$mode" in
  --restore|--init) ;;
  *)
    src="$SHELL_DIR/themes/$mode.json"
    if [ ! -f "$src" ]; then echo "unknown theme: $mode (have: $(ls "$SHELL_DIR/themes" | sed 's/.json//' | tr '\n' ' '))" >&2; exit 1; fi
    cp "$src" "$CONF/theme.json.tmp" && mv "$CONF/theme.json.tmp" "$CONF/theme.json"
    chmod u+w "$CONF/theme.json"
    mode="--restore"
    ;;
esac

if [ ! -f "$CONF/theme.json" ]; then
  cp "$SHELL_DIR/themes/sumi.json" "$CONF/theme.json"; chmod u+w "$CONF/theme.json"
fi

t="$CONF/theme.json"
get() { jq -r ".$1" "$t"; }
name=$(get name)
wall="$SHELL_DIR/assets/walls/wall-$name.jpg"
[ -f "$wall" ] || wall="$SHELL_DIR/assets/walls/wall-sumi.jpg"
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

if [ "$mode" = "--init" ]; then exit 0; fi

# live parts: only when a Hyprland session is running
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  hyprctl keyword general:col.active_border "rgb($(hex accent))" >/dev/null 2>&1 || true
  hyprctl keyword general:col.inactive_border "rgb($(hex line))" >/dev/null 2>&1 || true
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
