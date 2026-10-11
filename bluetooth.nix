# Bluetooth for the laptop: BlueZ service, adapter on at boot, Blueman as manager.
# The bar's Bluetooth icon: left click turns the adapter on or off, right click opens Blueman.
{ pkgs, ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;          # shows the battery level of headphones
        FastConnectable = true;
      };
    };
  };
  services.blueman.enable = true;
}
