#!/usr/bin/env bash
# Builds the home-manager module, then runs the shell, lock screen and login screen
# headless under sway and takes screenshots. Everything ends up in out/.
set -u
cd "$(dirname "$0")/.."
OUT=$PWD/out; mkdir -p $OUT
log() { echo "== $*" | tee -a $OUT/summary.txt; }
B() { nix build --no-link --print-out-paths "./ci#$1^out" 2>>$OUT/build.log | head -1; }

log "kernel default: $(nix eval --raw ./ci#kernel-default.version 2>>$OUT/build.log)"
for k in linuwu-default linuwu-latest; do
  if P=$(nix build --no-link --print-out-paths ./ci#$k 2>>$OUT/build-$k.log); then log "$k OK: $(find $P -name '*.ko*' | head -1)"; modinfo $(find $P -name '*.ko*' | head -1) 2>/dev/null | grep -E "^(vermagic|alias)" | head -3 | tee -a $OUT/summary.txt
  else log "$k FAILED"; tail -40 $OUT/build-$k.log | tee -a $OUT/summary.txt; fi
done
if D=$(nix eval --raw ./ci#nixosConfigurations.test.config.system.build.toplevel.drvPath 2>>$OUT/build.log); then log "nixos eval OK"; else log "nixos eval FAILED"; tail -30 $OUT/build.log | tee -a $OUT/summary.txt; fi
nix eval --json ./ci#nixosConfigurations.test.config.boot.blacklistedKernelModules 2>/dev/null | tee -a $OUT/summary.txt
log "build home-manager config"
if ! HM=$(nix build --no-link --print-out-paths ./ci#homeConfigurations.test.activationPackage 2>>$OUT/build.log); then
  log "HM BUILD FAILED"; tail -60 $OUT/build.log | tee -a $OUT/summary.txt; exit 1
fi
log "hm: $HM"
ls $HM/home-path/bin | grep -i helium | xargs -I{} echo "helium bin: {}" | tee -a $OUT/summary.txt
grep -h "^Exec\|^Icon" $HM/home-path/share/applications/helium.desktop | tee -a $OUT/summary.txt
(timeout 20 $HM/home-path/bin/helium --version > $OUT/helium-version.txt 2>&1; echo "helium rc=$?" >> $OUT/helium-version.txt)
HF=$HM/home-files
cp -L $HF/.config/hypr/hyprland.conf $OUT/hyprland.conf 2>/dev/null
cp -L $HF/.config/hypr/hyprlock.conf $OUT/hyprlock.conf 2>/dev/null
cp -L $HF/.config/kitty/kitty.conf $OUT/kitty.conf 2>/dev/null
ls -la $HF/.config/ > $OUT/config-ls.txt 2>&1
ls $HM/home-path/bin > $OUT/bin-ls.txt 2>&1
grep -c "old-bind-should-be-gone" $OUT/hyprland.conf | xargs -I{} echo "old bind count (want 0): {}" | tee -a $OUT/summary.txt
grep -c "waybar" $OUT/hyprland.conf | xargs -I{} echo "waybar mentions (want 0): {}" | tee -a $OUT/summary.txt
[ -e $HF/.config/waybar ] && log "waybar config still present (bad)" || log "waybar config gone (good)"
[ -e $HF/.config/mako ] && log "mako config still present (bad)" || log "mako config gone (good)"

QS=$(B quickshell)/bin/qs; SWAY=$(B sway)/bin/sway; GRIM=$(B grim)/bin/grim
MESA=$(B mesa); GLVND=$(B libglvnd); FONTS=$(B fonts); PAP=$(B papirus-icon-theme)
KITTY=$(B kitty); PAVU=$(B pavucontrol); BTOP=$(B btop)
mkdir -p ~/.local/share/fonts && cp -rL $FONTS/share/fonts/* ~/.local/share/fonts/ 2>/dev/null; fc-cache -f >/dev/null 2>&1
fc-list | grep -ci "jetbrainsmono nerd" | xargs -I{} echo "jetbrains fonts: {}" | tee -a $OUT/summary.txt

export PATH=$HM/home-path/bin:$PATH
export XDG_DATA_DIRS=$PAP/share:$KITTY/share:$PAVU/share:$BTOP/share:$HM/home-path/share
export XDG_RUNTIME_DIR=/tmp/xdg; rm -rf $XDG_RUNTIME_DIR; mkdir -p $XDG_RUNTIME_DIR; chmod 700 $XDG_RUNTIME_DIR
export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1
export __EGL_VENDOR_LIBRARY_FILENAMES=$MESA/share/glvnd/egl_vendor.d/50_mesa.json
export LIBGL_DRIVERS_PATH=$MESA/lib/dri GBM_BACKENDS_PATH=$MESA/lib/gbm LD_LIBRARY_PATH=$GLVND/lib LIBGL_ALWAYS_SOFTWARE=1

printf 'output HEADLESS-1 resolution 2560x1600 scale 1.6\noutput * bg #0f0f14 solid_color\ndefault_border none\n' > /tmp/sway.conf
$SWAY -c /tmp/sway.conf > $OUT/sway.log 2>&1 &
sleep 3
export WAYLAND_DISPLAY=$(ls $XDG_RUNTIME_DIR | grep -E '^wayland-[0-9]+$' | head -1)
log "wayland display: $WAYLAND_DISPLAY"

# theme files like the activation script does
export SUMI_SHELL_DIR=$HF/.config/quickshell/sumi
sumi-theme --init; log "sumi-theme --init rc=$?"
ls -la ~/.config/sumi >> $OUT/summary.txt
SHELLDIR=$(readlink -f $HF/.config/quickshell/sumi)

# wallpaper behind everything
swaybg -i $SHELLDIR/assets/walls/wall-sumi.jpg -m fill >/dev/null 2>&1 &
sleep 1

run_qs() {   # name, extra env...
  local name=$1; shift
  [ -n "${QPID:-}" ] && kill $QPID 2>/dev/null; sleep 0.8
  env "$@" $QS -p $SHELLDIR > $OUT/qs-$name.log 2>&1 &
  QPID=$!
  sleep ${WAIT:-5}
  $GRIM $OUT/shot-$name.png
}

# pick a renderer: try GL first, fall back to Qt's software renderer
run_qs probe SUMI_DEMO=1
if grep -q "Failed to create RHI\|Failed to initialize graphics\|failed to create graphics" $OUT/qs-probe.log; then
  export QT_QUICK_BACKEND=software; log "renderer: software"
else log "renderer: GL"; fi
run_qs probe2 SUMI_DEMO=1

run_qs bar SUMI_DEMO=1
run_qs launcher SUMI_DEMO=1 SUMI_OPEN=launcher SUMI_DEMO_QUERY=
run_qs launcher-q SUMI_DEMO=1 SUMI_OPEN=launcher SUMI_DEMO_QUERY=s
run_qs network SUMI_DEMO=1 SUMI_OPEN=network
run_qs agents SUMI_DEMO=1 SUMI_OPEN=agents
run_qs power SUMI_DEMO=1 SUMI_OPEN=power
run_qs themes SUMI_DEMO=1 SUMI_OPEN=themes
run_qs polkit SUMI_DEMO=1 SUMI_DEMO_POLKIT=1
run_qs osd SUMI_DEMO=1 SUMI_DEMO_OSD=1 SUMI_DEMO_NOTIFS=1
run_qs predator SUMI_DEMO=1 SUMI_OPEN=predator

# real mode: no demo data, services missing on the runner must not break anything
run_qs real
$QS ipc -p $SHELLDIR call shell toggle launcher > $OUT/ipc.log 2>&1; sleep 1.5; $GRIM $OUT/shot-real-ipc-launcher.png
$QS ipc -p $SHELLDIR call shell toggle launcher >> $OUT/ipc.log 2>&1
$QS ipc -p $SHELLDIR call shell toggle themes >> $OUT/ipc.log 2>&1; sleep 2; $GRIM $OUT/shot-real-themes.png
$QS ipc -p $SHELLDIR call shell close >> $OUT/ipc.log 2>&1
$QS ipc -p $SHELLDIR call shell toggle predator >> $OUT/ipc.log 2>&1; sleep 2; $GRIM $OUT/shot-real-predator.png
$QS ipc -p $SHELLDIR call shell close >> $OUT/ipc.log 2>&1
$QS ipc -p $SHELLDIR call osd brightness >> $OUT/ipc.log 2>&1
$QS ipc -p $SHELLDIR show >> $OUT/ipc.log 2>&1
sleep 1; kill $QPID 2>/dev/null; QPID=

log "qs warnings/errors:"
for f in $OUT/qs-*.log; do echo "--- $(basename $f)"; grep -E "WARN|ERROR|FATAL|TypeError|ReferenceError|is not defined|Cannot|Unable|failed" $f | grep -v "Failed to create wl_display" | head -40; done >> $OUT/summary.txt

# theme switch end to end
sumi-theme washi > $OUT/theme-switch.log 2>&1; log "sumi-theme washi rc=$?"
head -3 ~/.config/sumi/kitty.conf >> $OUT/summary.txt
WAIT=4 run_qs washi SUMI_DEMO=1 SUMI_OPEN=agents
sumi-theme sumi >/dev/null 2>&1
kill $QPID 2>/dev/null; QPID=

# login screen
SDDM=$(B sddm)
ls $SDDM/bin > $OUT/sddm-bin.txt
GREETER=$(ls $SDDM/bin | grep -E '^sddm-greeter(-qt6)?$' | tail -1)
(timeout 15 env QML_DISABLE_DISK_CACHE=1 QT_QPA_PLATFORM=wayland $SDDM/bin/$GREETER --test-mode --theme $PWD/sddm-sumi > $OUT/sddm.log 2>&1 &)
sleep 9; $GRIM $OUT/shot-sddm.png
sleep 7
# real notifications over a private D-Bus session
NS=$(B libnotify)/bin/notify-send; DBR=$(B dbus)/bin/dbus-run-session
$DBR -- bash -c "
  env $QS -p $SHELLDIR > $OUT/qs-notif.log 2>&1 & Q=\$!
  sleep 4
  $NS -a Discord 'Jonas' 'kommst du heute noch online? cs2 um 8'
  $NS -a 'claude' -A ok=Switch -A later=Later 'Waiting for your input' 'Build finished.' &
  $NS -u critical -a power 'Battery low' '7% left, plug in soon'
  sleep 2; $GRIM $OUT/shot-notif-real.png
  kill \$Q
"

# lock screen
HL=$(B hyprlock)/bin/hyprlock
(timeout 12 $HL -c $HF/.config/hypr/hyprlock.conf --immediate-render > $OUT/hyprlock.log 2>&1 &)
sleep 6; $GRIM $OUT/shot-hyprlock.png 2>>$OUT/hyprlock.log
sleep 7

log "done"
