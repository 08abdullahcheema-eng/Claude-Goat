#!/usr/bin/env bash
# Builds the home-manager module, then runs the shell, lock screen and login screen
# headless under sway and takes screenshots. Everything ends up in out/.
set -u
cd "$(dirname "$0")/.."
OUT=$PWD/out; mkdir -p $OUT
log() { echo "== $*" | tee -a $OUT/summary.txt; }
B() { nix build --no-link --print-out-paths "./ci#$1^out" 2>>$OUT/build.log | head -1; }

# a commit with [grub] in its title only tests the boot menu (fast)
GRUB_ONLY=$(git log -1 --format=%s 2>/dev/null | grep -q '\[grub\]' && echo 1)
log "kernel default: $(nix eval --raw ./ci#kernel-default.version 2>>$OUT/build.log)"
for k in $([ -n "$GRUB_ONLY" ] || echo linuwu-default linuwu-latest); do
  if P=$(nix build --no-link --print-out-paths ./ci#$k 2>>$OUT/build-$k.log); then log "$k OK: $(find $P -name '*.ko*' | head -1)"; modinfo $(find $P -name '*.ko*' | head -1) 2>/dev/null | grep -E "^(vermagic|alias)" | head -3 | tee -a $OUT/summary.txt
  else log "$k FAILED"; tail -40 $OUT/build-$k.log | tee -a $OUT/summary.txt; fi
done
if D=$(nix eval --raw ./ci#nixosConfigurations.test.config.system.build.toplevel.drvPath 2>$OUT/nixos-eval.log); then log "nixos eval OK"; else log "nixos eval FAILED"; tail -30 $OUT/nixos-eval.log | tee -a $OUT/summary.txt; fi
grep -i "warning" $OUT/nixos-eval.log | sort -u | head -20 | tee -a $OUT/summary.txt
echo "grub useOSProber = $(nix eval --json ./ci#nixosConfigurations.test.config.boot.loader.grub.useOSProber 2>&1 | tail -1)" | tee -a $OUT/summary.txt
nix eval --raw ./ci#nixosConfigurations.test.config.boot.loader.grub.extraEntries 2>&1 | tee -a $OUT/summary.txt
# build the parts that are new and could fail to build (nvidia driver, steam, nix-ld env)
for a in config.hardware.nvidia.package config.programs.nix-ld.package config.system.path; do
  if nix build --no-link ./ci#nixosConfigurations.test.$a 2>$OUT/build-sys.log; then log "build $a OK"; else log "build $a FAILED"; tail -25 $OUT/build-sys.log | tee -a $OUT/summary.txt; fi
done
nix eval --json ./ci#nixosConfigurations.test.config.hardware.bluetooth.enable 2>/dev/null | xargs -I{} echo "bluetooth enabled: {}" | tee -a $OUT/summary.txt
nix eval --raw ./ci#nixosConfigurations.test.config.boot.extraModprobeConfig 2>/dev/null | tee -a $OUT/summary.txt
nix eval --raw ./ci#nixosConfigurations.test.config.environment.etc.\"bluetooth/main.conf\".source 2>/dev/null | xargs cat 2>/dev/null | tee -a $OUT/summary.txt
for o in hardware.nvidia.prime.offload.enable programs.steam.enable programs.nix-ld.enable services.flatpak.enable services.power-profiles-daemon.enable zramSwap.enable time.hardwareClockInLocalTime nix.gc.automatic; do echo "$o = $(nix eval --json ./ci#nixosConfigurations.test.config.$o 2>&1 | tail -1)" | tee -a $OUT/summary.txt; done
nix eval --json ./ci#nixosConfigurations.test.config.services.blueman.enable 2>/dev/null | xargs -I{} echo "blueman enabled: {}" | tee -a $OUT/summary.txt
nix eval --json ./ci#nixosConfigurations.test.config.boot.blacklistedKernelModules 2>/dev/null | tee -a $OUT/summary.txt
# boot menu: build the GRUB themes, boot each one in QEMU from a small ISO and take a screenshot
if SG=$(nix build --no-link --print-out-paths ./ci#nixosConfigurations.test.config.system.build.sumiGrub 2>$OUT/grub-build.log); then
  log "grub themes OK: $(ls $SG | tr '\n' ' ')"; grep -- "->" $OUT/grub-build.log | head -20 >> $OUT/summary.txt
  nix log ./ci#nixosConfigurations.test.config.system.build.sumiGrub 2>/dev/null | grep -- "->" | head -20 >> $OUT/summary.txt
  GRUB=$(B grub2); XO=$(B xorriso); MT=$(B mtools); QEMU=$(B qemu); SOCAT=$(B socat); IM=$(B imagemagick)
  for t in sumi iso kiri hagane summit; do
    rm -rf /tmp/giso; mkdir -p /tmp/giso/boot/grub; cp -rL $SG /tmp/giso/boot/grub/theme; chmod -R u+w /tmp/giso
    {
      echo 'insmod all_video'; echo 'insmod gfxterm'; echo 'insmod png'; echo 'insmod jpeg'
      echo 'set gfxmode=1920x1200,auto'; echo 'terminal_output gfxterm'
      (cd /tmp/giso/boot/grub/theme && find . -name '*.pf2' | sed 's|^\./|loadfont /boot/grub/theme/|')
      echo 'set theme=/boot/grub/theme/theme.txt'; echo 'export theme'; echo "set sumi_theme=$t"
      cat sumi/grub/select.cfg
      echo 'set timeout=60'
      echo 'menuentry "NixOS" --class nixos { true }'; echo 'menuentry "Windows" --class windows { true }'
      echo 'submenu "NixOS - All configurations" --class submenu { menuentry "NixOS - Configuration 42" { true } }'
    } > /tmp/giso/boot/grub/grub.cfg
    PATH=$XO/bin:$MT/bin:$PATH $GRUB/bin/grub-mkrescue -o /tmp/g.iso /tmp/giso >> $OUT/grub-iso.log 2>&1
    rm -f /tmp/qmon
    $QEMU/bin/qemu-system-x86_64 -cdrom /tmp/g.iso -m 512 -display none -vga std -global VGA.vgamem_mb=64 -monitor unix:/tmp/qmon,server,nowait >> $OUT/grub-qemu.log 2>&1 &
    QEP=$!
    sleep 25
    echo "screendump /tmp/g.ppm" | $SOCAT/bin/socat - UNIX-CONNECT:/tmp/qmon >> $OUT/grub-qemu.log 2>&1; sleep 2
    kill $QEP 2>/dev/null; wait $QEP 2>/dev/null
    $IM/bin/magick /tmp/g.ppm $OUT/shot-grub-$t.png 2>>$OUT/grub-qemu.log && log "grub $t: $($IM/bin/magick identify -format '%wx%h' $OUT/shot-grub-$t.png)"
  done
else log "grub themes FAILED"; tail -30 $OUT/grub-build.log | tee -a $OUT/summary.txt; fi
[ -n "$GRUB_ONLY" ] && { log "done (grub only)"; exit 0; }

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
HYPR=$(B hyprland)
$HYPR/bin/Hyprland --version 2>&1 | head -2 | tee -a $OUT/summary.txt
grep -c "old-bind-should-be-gone" $OUT/hyprland.conf | xargs -I{} echo "old bind count (want 0): {}" | tee -a $OUT/summary.txt
grep -c "waybar" $OUT/hyprland.conf | xargs -I{} echo "waybar mentions (want 0): {}" | tee -a $OUT/summary.txt
[ -e $HF/.config/waybar ] && log "waybar config still present (bad)" || log "waybar config gone (good)"
[ -e $HF/.config/mako ] && log "mako config still present (bad)" || log "mako config gone (good)"

QS=$(B quickshell)/bin/qs; SWAY=$(B sway)/bin/sway; GRIM=$(B grim)/bin/grim
MESA=$(B mesa); GLVND=$(B libglvnd); FONTS=$(B fonts); PAP=$(B papirus-icon-theme)
KITTY=$(B kitty); PAVU=$(B pavucontrol); BTOP=$(B btop)
mkdir -p ~/.local/share/fonts && cp -rL $FONTS/share/fonts/* ~/.local/share/fonts/ 2>/dev/null
chmod -R u+w ~/.local/share/fonts; cp -rL $HM/home-path/share/fonts/. ~/.local/share/fonts/hm/ 2>>$OUT/fontcopy.log || { mkdir -p ~/.local/share/fonts/hm; cp -rL $HM/home-path/share/fonts/. ~/.local/share/fonts/hm/; }; fc-cache -f >/dev/null 2>&1
fc-list : family | grep -E "Shippori|Bebas|Space Grotesk|^Inter" | sort -u | tee -a $OUT/summary.txt
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
for t in iso kiri hagane summit sumi; do
  sumi-theme $t >/dev/null 2>&1
  WAIT=4 run_qs themes-$t SUMI_DEMO=1 SUMI_OPEN=themes
  WAIT=4 run_qs bar-$t SUMI_DEMO=1
  # motion check: open the calendar under its icon, grab frames while it moves in, close it, grab again
  $QS ipc -p $SHELLDIR call shell toggleAt calendar 800 >> $OUT/qs-anim.log 2>&1
  for i in 1 2 3; do $GRIM -s 0.5 $OUT/anim-$t-in$i.png; done
  sleep 1.2; $GRIM -s 0.5 $OUT/anim-$t-open.png
  $QS ipc -p $SHELLDIR call shell close >> $OUT/qs-anim.log 2>&1
  for i in 1 2; do $GRIM -s 0.5 $OUT/anim-$t-out$i.png; done
  sleep 0.8; $GRIM -s 0.5 $OUT/anim-$t-closed.png
  # the theme's animations must be valid Hyprland config
  echo "== verify $t" >> $OUT/verify-themes.log
  (cd /tmp && timeout 60 $HYPR/bin/Hyprland --verify-config -c $OUT/hyprland.conf 2>&1 | grep -v "^$" | tail -4) >> $OUT/verify-themes.log
done
grep -A4 "== verify" $OUT/verify-themes.log | grep -E "== verify|config ok|rror" | tee -a $OUT/summary.txt
# every bar layout with the sumi theme, and a panel above a bottom bar
for l in islands capsule rail side ridge notch pill bottom corners; do WAIT=4 run_qs layout-$l SUMI_DEMO=1 SUMI_LAYOUT=$l; done
WAIT=4 run_qs pill-audio SUMI_DEMO=1 SUMI_LAYOUT=pill SUMI_OPEN=audio
WAIT=4 run_qs bottom-calendar SUMI_DEMO=1 SUMI_LAYOUT=bottom SUMI_OPEN=calendar
WAIT=4 run_qs rail-system SUMI_DEMO=1 SUMI_LAYOUT=rail SUMI_OPEN=system
WAIT=4 run_qs side-audio SUMI_DEMO=1 SUMI_LAYOUT=side SUMI_OPEN=audio
WAIT=4 run_qs ridge-calendar SUMI_DEMO=1 SUMI_LAYOUT=ridge SUMI_OPEN=calendar
run_qs calendar SUMI_DEMO=1 SUMI_OPEN=calendar
run_qs system SUMI_DEMO=1 SUMI_OPEN=system
run_qs battery SUMI_DEMO=1 SUMI_OPEN=battery
run_qs bluetooth SUMI_DEMO=1 SUMI_OPEN=bluetooth
run_qs audio SUMI_DEMO=1 SUMI_OPEN=audio
run_qs polkit SUMI_DEMO=1 SUMI_DEMO_POLKIT=1
run_qs osd SUMI_DEMO=1 SUMI_DEMO_OSD=1 SUMI_DEMO_NOTIFS=1
run_qs predator SUMI_DEMO=1 SUMI_OPEN=predator
# panels drop down under the icon that opened them
run_qs anchor SUMI_DEMO=1
$QS ipc -p $SHELLDIR call shell toggleAt system 328 >> $OUT/qs-anchor.log 2>&1; sleep 1.5; $GRIM $OUT/shot-anchor-system.png
$QS ipc -p $SHELLDIR call shell toggleAt predator 252 >> $OUT/qs-anchor.log 2>&1; sleep 1.5; $GRIM $OUT/shot-anchor-predator.png
$QS ipc -p $SHELLDIR call shell toggleAt battery 1500 >> $OUT/qs-anchor.log 2>&1; sleep 1.5; $GRIM $OUT/shot-anchor-battery.png
$QS ipc -p $SHELLDIR call shell toggleAt battery 1500 >> $OUT/qs-anchor.log 2>&1; sleep 1.5; $GRIM $OUT/shot-anchor-closed.png


# real mode: no demo data, services missing on the runner must not break anything
run_qs real
$QS ipc -p $SHELLDIR call shell toggle launcher > $OUT/ipc.log 2>&1; sleep 1.5; $GRIM $OUT/shot-real-ipc-launcher.png
$QS ipc -p $SHELLDIR call shell toggle launcher >> $OUT/ipc.log 2>&1
$QS ipc -p $SHELLDIR call shell toggle themes >> $OUT/ipc.log 2>&1; sleep 2; $GRIM $OUT/shot-real-themes.png
$QS ipc -p $SHELLDIR call shell close >> $OUT/ipc.log 2>&1
$QS ipc -p $SHELLDIR call shell toggle predator >> $OUT/ipc.log 2>&1; sleep 2; $GRIM $OUT/shot-real-predator.png
$QS ipc -p $SHELLDIR call shell close >> $OUT/ipc.log 2>&1
$QS ipc -p $SHELLDIR call shell toggle bluetooth >> $OUT/ipc.log 2>&1; sleep 2; $GRIM $OUT/shot-real-bluetooth.png
$QS ipc -p $SHELLDIR call shell toggle audio >> $OUT/ipc.log 2>&1; sleep 2; $GRIM $OUT/shot-real-audio.png
$QS ipc -p $SHELLDIR call shell close >> $OUT/ipc.log 2>&1
$QS ipc -p $SHELLDIR call osd brightness >> $OUT/ipc.log 2>&1
$QS ipc -p $SHELLDIR show >> $OUT/ipc.log 2>&1
sleep 1; kill $QPID 2>/dev/null; QPID=

log "qs warnings/errors:"
for f in $OUT/qs-*.log; do echo "--- $(basename $f)"; grep -E "WARN|ERROR|FATAL|TypeError|ReferenceError|is not defined|Cannot|Unable|failed" $f | grep -v "Failed to create wl_display" | head -40; done >> $OUT/summary.txt

# theme switch end to end
sumi-theme iso wall-iso-2.jpg pill > $OUT/theme-switch.log 2>&1; log "sumi-theme iso rc=$? layout=$(cat ~/.config/sumi/layout 2>/dev/null) wall=$(cat ~/.config/sumi/wall 2>/dev/null)"
sumi-theme --layout auto; log "layout after auto: $(cat ~/.config/sumi/layout 2>/dev/null || echo none)"
head -3 ~/.config/sumi/kitty.conf >> $OUT/summary.txt
WAIT=4 run_qs iso-agents SUMI_DEMO=1 SUMI_OPEN=agents
sumi-theme sumi >/dev/null 2>&1
kill $QPID 2>/dev/null; QPID=

# login screen
SDDM=$(B sddm)
ls $SDDM/bin > $OUT/sddm-bin.txt
GREETER=$(ls $SDDM/bin | grep -E '^sddm-greeter(-qt6)?$' | tail -1)
# login screen of every theme: sumi-theme writes the palette, the greeter reads it
export SUMI_LOGIN_DIR=/tmp/sumi-login; mkdir -p $SUMI_LOGIN_DIR
rm -rf /tmp/sddm-test; cp -r $PWD/sddm-sumi /tmp/sddm-test; chmod -R u+w /tmp/sddm-test
printf '[General]\nstateDir=/tmp/sumi-login\n' > /tmp/sddm-test/theme.conf
QTSVG=$(B qtsvg)
for t in sumi iso kiri hagane summit; do
  sumi-theme $t >/dev/null 2>&1
  [ $t = sumi ] && cat $SUMI_LOGIN_DIR/palette.qml >> $OUT/summary.txt
  (timeout 14 env QML_DISABLE_DISK_CACHE=1 QT_FORCE_STDERR_LOGGING=1 QT_QPA_PLATFORM=wayland QT_PLUGIN_PATH=$QTSVG/lib/qt-6/plugins $SDDM/bin/$GREETER --test-mode --theme /tmp/sddm-test > $OUT/sddm-$t.log 2>&1; echo "greeter rc=$? after ${SECONDS}s" >> $OUT/sddm-$t.log) &
  echo "greeter $t started at ${SECONDS}s" >> $OUT/sddm-$t.log
  sleep 2.2; $GRIM $OUT/shot-sddm-$t-intro1.png
  sleep 0.6; $GRIM $OUT/shot-sddm-$t-intro2.png
  sleep 6.2; $GRIM $OUT/shot-sddm-$t.png
  sleep 2.5; $GRIM $OUT/shot-sddm-$t-b.png
  sleep 3.5
done
grep -hiE "error|warn|cannot|unable" $OUT/sddm-*.log | sort | uniq -c | head -20 >> $OUT/summary.txt
grep -h "greeter" $OUT/sddm-*.log >> $OUT/summary.txt
unset SUMI_LOGIN_DIR
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

# lock screen of every theme
HL=$(B hyprlock)/bin/hyprlock
for t in sumi iso kiri hagane summit; do
  sumi-theme $t >/dev/null 2>&1
  (timeout 9 $HL -c $HF/.config/hypr/hyprlock.conf --immediate-render > $OUT/hyprlock-$t.log 2>&1 &)
  sleep 5; $GRIM $OUT/shot-lock-$t.png 2>>$OUT/hyprlock-$t.log
  sleep 1.3; $GRIM -s 0.5 $OUT/shot-lock-$t-b.png 2>>$OUT/hyprlock-$t.log
  sleep 3.7
done
sumi-theme sumi >/dev/null 2>&1
log "hyprlock config problems:"
grep -hiE "error|unknown|invalid|no such" $OUT/hyprlock-*.log | sort | uniq -c | head -20 >> $OUT/summary.txt
log "lockinfo samples:"
for m in "clock #c8323a" tick "wave 32" stars "breath x 6000" nextwall; do echo "$m -> $(sumi-lockinfo $m)" >> $OUT/summary.txt; done

log "done"
