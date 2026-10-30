{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    konsole.enable = mkEnableOption "Enable Konsole";
  };

  config = mkIf config.konsole.enable {
    environment.systemPackages = with pkgs; [ kdePackages.konsole ];

    hm.programs.konsole = {
      enable = true;

      defaultProfile = "dark";

      # https://github.com/catppuccin/konsole
      customColorSchemes = {
        "catppuccin-mocha" = {
          General = {
            Blur = true;
            ColorRandomization = false;
            Description = "Catppuccin Mocha";
            # 50% transparency, blurred background
            Opacity = 0.5;
            Wallpaper = "";
          };

          Background = {
            Color = "30,30,46";
          };
          BackgroundFaint = {
            Color = "30,30,46";
          };
          BackgroundIntense = {
            Color = "30,30,46";
          };

          Foreground = {
            Color = "205,214,244";
          };
          ForegroundFaint = {
            Color = "205,214,244";
          };
          ForegroundIntense = {
            Color = "205,214,244";
          };

          Color0 = {
            Color = "108,112,134";
          };
          Color0Faint = {
            Color = "108,112,134";
          };
          Color0Intense = {
            Color = "108,112,134";
          };
          Color1 = {
            Color = "243,139,168";
          };
          Color1Faint = {
            Color = "243,139,168";
          };
          Color1Intense = {
            Color = "243,139,168";
          };
          Color2 = {
            Color = "166,227,161";
          };
          Color2Faint = {
            Color = "166,227,161";
          };
          Color2Intense = {
            Color = "166,227,161";
          };
          Color3 = {
            Color = "249,226,175";
          };
          Color3Faint = {
            Color = "249,226,175";
          };
          Color3Intense = {
            Color = "249,226,175";
          };
          Color4 = {
            Color = "137,180,250";
          };
          Color4Faint = {
            Color = "137,180,250";
          };
          Color4Intense = {
            Color = "137,180,250";
          };
          Color5 = {
            Color = "203,166,247";
          };
          Color5Faint = {
            Color = "203,166,247";
          };
          Color5Intense = {
            Color = "203,166,247";
          };
          Color6 = {
            Color = "137,220,235";
          };
          Color6Faint = {
            Color = "137,220,235";
          };
          Color6Intense = {
            Color = "137,220,235";
          };
          Color7 = {
            Color = "205,214,244";
          };
          Color7Faint = {
            Color = "205,214,244";
          };
          Color7Intense = {
            Color = "205,214,244";
          };
        };
        "catppuccin-latte" = {
          General = {
            Blur = true;
            ColorRandomization = false;
            Description = "Catppuccin Latte";
            # 50% transparency, blurred background
            Opacity = 0.5;
            Wallpaper = "";
          };

          Background = {
            Color = "239,241,245";
          };
          BackgroundFaint = {
            Color = "239,241,245";
          };
          BackgroundIntense = {
            Color = "239,241,245";
          };

          Foreground = {
            Color = "76,79,105";
          };
          ForegroundFaint = {
            Color = "76,79,105";
          };
          ForegroundIntense = {
            Color = "76,79,105";
          };

          Color0 = {
            Color = "156,160,176";
          };
          Color0Faint = {
            Color = "156,160,176";
          };
          Color0Intense = {
            Color = "156,160,176";
          };
          Color1 = {
            Color = "210,15,57";
          };
          Color1Faint = {
            Color = "210,15,57";
          };
          Color1Intense = {
            Color = "210,15,57";
          };
          Color2 = {
            Color = "64,160,43";
          };
          Color2Faint = {
            Color = "64,160,43";
          };
          Color2Intense = {
            Color = "64,160,43";
          };
          Color3 = {
            Color = "223,142,29";
          };
          Color3Faint = {
            Color = "223,142,29";
          };
          Color3Intense = {
            Color = "223,142,29";
          };
          Color4 = {
            Color = "30,102,245";
          };
          Color4Faint = {
            Color = "30,102,245";
          };
          Color4Intense = {
            Color = "30,102,245";
          };
          Color5 = {
            Color = "136,57,239";
          };
          Color5Faint = {
            Color = "136,57,239";
          };
          Color5Intense = {
            Color = "136,57,239";
          };
          Color6 = {
            Color = "4,165,229";
          };
          Color6Faint = {
            Color = "4,165,229";
          };
          Color6Intense = {
            Color = "4,165,229";
          };
          Color7 = {
            Color = "76,79,105";
          };
          Color7Faint = {
            Color = "76,79,105";
          };
          Color7Intense = {
            Color = "76,79,105";
          };
        };
      };

      profiles = {
        dark = {
          name = "dark";
          colorScheme = "catppuccin-mocha";
          font = {
            name = "JetBrainsMono Nerd Font";
            size = 9;
          };
          command = lib.getExe pkgs.zellij;
          extraConfig = {
            "Appearance" = {
              TabColor = "27,30,32,0";
              UseFontBrailleChararacters = false;
            };
            "Cursor Options" = {
              CursorShape = 1;
            };
            "Scrolling" = {
              HistoryMode = 2;
            };
            "Terminal Features" = {
              BlinkingCursorEnabled = true;
            };
            "Interaction Options" = {
              AutoCopySelectedText = true;
            };
          };
        };
        light = {
          name = "light";
          colorScheme = "catppuccin-latte";
          font = {
            name = "JetBrainsMono Nerd Font";
            size = 9;
          };
          command = lib.getExe pkgs.zellij;
          extraConfig = {
            "Appearance" = {
              TabColor = "27,30,32,0";
              UseFontBrailleChararacters = false;
            };
            "Cursor Options" = {
              CursorShape = 1;
            };
            "Scrolling" = {
              HistoryMode = 2;
            };
            "Terminal Features" = {
              BlinkingCursorEnabled = true;
            };
            "Interaction Options" = {
              AutoCopySelectedText = true;
            };
          };
        };
      };

      extraConfig = {
        "Desktop Entry" = {
          DefaultProfile = "dark.profile";
        };
        "MainWindow" = {
          MenuBar = "Disabled";
          State = "AAAA/wAAAAD9AAAAAQAAAAAAAAAAAAAAAPwCAAAAAvsAAAAiAFEAdQBpAGMAawBDAG8AbQBtAGEAbgBkAHMARABvAGMAawAAAAAA/////wAAAXwBAAAD+wAAABwAUwBTAEgATQBhAG4AYQBnAGUAcgBEAG8AYwBrAAAAAAD/////AAABFQEAAAMAAAeAAAAD8AAAAAQAAAAEAAAACAAAAAj8AAAAAQAAAAIAAAACAAAAFgBtAGEAaQBuAFQAbwBvAGwAQgBhAHIAAAAAAP////8AAAAAAAAAAAAAABwAcwBlAHMAcwBpAG8AbgBUAG8AbwBsAGIAYQByAAAAAAD/////AAAAAAAAAAA=";
        };
      };
    };
  };
}
