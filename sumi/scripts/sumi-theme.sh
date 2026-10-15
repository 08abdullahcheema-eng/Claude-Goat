# sumi-theme <name> [wall.jpg] [layout]   switch theme (yoru koyo hotaru shinkai tsuki),
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
  cp "$SHELL_DIR/themes/yoru.json" "$CONF/theme.json"; chmod u+w "$CONF/theme.json"
fi

t="$CONF/theme.json"
get() { jq -r ".$1" "$t"; }
name=$(get name)
# a theme that no longer exists (removed in an update) falls back to yoru
if [ ! -f "$SHELL_DIR/themes/$name.json" ]; then
  cp "$SHELL_DIR/themes/yoru.json" "$t"; chmod u+w "$t"; rm -f "$CONF/wall" "$CONF/layout"; name=yoru
fi
w0=$(jq -r '.walls[0] // empty' "$t")
wall="$SHELL_DIR/assets/walls/${w0:-wall-$name.jpg}"
wf=$(cat "$CONF/wall" 2>/dev/null || true)
# only one of the theme's own wallpapers
if [ -n "$wf" ] && jq -e --arg w "$wf" '.walls | index($w)' "$t" >/dev/null 2>&1 && [ -f "$SHELL_DIR/assets/walls/$wf" ]; then
  wall="$SHELL_DIR/assets/walls/$wf"
fi
[ -f "$wall" ] || wall="$SHELL_DIR/assets/walls/wall-yoru-1.jpg"
hex() { get "$1" | tr -d '#'; }
dark=$(get dark)
if [ "$dark" = "true" ]; then ink=$(hex bg); else ink=$(hex hi); fi

# lock screen colours (sourced by hyprlock.conf)
cat > "$CONF/hyprlock-colors.conf.tmp" <<EOC
\$sumi_wall = $wall
\$sumi_assets = $SHELL_DIR/assets
\$sumi_avatar = $SHELL_DIR/assets/lock/avatar-$name.png
\$sumi_accent_soft = rgba($(hex accent)8c)
\$sumi_error = rgb($(hex error))
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

# ---- terminal apps: btop and neovim follow the theme ----
# btop: a theme file plus color_theme in btop.conf (left alone when home-manager owns it),
# running btops reload on SIGUSR2
bt="$HOME/.config/btop"
if mkdir -p "$bt/themes" 2>/dev/null && [ -w "$bt/themes" ]; then
  a() { jq -r ".ansi[$1]" "$t"; }
  cat > "$bt/themes/sumi.theme.tmp" <<EOB
# written by sumi-theme ($name)
theme[main_bg]="$(get bg)"
theme[main_fg]="$(get fg)"
theme[title]="$(get hi)"
theme[hi_fg]="$(get accent)"
theme[selected_bg]="$(get bg2)"
theme[selected_fg]="$(get hi)"
theme[inactive_fg]="$(get mute)"
theme[graph_text]="$(get dim)"
theme[meter_bg]="$(get line)"
theme[proc_misc]="$(get accent2)"
theme[cpu_box]="$(get line2)"
theme[mem_box]="$(get line2)"
theme[net_box]="$(get line2)"
theme[proc_box]="$(get line2)"
theme[div_line]="$(get line)"
theme[temp_start]="$(get green)"
theme[temp_mid]="$(get gold)"
theme[temp_end]="$(get accent)"
theme[cpu_start]="$(get mute)"
theme[cpu_mid]="$(get accent2)"
theme[cpu_end]="$(get accent)"
theme[free_start]="$(get green)"
theme[free_mid]="$(get green)"
theme[free_end]="$(get green)"
theme[cached_start]="$(get gold)"
theme[cached_mid]="$(get gold)"
theme[cached_end]="$(get gold)"
theme[available_start]="$(get cyan)"
theme[available_mid]="$(get cyan)"
theme[available_end]="$(get cyan)"
theme[used_start]="$(get accent2)"
theme[used_mid]="$(get accent)"
theme[used_end]="$(get accent)"
theme[download_start]="$(get mute)"
theme[download_mid]="$(get cyan)"
theme[download_end]="$(get cyan)"
theme[upload_start]="$(get mute)"
theme[upload_mid]="$(get accent2)"
theme[upload_end]="$(get accent)"
theme[process_start]="$(get dim)"
theme[process_mid]="$(get accent2)"
theme[process_end]="$(get accent)"
EOB
  mv "$bt/themes/sumi.theme.tmp" "$bt/themes/sumi.theme"
  bc="$bt/btop.conf"
  if [ ! -e "$bc" ]; then
    printf 'color_theme = "sumi"\ntheme_background = False\n' > "$bc"
  elif [ -f "$bc" ] && [ ! -L "$bc" ] && [ -w "$bc" ]; then
    if grep -q '^color_theme' "$bc"; then sed -i 's|^color_theme.*|color_theme = "sumi"|' "$bc"; else echo 'color_theme = "sumi"' >> "$bc"; fi
  fi
  pkill -USR2 -x btop 2>/dev/null || true
