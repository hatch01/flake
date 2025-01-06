{
  pkgs,
  username,
  lib,
  config,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    plasma.enable = mkEnableOption "Plasma Desktop";
  };

  config = mkIf config.plasma.enable {
    services = {
      displayManager = {
        defaultSession = "plasma";
        autoLogin = {
          enable = true;
          user = username;
        };
      };
      xserver = {
        enable = true;
        xkb = {
          layout = "fr";
          variant = "";
        };
        displayManager = {
          lightdm.enable = true;
        };
      };
      desktopManager.plasma6.enable = true;
    };

    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      elisa
    ];

    environment.systemPackages = [ ]
      ++ (with pkgs.kdePackages; [
        merkuro
        qtlocation # this is needed for merkuro
        kdepim-addons
        koi
      ]);

    hm = {
      programs.plasma = {
        enable = true;
        workspace = {
          clickItemTo = "open";
          lookAndFeel = "Catppuccin-Latte-Blue";
          cursor.theme = "Catppuccin-Mocha-Dark-Cursors";
          iconTheme = "breeze";
        };

        fonts = {
          general = {
            family = "JetBrainsMono Nerd Font";
            pointSize = 10;
          };
        };

        shortcuts = {
          kwin = {
            "Switch One Desktop Down" = "Meta+Shift+Down";
            "Switch One Desktop Up" = "Meta+Shift+Up";
            "Switch One Desktop to the Left" = "Meta+Shift+Left";
            "Switch One Desktop to the Right" = "Meta+Shift+Right";
            "Switch Window Down" = [];
            "Switch Window Left" = "Meta+Alt+Left";
            "Switch Window Right" = "Meta+Alt+Right";
            "Switch Window Up" = [];
            "Switch to Desktop 1" = "Meta+F1";
            "Switch to Desktop 2" = "Meta+F2";
            "Switch to Desktop 3" = "Meta+F3";
            "Switch to Desktop 4" = "Meta+F4";
            "Switch to Desktop 5" = "Meta+F5";
            "Switch to Desktop 6" = "Meta+&";
            "Switch to Desktop 7" = "Meta+É";
            "Switch to Desktop 8" = "Meta+\"";
            "Switch to Desktop 9" = "Meta+'";
            "Switch to Desktop 10" = "Meta+(";
            "Window Maximize" = "Meta+Ctrl+Up";
            "Window Minimize" = "Meta+Ctrl+Down";
            "Window to Desktop 1" = "Meta+Shift+F1";
            "Window to Desktop 2" = "Meta+Shift+F2";
            "Window to Desktop 3" = "Meta+Shift+F3";
            "Window to Desktop 4" = "Meta+Shift+F4";
            "Window to Desktop 5" = "Meta+Shift+F5";
            "Window to Desktop 6" = "Meta+1";
            "Window to Desktop 7" = "Meta+2";
            "Window to Desktop 8" = "Meta+3";
            "Window to Desktop 9" = "Meta+4";
            "Window to Desktop 10" = "Meta+5";
            "Window to Next Screen" = [];
            "Window to Previous Screen" = [];
            "Window to Screen 0" = "Meta+Ctrl+1";
            "Window to Screen 1" = "Meta+Ctrl+2";
            "view_zoom_in" = "Meta+Ctrl+Num++";
            "view_zoom_out" = "Meta+Ctrl+Num+-";
            "Overview" = "Meta+Tab";
            "Grid View" = "Meta+Shift+Tab";
          };
          "yakuake"."toggle-window-state" = "Meta+Return";
          # "services/com.mitchellh.ghostty.desktop"."open" = "Ctrl+Alt+T";
          "services/org.kde.konsole.desktop"."_launch" = "Ctrl+Alt+T";
        };
        configFile = {
          "kcminputrc"."Libinput.1739.52861.SYNA32B9:00 06CB:CE7D Touchpad"."NaturalScroll".value = true;
          "kcminputrc"."Libinput.1739.52861.SYNA32B9:00 06CB:CE7D Touchpad"."TapToClick".value = true;
          "kcminputrc"."Keyboard"."NumLock".value = 0;
          "krunnerrc"."General"."FreeFloating".value = true;
          "plasma-org/kde/plasma/desktop-appletsrc" = {
            "Containments/2/Applets/30" = {
              "immutability".value = 1;
              "plugin".value = "day-night-switcher";
            };
            "Containments/37/Applets/62" = {
              "immutability".value = 1;
              "plugin".value = "day-night-switcher";
            };
            "Containments/2/Applets/31/Configuration/General" = {
              "customButtonImage".value = "nix-snowflake";
              "favoritesPortedToKAstats".value = true;
              "systemFavorites".value = "suspend\\,hibernate\\,reboot\\,shutdown";
              "useCustomButtonImage".value = true;
            };
            "Containments/2/Applets/5/Configuration/General"."groupedTaskVisualization".value = 2;
            "Containments/127/Applets/145" = {
              "immutability".value = 1;
              "plugin".value = "org.kde.plasma.digitalclock";
            };
            "Containments/127/Applets/145/Configuration/Appearance" = {
              "enabledCalendarPlugins".value = "pimevents";
              "showSeconds".value = "Always";
              "showWeekNumbers".value = true;
            };
            "Containments/78/Applets/96" = {
              "immutability".value = 1;
              "plugin".value = "org.kde.plasma.digitalclock";
            };
            "Containments/78/Applets/96/Configuration/Appearance" = {
              "enabledCalendarPlugins".value = "pimevents";
              "showSeconds".value = "Always";
              "showWeekNumbers".value = true;
            };
            "Containments/103/Applets/121" = {
              "immutability".value = 1;
              "plugin".value = "org.kde.plasma.digitalclock";
            };
            "Containments/103/Applets/121/Configuration/Appearance" = {
              "enabledCalendarPlugins".value = "pimevents";
              "showSeconds".value = "Always";
              "showWeekNumbers".value = true;
            };
          };

          # desktop configs
          "kwinrc" = {
            "Windows"."RollOverDesktops".value = true;
            "Desktops" = {
              "Number".value = 10;
              "Rows".value = 2;
            };
            "Effect-slide" = {
              "HorizontalGap".value = 0;
              "VerticalGap".value = 0;
            };

            "org.kde.kdecoration2"."BorderSizeAuto".value = false;
            "org.kde.kdecoration2"."BorderSize".value = "Tiny";
            "NightColor" = {
              "Active".value = true;
              "NightTemperature".value = 3400;
            };
          };

          #mime apps WARNING DONT FORGET ; IN THE STRING
          "mimeapps.list"."Added Associations" = {
            "text/markdown".value = "org.kde.ghostwriter.desktop;";
          };
          "plasmaparc"."General"."AudioFeedback".value = false;

          #power management
          "powerdevilrc" = {
            "AC/Performance"."PowerProfile".value = "performance";
            "Battery/Performance"."PowerProfile".value = "balanced";
            "LowBattery/Performance"."PowerProfile".value = "power-saver";
          };

          "koirc" = {
            General = {
              current.value = "Light";
              latitude.value = 45.778;
              longitude.value = 4.885;
              notify.value = 2;
              schedule.value = 2;
              schedule-type.value = "sun";
              start-hidden.value = 2;
            };
            "ColorScheme" = {
              dark.value = "/var/run/current-system/sw/share/color-schemes/CatppuccinMochaBlue.colors";
              enabled.value = true;
              light.value = "/var/run/current-system/sw/share/color-schemes/CatppuccinLatteBlue.colors";
            };
            "GTKTheme" = {
              dark.value = "Breeze-Dark";
              enabled.value = true;
              light.value = "Breeze";
            };
            "IconTheme" = {
              dark.value = "catppuccin-mocha-dark-cursors";
              enabled.value = true;
              light.value = "catppuccin-mocha-dark-cursors";
            };
            "KvantumStyle" = {
              dark.value = "";
              enabled.value = false;
              light.value = "";
            };
            "PlasmaStyle" = {
              dark.value = "breeze-dark";
              enabled.value = false;
              light.value = "breeze-dark";
            };
            "Wallpaper" = {
              dark.value = "";
              enabled.value = false;
              light.value = "";
            };
          };

          "ksmserverrc"."General"."loginMode".value = "emptySession";
        };
      };

      # home.file.".local/share/plasma/plasmoids/day-night-switcher" = {
      #   source = ./day-night-switcher;
      #   recursive = true;
      #   force = true;
      # };

      # autostart some apps
      home.file.".config/autostart/" = {
        source = ./autostart;
        force = true;
        recursive = true;
      };
    };
  };
}
