# The things that make NixOS pleasant as a daily system:
# screen sharing and file pickers, power profiles, running downloaded Linux programs,
# Flatpak, automatic cleanup, the Windows clock fix and compressed swap.
{ pkgs, lib, ... }:
{
  # ---- screen sharing (Discord, browser) and file dialogs ----
  programs.hyprland.enable = lib.mkDefault true;   # brings xdg-desktop-portal-hyprland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];   # open/save dialogs
  };

  # ---- power: the battery panel switches these profiles (power saver / balanced / performance) ----
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # ---- downloaded Linux programs (zips, installers, AppImages) just start ----
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc zlib zstd openssl curl glib dbus expat libuuid
      nss nspr atk at-spi2-atk at-spi2-core cups gtk3 pango cairo gdk-pixbuf
      libdrm mesa libgbm libGL libglvnd vulkan-loader libxkbcommon
      alsa-lib libpulseaudio pipewire udev libsecret libnotify fontconfig freetype
      xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext xorg.libXfixes
      xorg.libXrandr xorg.libXrender xorg.libXtst xorg.libXi xorg.libXcursor xorg.libxcb xorg.libxshmfence
    ];
  };
  programs.appimage = {
    enable = true;
    binfmt = true;      # ./Something.AppImage runs directly
  };

  # ---- Flatpak with Flathub, for apps that are not in nixpkgs ----
  services.flatpak.enable = true;
  systemd.services.flathub-remote = {
    description = "Add the Flathub repository";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
    script = "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo";
  };

  # ---- keep the 512 GB SSD from filling up ----
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;
  nix.settings.auto-optimise-store = true;
  # only the last 10 systems in the boot menu (whichever boot loader you use)
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
  boot.loader.grub.configurationLimit = lib.mkDefault 10;

  # ---- dual boot: Windows keeps the hardware clock in local time, Linux now does the same ----
  time.hardwareClockInLocalTime = true;

  # ---- compressed swap in RAM ----
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };

  # ---- firmware updates (BIOS, SSD) from Linux: fwupdmgr refresh && fwupdmgr update ----
  services.fwupd.enable = true;
}
