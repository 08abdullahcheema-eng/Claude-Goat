# Sumi login screen (SDDM). The greeter follows the theme you pick in the theme picker:
# sumi-theme writes wallpaper, logo and colours to /var/lib/sumi, the login screen reads them.
{ config, lib, pkgs, ... }:
let
  user = "larp";
  sumi-sddm = pkgs.stdenvNoCC.mkDerivation {
    pname = "sddm-theme-sumi";
    version = "2.0";
    src = ./sddm-sumi;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/sumi
      cp -r ./* $out/share/sddm/themes/sumi/
    '';
  };

  # ---- boot menu (GRUB): one theme per desktop theme, sumi-theme picks which one shows ----
  fontSrc = pkgs.google-fonts.override { fonts = [ "ShipporiMincho" "SpaceGrotesk" ]; };
  # grub-mkfont only takes FROM-TO pairs, so single characters are written as X-X
  latin = "0x20-0x7E,0xA0-0x17F,0x2013-0x2014,0x2022-0x2022,0x2190-0x2193";
  kanji = "0x58A8-0x58A8,0x78EF-0x78EF,0x9727-0x9727,0x92FC-0x92FC,0x5CF0-0x5CF0";      # 墨 磯 霧 鋼 峰
  sumi-grub = pkgs.runCommand "sumi-grub-themes" { nativeBuildInputs = [ pkgs.grub2 pkgs.python3 pkgs.findutils pkgs.librsvg ]; } ''
    cp -r ${./sumi/grub} $out; chmod -R u+w $out; mkdir -p $out/fonts
    pick() { f=$(find "$1" -iname "$2" | sort | head -1); [ -n "$f" ] || { echo "font $2 not found in $1" >&2; exit 1; }; echo "$f"; }
    mk() { grub-mkfont -s "$3" -r "$4" -o "$out/fonts/$1.pf2" ''${5:+-n "$5"} "$2"; }
    shx=$(pick ${fontSrc} 'ShipporiMincho-ExtraBold.ttf')
    shr=$(pick ${fontSrc} 'ShipporiMincho-Regular.ttf')
    gro=$(pick ${fontSrc} 'SpaceGrotesk*.ttf')
    int=$(pick ${pkgs.inter} 'InterVariable.ttf' 2>/dev/null || pick ${pkgs.inter} 'Inter*.tt[fc]')
    jbm=$(pick ${pkgs.nerd-fonts.jetbrains-mono} 'JetBrainsMonoNerdFont-Regular.ttf')
    # sizes for the 1920x1200 the laptop's firmware offers in GRUB
    mk kanji-90 "$shx" 90 "${kanji}"
    mk kanji-36 "$shx" 36 "${kanji}"
    mk shippori-xb-45 "$shx" 45 "${latin}" "Shippori Mincho XB"   # own name, else it clashes with the regular cut
    mk shippori-45 "$shr" 45 "${latin}"
    mk grotesk-45 "$gro" 45 "${latin}"
    mk grotesk-22 "$gro" 22 "${latin}"
    mk grotesk-20 "$gro" 20 "${latin}"
    mk grotesk-15 "$gro" 15 "${latin}"
    mk inter-22 "$int" 22 "${latin}"
    mk inter-20 "$int" 20 "${latin}"
    mk inter-15 "$int" 15 "${latin}"
    mk jbmono-22 "$jbm" 22 "${latin}"
    mk jbmono-15 "$jbm" 15 "${latin}"

    # the theme's own logo is the icon of the NixOS entries
    for t in sumi iso kiri hagane summit; do
      mkdir -p $out/$t/icons
      rsvg-convert -w 64 -h 64 ${./sumi/shell/assets}/logo-$t.svg -o $out/$t/icons/nixos.png
    done
    python3 $out/render.py $out
    rm $out/render.py $out/select.cfg
  '';
in
{
  boot.loader.grub = {
    theme = lib.mkDefault sumi-grub;
    # the firmware only offers 1920x1200 in GRUB, the themes are drawn for exactly that
    gfxmodeEfi = lib.mkDefault "1920x1200,auto";
    gfxmodeBios = lib.mkDefault "1920x1200,auto";
    # GRUB paints its hidden text console with the splash image; the Sumi picture keeps it from showing as a black box
    splashImage = "${sumi-grub}/sumi/background.jpg";
    splashMode = lib.mkDefault "normal";
    extraConfig = builtins.readFile ./sumi/grub/select.cfg;
    # menu order: NixOS (default), Windows, then "NixOS - All configurations".
    # NixOS writes extraEntries between its default entry and the generations submenu,
    # so Windows gets its own entry here instead of the os-prober one (which lands last).
    useOSProber = lib.mkForce false;
    extraEntries = ''
      menuentry "Windows" --class windows --class os {
        insmod part_gpt
        insmod fat
        insmod chain
        search --no-floppy --file --set=root /EFI/Microsoft/Boot/bootmgfw.efi
        chainloader /EFI/Microsoft/Boot/bootmgfw.efi
      }
    '';
  };
  system.build.sumiGrub = sumi-grub;

  # sumi-theme writes the palette for the login screen; when it changes, store the theme's
  # name in grubenv so the next boot menu uses the same theme
  systemd.services.sumi-grub-sync = {
    description = "Boot menu follows the Sumi theme";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.grub2 pkgs.coreutils pkgs.gnused ];
    serviceConfig.Type = "oneshot";
    script = ''
      f=/var/lib/sumi/palette.qml
      [ -f "$f" ] && [ -d /boot/grub ] || exit 0
      n=$(sed -n 's/.*property string name: "\(.*\)".*/\1/p' "$f" | head -1)
      case "$n" in sumi|iso|kiri|hagane|summit) ;; *) exit 0 ;; esac
      env=/boot/grub/grubenv
      [ -s "$env" ] || grub-editenv "$env" create
      cur=$(grub-editenv "$env" list | sed -n 's/^sumi_theme=//p')
      [ "$cur" = "$n" ] || grub-editenv "$env" set "sumi_theme=$n"
    '';
  };
  systemd.paths.sumi-grub-sync = {
    wantedBy = [ "paths.target" ];
    pathConfig.PathChanged = "/var/lib/sumi/palette.qml";
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.kdePackages.sddm;
    theme = "sumi";
    # qtsvg for the logo, qtdeclarative brings QtQuick.Particles for the moving login background
    extraPackages = [ pkgs.kdePackages.qtsvg pkgs.kdePackages.qtdeclarative ];
  };
  environment.systemPackages = [ sumi-sddm ];

  # the greeter runs as its own user, so the theme fonts must be installed system wide
  fonts.packages = with pkgs; [
    inter
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-serif
    (google-fonts.override { fonts = [ "ShipporiMincho" "SpaceGrotesk" ]; })
  ];

  # shared folder: written by you (sumi-theme), readable by the login screen
  systemd.tmpfiles.rules = [
    "d /var/lib/sumi 0755 ${user} users -"
    # SDDM caches compiled QML; clear it on boot so a theme update shows up
    "R /var/lib/sddm/.cache - - - - -"
  ];
}
