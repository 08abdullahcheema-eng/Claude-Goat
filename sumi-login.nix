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
in
{
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
    (google-fonts.override { fonts = [ "ShipporiMincho" "SpaceGrotesk" "SpaceMono" "Cinzel" "Fraunces" ]; })
  ];

  # shared folder: written by you (sumi-theme), readable by the login screen
  systemd.tmpfiles.rules = [ "d /var/lib/sumi 0755 ${user} users -" ];
}
