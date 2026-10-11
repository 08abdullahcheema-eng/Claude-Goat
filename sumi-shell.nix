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
      "${qs} -n -c sumi"
    ];

    # window feel: small even gaps that line up with the floating bar, smooth motion, tidy tiling
    general = {
      gaps_in = lib.mkForce 4;
      gaps_out = lib.mkForce "6, 10, 10, 10";
      border_size = lib.mkForce 2;
      resize_on_border = lib.mkForce true;
      extend_border_grab_area = lib.mkForce 14;
      layout = lib.mkForce "dwindle";
    };
    animations = {
      enabled = lib.mkForce true;
      bezier = lib.mkForce [
        "easeOutQuint, 0.22, 1, 0.36, 1"
        "smooth, 0.25, 0.1, 0.25, 1"
      ];
      animation = lib.mkForce [
        "windows, 1, 5, easeOutQuint, popin 88%"
        "windowsOut, 1, 4, smooth, popin 88%"
        "windowsMove, 1, 4, easeOutQuint"
        "fade, 1, 5, smooth"
        "border, 1, 8, smooth"
        "layers, 1, 4, easeOutQuint, fade"
        "workspaces, 1, 6, easeOutQuint, slide"
      ];
    };
    dwindle = {
      preserve_split = lib.mkForce true;
      force_split = lib.mkForce 2;
    };
    misc = {
      disable_hyprland_logo = lib.mkForce true;
      disable_splash_rendering = lib.mkForce true;
      force_default_wallpaper = lib.mkForce 0;
      focus_on_activate = lib.mkForce true;
    };

    bind = lib.mkForce ([
      "SUPER, Q, exec, kitty"
      "SUPER, B, exec, helium"
      "SUPER, E, exec, kitty -e yazi"
      "SUPER, C, killactive,"
      "SUPER, M, exec, ${ipc} shell open power"
      "SUPER, V, togglefloating,"
      "SUPER, F, fullscreen,"
      "SUPER SHIFT, F, fullscreen, 1"
      "SUPER, L, exec, pidof hyprlock || hyprlock"

      # tiling: flip the split, pseudo-tile, pin a floating window on top of every workspace
      "SUPER, T, layoutmsg, togglesplit"
      "SUPER, P, pseudo,"
      "SUPER, O, pin,"

      # move the focused window around the layout
      "SUPER SHIFT, left, movewindow, l"
      "SUPER SHIFT, right, movewindow, r"
      "SUPER SHIFT, up, movewindow, u"
      "SUPER SHIFT, down, movewindow, d"

      # workspaces: back and forth, next and previous, scratchpad
      "SUPER, TAB, workspace, previous"
      "SUPER, period, workspace, e+1"
      "SUPER, comma, workspace, e-1"
      "SUPER, mouse_down, workspace, e+1"
      "SUPER, mouse_up, workspace, e-1"
      "SUPER, S, togglespecialworkspace, magic"
      "SUPER ALT, S, movetoworkspace, special:magic"
      "ALT, TAB, cyclenext,"
      "ALT, TAB, bringactivetotop,"

      # Sumi shell
      "SUPER, SPACE, exec, ${ipc} shell launcher all"
      "SUPER, X, exec, ${ipc} shell toggle power"
      "SUPER, W, killactive,"
      "SUPER CTRL, N, exec, ${ipc} shell toggle network"
      "SUPER CTRL, A, exec, ${ipc} shell toggle agents"
      "SUPER CTRL, T, exec, ${ipc} shell toggle themes"
      "SUPER CTRL, SPACE, exec, ${ipc} shell toggle themes"
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
        "SUPER ALT, ${ws}, movetoworkspacesilent, ${ws}"
      ]) 9));

    # hold to keep resizing the focused window
    binde = lib.mkForce [
      "SUPER ALT, left, resizeactive, -40 0"
      "SUPER ALT, right, resizeactive, 40 0"
      "SUPER ALT, up, resizeactive, 0 -40"
      "SUPER ALT, down, resizeactive, 0 40"
    ];

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
