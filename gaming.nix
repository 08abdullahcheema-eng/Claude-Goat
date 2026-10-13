# Games and voice chat: Steam with Proton (and Proton-GE), GameMode, Gamescope, MangoHud, Vesktop.
# Steam launch options for a game (right click > Properties), so it runs on the RTX 4060:
#   gamemoderun nvidia-offload %command%
# with an FPS overlay:
#   gamemoderun nvidia-offload mangohud %command%
{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfree = lib.mkDefault true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];   # pick it per game under Compatibility
  };
  programs.gamemode.enable = true;    # CPU/GPU into performance mode while a game runs
  programs.gamescope.enable = true;
  users.users.larp.extraGroups = [ "gamemode" ];

  environment.systemPackages = with pkgs; [
    mangohud     # FPS / temperature overlay
    vesktop      # Discord with working screen sharing on Wayland
  ];
}
