# Sumi shell (Quickshell): bar, launcher, panels, notifications, OSD, polkit,
# theme switcher and the matching lock screen. Replaces Waybar, Rofi menus and mako.
{ config, pkgs, lib, ... }:
let
  shellDir = "${config.xdg.configHome}/quickshell/sumi";

  sumi-theme = pkgs.writeShellApplication {
    name = "sumi-theme";
    runtimeInputs = with pkgs; [ jq procps swaybg coreutils util-linux gnused gawk dbus ];
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
    runtimeInputs = with pkgs; [ jq playerctl gawk coreutils gnugrep ];
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
    cliphist               # clipboard history for the launcher's Clipboard tab
    wtype                  # "paste" from the clipboard and emoji tabs (Shift+Enter)
    noto-fonts-color-emoji
    yazi
    btop
    claude-code
    # theme fonts: Shippori Mincho (Sumi, Iso), Space Grotesk (Kiri, Summit), Inter (Hagane, Iso)
    inter
    (google-fonts.override { fonts = [ "ShipporiMincho" "SpaceGrotesk" ]; })
  ]) ++ [ sumi-theme sumi-agents sumi-lockinfo ];

  # the shell itself
  xdg.configFile."quickshell/sumi".source = ./sumi/shell;

  fonts.fontconfig.enable = true;

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

  # apps follow the theme: Qt/KDE apps (Dolphin, Kate, Okular...) read the colour scheme that
  # sumi-theme writes into ~/.config/kdeglobals (running ones recolour live), GTK apps read
  # ~/.config/sumi/gtk.css on a dark adw-gtk3 base (they pick it up when they start)
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };
  gtk = {
    enable = true;
    theme = { name = "adw-gtk3-dark"; package = pkgs.adw-gtk3; };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    # home-manager leaves the theme out of GTK 4's settings.ini, plain GTK 4 apps (pavucontrol...) need it
    gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; gtk-theme-name = "adw-gtk3-dark"; };
    gtk3.extraCss = ''@import url("file://${config.xdg.configHome}/sumi/gtk.css");'';
    gtk4.extraCss = ''@import url("file://${config.xdg.configHome}/sumi/gtk.css");'';
  };
  # libadwaita apps ask the portal for dark or light, the portal reads this
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "adw-gtk3-dark";
    icon-theme = "Papirus-Dark";
  };

  # lock screen
  programs.hyprlock.enable = true;
  programs.hyprlock.settings = lib.mkForce { };
  programs.hyprlock.extraConfig = lib.mkForce (builtins.readFile ./sumi/hyprlock.conf);

  # idle: screensaver after 3 min, dim after 4.5, lock after 5, screen off after 5.5, sleep after 20.
  # Closing the lid suspends (systemd default) and the screen is locked before it sleeps.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;      # videos and games keep the screen awake
      };
      listener = [
        { timeout = 180; on-timeout = "${ipc} shell saver true"; on-resume = "${ipc} shell saver false"; }
        { timeout = 270; on-timeout = "brightnessctl -s set 15%"; on-resume = "brightnessctl -r"; }
        { timeout = 300; on-timeout = "loginctl lock-session"; }
        { timeout = 330; on-timeout = "hyprctl dispatch dpms off"; on-resume = "hyprctl dispatch dpms on"; }
        { timeout = 1200; on-timeout = "systemctl suspend"; }
      ];
    };
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = lib.mkForce [
      "sumi-theme --restore"
      "${qs} -n -c sumi"
      # clipboard history: every copied text and picture goes into cliphist
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
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
    # the theme's own animations and border colours come from ~/.config/sumi/hypr-theme.conf
    # (written by sumi-theme, switched together with the theme)
    animations.enabled = lib.mkForce true;
    source = [ "~/.config/sumi/hypr-theme.conf" ];

    dwindle = {
      preserve_split = lib.mkForce true;
      force_split = lib.mkForce 2;
    };
    misc = {
      disable_hyprland_logo = lib.mkForce true;
      disable_splash_rendering = lib.mkForce true;
      force_default_wallpaper = lib.mkForce 0;
      focus_on_activate = lib.mkForce true;
      # a new window next to a maximised one ends the maximise and tiles beside it
      on_focus_under_fullscreen = lib.mkForce 2;
    };
    # apps may not maximise themselves (Electron apps like Claude or Discord do), so the
    # next terminal always gets its own tile instead of covering the screen.
    # Real fullscreen (games, SUPER+F) still works.
    windowrule = [
      "suppress_event maximize, match:class .*"
    ];
    # frosted glass behind the bar (only where the bar is drawn, not its transparent parts)
    decoration.blur = {
      enabled = lib.mkDefault true;
      size = lib.mkDefault 8;
      passes = lib.mkDefault 3;
    };
    layerrule = [
      "blur on, match:namespace sumi-bar"
      "ignore_alpha 0.25, match:namespace sumi-bar"
    ];

    bind = lib.mkForce ([
      "SUPER, Q, exec, kitty"
      "SUPER, B, exec, helium"
      "SUPER, E, exec, kitty -e yazi"
      "SUPER, C, killactive,"
      "SUPER, M, exec, ${ipc} shell open power"
      "SUPER, V, exec, ${ipc} shell launcher clip"
      "SUPER SHIFT, V, togglefloating,"
      "SUPER CTRL, E, exec, ${ipc} shell launcher emoji"
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
