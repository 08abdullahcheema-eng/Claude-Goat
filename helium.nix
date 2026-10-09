# Helium browser (not in nixpkgs yet): official AppImage, wrapped so it runs on NixOS.
{ pkgs, ... }:
let
  pname = "helium";
  version = "0.19.2.1";
  src = pkgs.fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-oEVQo8fHC9rTrNOkQw7ajSr8C/cXOpxYpAP+q5UXCH8=";
  };
  contents = pkgs.appimageTools.extract { inherit pname version src; };
  helium = pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    extraInstallCommands = ''
      install -Dm444 ${contents}/helium.desktop $out/share/applications/helium.desktop
      install -Dm444 ${contents}/usr/share/icons/hicolor/256x256/apps/helium.png \
        $out/share/icons/hicolor/256x256/apps/helium.png
    '';
  };
in
{
  home.packages = [ helium ];
}
