{
  pkgs,
  username,
  lib,
  config,
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

    environment.plasma6.excludePackages = with pkgs.libsForQt5; [
      elisa
    ];

    hm = {
      programs.plasma = {
        enable = true;
        workspace = {
          clickItemTo = "open";
          lookAndFeel = "Catppuccin-Latte-Blue";
          cursorTheme = "Catppuccin-Mocha-Dark-Cursors";
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
            "Switch to Desktop 1" = "Meta+&";
            "Switch to Desktop 2" = "Meta+É";
            "Switch to Desktop 3" = "Meta+\"";
            "Switch to Desktop 4" = "Meta+'";
            "Switch to Desktop 5" = "Meta+(";
            "Switch to Desktop 6" = "Meta+-";
            "Switch to Desktop 7" = "Meta+È";
            "Switch to Desktop 8" = "Meta+_";
            "Switch to Desktop 9" = "Meta+ç";
            "Switch to Desktop 10" = "Meta+à";
            "Window Maximize" = "Meta+Ctrl+Up";
            "Window Minimize" = "Meta+Ctrl+Down";
            "Window to Desktop 1" = "Meta+1";
            "Window to Desktop 2" = "Meta+2";
            "Window to Desktop 3" = "Meta+3";
            "Window to Desktop 4" = "Meta+4";
            "Window to Desktop 5" = "Meta+5";
            "Window to Desktop 6" = "Meta+6";
            "Window to Desktop 7" = "Meta+7";
            "Window to Desktop 8" = "Meta+8";
            "Window to Desktop 9" = "Meta+9";
            "Window to Desktop 10" = "Meta+0";
            "Window to Next Screen" = [];
            "Window to Previous Screen" = [];
            "Window to Screen 0" = "Meta+Ctrl+1";
            "Window to Screen 1" = "Meta+Ctrl+2";
            "view_zoom_in" = "Meta+Ctrl+Num++";
            "view_zoom_out" = "Meta+Ctrl+Num+-";
            "Overview" = "Meta+Tab";
          };
          "yakuake"."toggle-window-state" = "Meta+Return";
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
          };

          # desktop configs
          "kwinrc"."Windows"."RollOverDesktops".value = true;
          "kwinrc"."Desktops" = {
            "Number".value = 10;
            "Rows".value = 2;
          };
          "kwinrc"."Effect-slide" = {
            "HorizontalGap".value = 0;
            "VerticalGap".value = 0;
          };
          "kwinrc"."org.kde.kdecoration2"."BorderSizeAuto".value = false;
          "kwinrc"."org.kde.kdecoration2"."BorderSize".value = "Tiny";

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
