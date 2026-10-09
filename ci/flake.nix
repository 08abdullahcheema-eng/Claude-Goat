{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = { url = "github:nix-community/home-manager/release-26.05"; inputs.nixpkgs.follows = "nixpkgs"; };
  };
  outputs = { nixpkgs, home-manager, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
    in {
      homeConfigurations.test = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ../sumi-shell.nix
          ../helium.nix
          {
            home.username = "larp";
            home.homeDirectory = "/home/larp";
            home.stateVersion = "26.05";
            programs.kitty.enable = true;
            programs.waybar.enable = true;
            services.mako.enable = true;
            programs.hyprlock.settings = { general.hide_cursor = false; };
            wayland.windowManager.hyprland = {
              enable = true;
              package = null;
              portalPackage = null;
              configType = "hyprlang";
              settings = {
                bind = [ "SUPER, Z, exec, old-bind-should-be-gone" ];
                exec-once = [ "waybar" ];
                general.border_size = 2;
              };
            };
          }
        ];
      };
      packages.x86_64-linux = {
        inherit (pkgs) quickshell sway grim hyprlock mesa libglvnd jq papirus-icon-theme kitty pavucontrol btop libnotify dbus;
        fonts = pkgs.symlinkJoin { name = "fonts"; paths = [ pkgs.nerd-fonts.jetbrains-mono pkgs.noto-fonts-cjk-serif pkgs.inter ]; };
        sddm = pkgs.kdePackages.sddm;
      };
    };
}
