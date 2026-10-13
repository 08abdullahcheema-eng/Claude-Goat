# RTX 4060 with PRIME offload: the Intel GPU draws the desktop (cool, quiet, long battery),
# the NVIDIA GPU wakes up only for what you start with `nvidia-offload` (games, Blender, ...).
# In the BIOS keep the GPU mode on "Hybrid" (MSHybrid), not "Discrete".
#
# The two bus IDs below are the usual ones on the Helios Neo 16. Check yours with
#   nix-shell -p pciutils --run "lspci | grep -E 'VGA|3D'"
# "00:02.0 VGA ... Intel" -> PCI:0:2:0     "01:00.0 VGA ... NVIDIA" -> PCI:1:0:0
{ config, lib, pkgs, ... }:
{
  nixpkgs.config.allowUnfree = lib.mkDefault true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;          # 32-bit games and Steam itself
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = true;                 # NVIDIA's open kernel module, the recommended one for RTX 40
    modesetting.enable = true;   # needed for Wayland / Hyprland
    nvidiaSettings = true;
    # let the GPU power off completely when nothing uses it
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;   # gives you the `nvidia-offload` command
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