fi

# neovim: a colour scheme named "sumi" (use it with  vim.cmd.colorscheme("sumi")  in your init);
# running neovims that use it switch at once
nv="$HOME/.config/nvim/colors"
if mkdir -p "$nv" 2>/dev/null && [ -w "$nv" ]; then
  bgmode=dark; [ "$dark" = "true" ] || bgmode=light
  cat > "$nv/sumi.lua.tmp" <<EON
-- written by sumi-theme ($name)
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.o.background = "$bgmode"
vim.o.termguicolors = true
vim.g.colors_name = "sumi"
local c = {
  bg = "$(get bg)", bg1 = "$(get bg1)", bg2 = "$(get bg2)", line = "$(get line)", line2 = "$(get line2)",
  mute = "$(get mute)", dim = "$(get dim)", fg = "$(get fg)", hi = "$(get hi)",
  accent = "$(get accent)", accent2 = "$(get accent2)", gold = "$(get gold)", orange = "$(get orange)",
  green = "$(get green)", cyan = "$(get cyan)", blue = "$(get blue)", violet = "$(get violet)",
  sel = "$(get sel)", add = "$(get diffAdd)", del = "$(get diffDel)",
  error = "$(get error)", warn = "$(get warn)", info = "$(get info)", ok = "$(get ok)",
}
local h = function(g, o) vim.api.nvim_set_hl(0, g, o) end
h("Normal", { fg = c.fg, bg = c.bg })
h("NormalFloat", { fg = c.fg, bg = c.bg1 })
h("FloatBorder", { fg = c.line2, bg = c.bg1 })
h("FloatTitle", { fg = c.accent, bg = c.bg1, bold = true })
h("Cursor", { fg = c.bg, bg = c.hi })
h("CursorLine", { bg = c.bg1 })
h("CursorLineNr", { fg = c.accent, bold = true })
h("LineNr", { fg = c.mute })
h("SignColumn", { bg = c.bg })
h("ColorColumn", { bg = c.bg1 })
h("VertSplit", { fg = c.line })
h("WinSeparator", { fg = c.line })
h("StatusLine", { fg = c.fg, bg = c.bg1 })
h("StatusLineNC", { fg = c.mute, bg = c.bg1 })
h("TabLine", { fg = c.dim, bg = c.bg1 })
h("TabLineSel", { fg = c.hi, bg = c.bg2, bold = true })
h("TabLineFill", { bg = c.bg })
h("Pmenu", { fg = c.fg, bg = c.bg1 })
h("PmenuSel", { fg = c.hi, bg = c.bg2, bold = true })
h("PmenuSbar", { bg = c.bg1 })
h("PmenuThumb", { bg = c.line2 })
h("Visual", { bg = c.sel })
h("Search", { fg = c.bg, bg = c.gold })
h("IncSearch", { fg = c.bg, bg = c.accent })
h("CurSearch", { fg = c.bg, bg = c.accent })
h("MatchParen", { fg = c.accent, bold = true, underline = true })
h("NonText", { fg = c.line2 })
h("Whitespace", { fg = c.line })
h("Folded", { fg = c.dim, bg = c.bg1 })
h("Title", { fg = c.accent, bold = true })
h("Directory", { fg = c.blue })
h("ErrorMsg", { fg = c.error })
h("WarningMsg", { fg = c.warn })
h("MoreMsg", { fg = c.green })
h("Question", { fg = c.cyan })
h("Comment", { fg = c.mute, italic = true })
h("Constant", { fg = c.orange })
h("String", { fg = c.green })
h("Character", { fg = c.green })
h("Number", { fg = c.orange })
h("Boolean", { fg = c.orange })
h("Identifier", { fg = c.fg })
h("Function", { fg = c.blue })
h("Statement", { fg = c.accent2 })
h("Keyword", { fg = c.accent2, italic = true })
h("Conditional", { fg = c.accent2 })
h("Repeat", { fg = c.accent2 })
h("Operator", { fg = c.dim })
h("PreProc", { fg = c.violet })
h("Include", { fg = c.violet })
h("Type", { fg = c.cyan })
h("Special", { fg = c.gold })
h("Delimiter", { fg = c.dim })
h("Todo", { fg = c.bg, bg = c.gold, bold = true })
h("Error", { fg = c.error })
h("DiffAdd", { bg = c.add })
h("DiffDelete", { bg = c.del })
h("DiffChange", { bg = c.bg2 })
h("DiffText", { bg = c.sel })
h("DiagnosticError", { fg = c.error })
h("DiagnosticWarn", { fg = c.warn })
h("DiagnosticInfo", { fg = c.info })
h("DiagnosticHint", { fg = c.cyan })
h("DiagnosticOk", { fg = c.ok })
h("DiagnosticUnderlineError", { undercurl = true, sp = c.error })
h("DiagnosticUnderlineWarn", { undercurl = true, sp = c.warn })
h("GitSignsAdd", { fg = c.green })
h("GitSignsChange", { fg = c.gold })
h("GitSignsDelete", { fg = c.accent })
h("@variable", { fg = c.fg })
h("@variable.builtin", { fg = c.accent2 })
h("@property", { fg = c.fg })
h("@field", { fg = c.fg })
h("@parameter", { fg = c.hi })
h("@function.builtin", { fg = c.cyan })
h("@keyword.return", { fg = c.accent })
h("@punctuation", { fg = c.dim })
h("@tag", { fg = c.accent2 })
h("@tag.attribute", { fg = c.gold })
h("@markup.heading", { fg = c.accent, bold = true })
h("@markup.link", { fg = c.blue, underline = true })
local ansi = { $(jq -r '[.ansi[] | "\"" + . + "\""] | join(", ")' "$t") }
for i, v in ipairs(ansi) do vim.g["terminal_color_" .. (i - 1)] = v end
EON
  mv "$nv/sumi.lua.tmp" "$nv/sumi.lua"
  if command -v nvim >/dev/null 2>&1; then
    for s in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/nvim.*.0 "${XDG_RUNTIME_DIR:-/tmp}"/nvim*/0; do
      [ -S "$s" ] || continue
      timeout 2 nvim --server "$s" --remote-expr 'execute("if get(g:, \"colors_name\", \"\") ==# \"sumi\" | colorscheme sumi | endif")' >/dev/null 2>&1 || true
    done
  fi
