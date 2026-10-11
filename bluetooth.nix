# Bluetooth for the laptop: BlueZ service, adapter on at boot, Blueman as manager.
# The bar's Bluetooth icon: left click opens the menu, right click turns the adapter on or off.
{ pkgs, ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;            # shows the battery level of headphones
        FastConnectable = true;
        JustWorksRepairing = "always";  # AirPods and other earbuds re-pair without trouble
        MultiProfile = "multiple";
      };
      Policy = {
        AutoEnable = true;
        ReconnectAttempts = 7;
        ReconnectIntervals = "1,2,4,8,16,32,64";
      };
    };
  };
  services.blueman.enable = true;

  # the Bluetooth chip must not fall asleep, that drops earbuds after a few seconds
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=0
  '';
}
