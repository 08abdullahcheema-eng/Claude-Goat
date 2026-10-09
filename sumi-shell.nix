# Sumi shell (Quickshell): bar, launcher, panels, notifications, OSD, polkit,
# theme switcher and the matching lock screen. Replaces Waybar, Rofi menus and mako.
{ config, pkgs, lib, ... }:
let
  shellDir = "${config.xdg.configHome}/quickshell/sumi";

  sumi-theme = pkgs.writeShellApplication {
    name = "sumi-theme";
    runtimeInputs = with pkgs; [ jq procps swaybg coreutils util-linux gnused ];
    text = ''
      export SUMI_SHELL_DIR="''${SUMI_SHELL_DIR:-${shellDir}}"
    '' + builtins.readFile ./sumi/scripts/sumi-theme.sh;
    checkPhase = "";
  };

  sumi-agents = pkgs.writers.writePython3Bin "sumi-agents" {
    doCheck = false;
  } (builtins.readFile ./sumi/scripts/sumi-agents.py);

  sumi-lockinfo = pkgs.writeShellApplication {
    name = "sumi-lockinfo";
    runtimeInputs = with pkgs; [ jq playerctl gawk coreutils ];
    text = builtins.readFile ./sumi/scripts/sumi-lockinfo.sh;
    checkPhase = "";
  };

  qs = "${pkgs.quickshell}/bin/qs";
  ipc = "${qs} ipc -c sumi call";
in
{
  home.packages = (with pkgs; [
    quickshell
    qrencode
    jq
    curl
    iputils
    playerctl
    brightnessctl
    networkmanagerapplet   # nm-connection-editor
    pavucontrol
    swaybg
    grim
    slurp
    wl-clipboard
    yazi
    btop
    claude-code
  ]) ++ [ sumi-theme sumi-agents sumi-lockinfo ];

  # the shell itself
  xdg.configFile."quickshell/sumi".source = ./sumi/shell;

  # write default theme files once (they stay editable by sumi-theme)
  home.activation.sumiTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${sumi-theme}/bin/sumi-theme --init || true
  '';

  # old pieces that the shell replaces
  programs.waybar.enable = lib.mkForce false;
  services.mako.enable = lib.mkForce false;

  # kitty follows the theme switcher
  programs.kitty.extraConfig = lib.mkAfter ''
    include ../sumi/kitty.conf
  '';

  # lock screen
  programs.hyprlock.enable = true;
  programs.hyprlock.settings = lib.mkForce { };
  programs.hyprlock.extraConfig = lib.mkForce (builtins.readFile ./sumi/hyprlock.conf);

  wayland.windowManager.hyprland.settings = {
    exec-once = lib.mkForce [
      "sumi-theme --restore"
      "${qs} -c sumi"
    ];

    bind = lib.mkForce ([
      "SUPER, Q, exec, kitty"
      "SUPER, B, exec, firefox"
      "SUPER, E, exec, kitty -e yazi"
      "SUPER, C, killactive,"
      "SUPER, M, exec, ${ipc} shell open power"
      "SUPER, V, togglefloating,"
      "SUPER, F, fullscreen,"
      "SUPER, L, exec, pidof hyprlock || hyprlock"

      # Sumi shell
      "SUPER, SPACE, exec, ${ipc} shell launcher all"
      "SUPER, R, exec, ${ipc} shell launcher apps"
      "SUPER, X, exec, ${ipc} shell toggle power"
      "SUPER, W, killactive,"
      "SUPER CTRL, N, exec, ${ipc} shell toggle network"
      "SUPER CTRL, A, exec, ${ipc} shell toggle agents"
      "SUPER CTRL, T, exec, ${ipc} shell toggle themes"
      "SUPER CTRL, D, exec, ${ipc} shell dnd"
      "SUPER CTRL, P, exec, ${ipc} shell toggle predator"

      # screenshots
      "SUPER SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
      ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"

      # focus
      "SUPER, left, movefocus, l"
      "SUPER, right, movefocus, r"
      "SUPER, up, movefocus, u"
      "SUPER, down, movefocus, d"
    ] ++ builtins.concatLists (builtins.genList (i:
      let ws = toString (i + 1); in [
        "SUPER, ${ws}, workspace, ${ws}"
        "SUPER SHIFT, ${ws}, movetoworkspace, ${ws}"
      ]) 9));

    bindm = lib.mkForce [
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
    ];

    # volume shows the OSD by itself, brightness tells the shell
    bindel = lib.mkForce [
      ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86MonBrightnessUp, exec, brightnessctl -q s 5%+ && ${ipc} osd brightness"
      ", XF86MonBrightnessDown, exec, brightnessctl -q s 5%- && ${ipc} osd brightness"
    ];
    bindl = lib.mkForce [
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPrev, exec, playerctl previous"
    ];
  };
}