fi

# ---- apps: GTK colours (read by gtk.css of GTK 3 and 4, see sumi-shell.nix) ----
{
  echo "/* written by sumi-theme ($name) */"
  for pair in "accent_color accent" "accent_bg_color accent" "accent_fg_color onAccent" \
              "window_bg_color bg" "window_fg_color fg" "view_bg_color bg" "view_fg_color fg" \
              "headerbar_bg_color bg1" "headerbar_fg_color fg" "headerbar_border_color line" "headerbar_backdrop_color bg" \
              "sidebar_bg_color bg1" "sidebar_fg_color fg" "sidebar_backdrop_color bg1" "secondary_sidebar_bg_color bg1" \
              "card_bg_color bg1" "card_fg_color fg" "dialog_bg_color bg1" "dialog_fg_color fg" \
              "popover_bg_color bg1" "popover_fg_color fg" "thumbnail_bg_color bg1" "thumbnail_fg_color fg" \
              "destructive_bg_color error" "destructive_color error" "error_color error" "warning_color warn" "success_color ok"; do
    set -- $pair
    echo "@define-color $1 $(get "$2");"
  done
} > "$CONF/gtk.css.tmp"
mv "$CONF/gtk.css.tmp" "$CONF/gtk.css"

# ---- apps: KDE colour scheme in kdeglobals (Dolphin, Kate, Okular and every other Qt/KDE app) ----
# only the colour sections are replaced, everything else in kdeglobals stays as it is
rgb() {
  case "$1" in selbg) echo "$selbg"; return ;; esac
  h=$(get "$1" | tr -d '#'); printf '%d,%d,%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}
