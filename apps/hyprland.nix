{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    hyprland.enable = mkEnableOption "hyprland";
  };

  config = mkIf config.hyprland.enable {
    environment.systemPackages = with pkgs; [
      fuzzel
      wlogout
      brightnessctl
    ];

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    hm = {
      wayland.windowManager.hyprland = {
        enable = true;
        systemd.enable = false;
        xwayland.enable = true;
        settings = {
          "$mainMod" = "SUPER";

          monitor = [
            "eDP-1, highres, auto, 1"
            ", preferred, auto, 1"
          ];

          bind = [
            "$mainMod, Return, exec, kitty"
            "$mainMod SHIFT, A, killactive,"
            "$mainMod SHIFT, E, exit,"
            "$mainMod SHIFT, Space, togglefloating,"
            "$mainMod, D, exec, fuzzel"

            "$mainMod, F, fullscreen, 0"
            "$mainMod, P, pseudo, # dwindle"
            "$mainMod, J, togglesplit, # dwindle"
            "$mainMod SHIFT, N, exec, wlogout"
            "$mainMod, E, exec, dolphin"

            # audio
            ",XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
            ",XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
            ",XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
            ",XF86AudioMicMute, exec, pactl set-source-mute @DEFAULT_SINK@ toggle"
            ",XF86AudioPause, exec, playerctl play-pause"
            ",XF86AudioPlay, exec, playerctl play-pause"
            ",XF86AudioNext, exec, playerctl next"
            ",XF86AudioPrev, exec, playerctl previous"

            "$mainMod, c, exec, pavucontrol"

            # backlight
            ",XF86MonBrightnessUp, exec, brightnessctl s +5%"
            ",XF86MonBrightnessDown, exec, brightnessctl s 5%-"

            # Move focus
            "$mainMod, h, movefocus, l"
            "$mainMod, j, movefocus, d"
            "$mainMod, k, movefocus, u"
            "$mainMod, l, movefocus, r"

            # Move focus with mainMod + arrow keys
            "$mainMod, left, movefocus, l"
            "$mainMod, down, movefocus, d"
            "$mainMod, up, movefocus, u"
            "$mainMod, right, movefocus, r"

            # Move windows
            "$mainMod SHIFT, h, movewindow, l"
            "$mainMod SHIFT, j, movewindow, d"
            "$mainMod SHIFT, k, movewindow, u"
            "$mainMod SHIFT, l, movewindow, r"

            # Move windows with arrow keys
            "$mainMod SHIFT, left, movewindow, l"
            "$mainMod SHIFT, down, movewindow, d"
            "$mainMod SHIFT, up, movewindow, u"
            "$mainMod SHIFT, right, movewindow, r"

            # Switch workspaces with mainMod + [0-9
            "$mainMod, ampersand, workspace, 1"
            "$mainMod, eacute, workspace, 2"
            "$mainMod, quotedbl, workspace, 3"
            "$mainMod, apostrophe, workspace, 4"
            "$mainMod, parenleft, workspace, 5"
            "$mainMod, minus, workspace, 6"
            "$mainMod, egrave, workspace, 7"
            "$mainMod, underscore, workspace, 8"
            "$mainMod, ccedilla, workspace, 9"
            "$mainMod, agrave, workspace, 10"

            # Move active window to a workspace with mainMod + SHIFT + [0-9]
            "$mainMod SHIFT, ampersand, movetoworkspacesilent, 1"
            "$mainMod SHIFT, eacute, movetoworkspacesilent, 2"
            "$mainMod SHIFT, quotedbl, movetoworkspacesilent, 3"
            "$mainMod SHIFT, apostrophe, movetoworkspacesilent, 4"
            "$mainMod SHIFT, parenleft, movetoworkspacesilent, 5"
            "$mainMod SHIFT, minus, movetoworkspacesilent, 6"
            "$mainMod SHIFT, egrave, movetoworkspacesilent, 7"
            "$mainMod SHIFT, underscore, movetoworkspacesilent, 8"
            "$mainMod SHIFT, ccedilla, movetoworkspacesilent, 9"
            "$mainMod SHIFT, agrave, movetoworkspacesilent, 10"

            # Kill
            "CTRL ALT SHIFT, K, exec, hyprctl kill"
          ];

          animations.enabled = false;

          misc = {
            disable_hyprland_logo = true;
            force_default_wallpaper = 0;
          };

          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
          };

          decoration = {
            shadow.enabled = false;
            blur.enabled = false;
            rounding = 10;
          };

          input = {
            kb_layout = "fr";
            follow_mouse = 1;
            numlock_by_default = true;

            touchpad = {
              drag_lock = true;
              natural_scroll = true;
            };

            sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

            accel_profile = "flat";

            repeat_delay = 200;
            repeat_rate = 40;

            float_switch_override_focus = 0;
          };

          xwayland.force_zero_scaling = true;

          # Startup Apps
          exec-once = [
          ];

          bindm = [
            "$mainMod, mouse:272, movewindow"
            "$mainMod, mouse:273, resizewindow"
            "$mainMod ALT, mouse:272, resizewindow"
          ];
        };
      };

      programs.kitty = lib.mkForce {
        enable = true;

        settings = {
          enable_audio_bell = false;
          window_padding_width = 15;
          themeFile = "Catppuccin-Latte";
        };

        font = {
          name = "JetBrains Mono";
          size = 12;
        };
      };
    };
  };
}
