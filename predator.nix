# PredatorSense on NixOS: loads the linuwu_sense driver (instead of acer_wmi)
# and lets the user larp control fans, thermal profile, keyboard light and battery.
{ config, pkgs, lib, ... }:
let
  linuwu-sense = config.boot.kernelPackages.callPackage ./predator/linuwu-sense.nix { };
  base = "/sys/module/linuwu_sense/drivers/platform:acer-wmi/acer-wmi";
  perms = pkgs.writeShellScript "predator-perms" ''
    for i in $(${pkgs.coreutils}/bin/seq 1 40); do
      [ -d "${base}" ] && break
      ${pkgs.coreutils}/bin/sleep 0.5
    done
    for f in "${base}"/*_sense/* "${base}"/four_zoned_kb/* /sys/firmware/acpi/platform_profile; do
      [ -f "$f" ] || continue
      ${pkgs.coreutils}/bin/chgrp predator "$f" && ${pkgs.coreutils}/bin/chmod g+w "$f"
    done
  '';
in
{
  boot.extraModulePackages = [ linuwu-sense ];
  boot.kernelModules = [ "linuwu_sense" ];
  boot.blacklistedKernelModules = [ "acer_wmi" ];

  users.groups.predator = { };
  users.users.larp.extraGroups = [ "predator" ];

  # sysfs files belong to root; give the predator group write access once the driver is up
  systemd.services.predator-sense-perms = {
    description = "Let the predator group control fans, thermal profile and keyboard light";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = perms;
    };
  };
}