# selection: the accent sunk into the background, so light text stays readable on every accent,
# whether the window is focused or not
selbg=$(awk -v a="$(rgb accent)" -v b="$(rgb bg1)" 'BEGIN { split(a, x, ","); split(b, y, ","); t = 0.42
  printf "%d,%d,%d", y[1] + (x[1] - y[1]) * t, y[2] + (x[2] - y[2]) * t, y[3] + (x[3] - y[3]) * t }')
kgroup() {   # section, normal background, alternate background, normal text [, all text]
  local all="${5:-}"
  cat <<EOK
[Colors:$1]
BackgroundNormal=$(rgb "$2")
BackgroundAlternate=$(rgb "$3")
ForegroundNormal=$(rgb "$4")
ForegroundInactive=$(rgb "${all:-dim}")
ForegroundActive=$(rgb "${all:-hi}")
ForegroundLink=$(rgb blue)
ForegroundVisited=$(rgb violet)
ForegroundNegative=$(rgb error)
ForegroundNeutral=$(rgb warn)
ForegroundPositive=$(rgb ok)
DecorationFocus=$(rgb accent)
DecorationHover=$(rgb accent2)

EOK
}
kg="$HOME/.config/kdeglobals"
{
  if [ -f "$kg" ]; then
    awk '/^\[/ { skip = ($0 ~ /^\[(Colors:|WM\]|ColorEffects:)/); if (!skip && n++) print "" } !skip && NF' "$kg"
    echo
  else
    printf '[General]\nColorScheme=Sumi\n\n[Icons]\nTheme=Papirus-Dark\n\n'
  fi
  kgroup View bg bg1 fg
  kgroup Window bg1 bg2 fg
  kgroup Button bg2 line fg
  kgroup Selection selbg selbg hi hi
  kgroup Tooltip bg2 bg1 fg
  kgroup Complementary bg bg1 fg
  kgroup Header bg1 bg fg
  cat <<EOK
[Colors:Header][Inactive]
BackgroundNormal=$(rgb bg)
BackgroundAlternate=$(rgb bg)
ForegroundNormal=$(rgb dim)

[ColorEffects:Inactive]
Enable=false

[ColorEffects:Disabled]
ColorAmount=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[WM]
activeBackground=$(rgb bg1)
activeForeground=$(rgb fg)
activeBlend=$(rgb accent)
inactiveBackground=$(rgb bg)
inactiveForeground=$(rgb dim)
inactiveBlend=$(rgb line)
EOK
} > "$kg.tmp"
mv "$kg.tmp" "$kg"

# lock screen layout of the theme
lock="$SHELL_DIR/locks/$name.conf"; [ -f "$lock" ] || lock="$SHELL_DIR/locks/yoru.conf"
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
  logo="$SHELL_DIR/assets/$(get logo)"; [ -f "$logo" ] || logo="$SHELL_DIR/assets/logo-yoru.svg"
  cp "$logo" "$L/logo.svg.tmp" 2>/dev/null && mv "$L/logo.svg.tmp" "$L/logo.svg"
  case "$name" in tsuki) rad=8 ;; yoru|koyo) rad=16 ;; *) rad=24 ;; esac
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
# running Qt/KDE apps reload their colours when they get this signal
if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  dbus-send --session --type=signal /KGlobalSettings org.kde.KGlobalSettings.notifyChange int32:0 int32:0 2>/dev/null || true
fi
exit 0
