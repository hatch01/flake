{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    konsole.enable = mkEnableOption "Enable Konsole";
  };

  config = mkIf config.konsole.enable {
    environment.systemPackages = with pkgs; [kdePackages.konsole];

    hm = {
      programs.plasma = {
        configFile = {
          "konsolerc" = {
            "Desktop Entry"."DefaultProfile".value = "dark.profile";
            "MainWindow" = {
              "MenuBar".value = "Disabled";
              "State".value = "AAAA/wAAAAD9AAAAAQAAAAAAAAAAAAAAAPwCAAAAAvsAAAAiAFEAdQBpAGMAawBDAG8AbQBtAGEAbgBkAHMARABvAGMAawAAAAAA/////wAAAXwBAAAD+wAAABwAUwBTAEgATQBhAG4AYQBnAGUAcgBEAG8AYwBrAAAAAAD/////AAABFQEAAAMAAAeAAAAD8AAAAAQAAAAEAAAACAAAAAj8AAAAAQAAAAIAAAACAAAAFgBtAGEAaQBuAFQAbwBvAGwAQgBhAHIAAAAAAP////8AAAAAAAAAAAAAABwAcwBlAHMAcwBpAG8AbgBUAG8AbwBsAGIAYQByAAAAAAD/////AAAAAAAAAAA=";
            };
          };
        };

        dataFile = {
          "konsole/light.profile" = {
            "Appearance" = {
              "ColorScheme".value = "BlackOnWhite";
              "Font".value = "JetBrainsMono Nerd Font,9,-1,5,50,0,0,0,0,0";
              "TabColor".value = "27,30,32,0";
            };

            "Cursor Options"."CursorShape".value = 1;

            "General" = {
              "Command".value = "${lib.getExe pkgs.zsh}";
              "Name".value = "light";
            };
            "Scrolling"."HistoryMode".value = 2;

            "Terminal Features"."BlinkingCursorEnabled".value = true;
            "Interaction Options"."AutoCopySelectedText".value = true;
          };
          "konsole/dark.profile" = {
            "Appearance" = {
              "ColorScheme".value = "Breeze";
              "Font".value = "JetBrainsMono Nerd Font,9,-1,5,50,0,0,0,0,0";
              "TabColor".value = "27,30,32,0";
            };

            "Cursor Options"."CursorShape".value = 1;

            "General" = {
              "Command".value = "${lib.getExe pkgs.zsh}";
              "Name".value = "light";
            };
            "Scrolling"."HistoryMode".value = 2;

            "Terminal Features"."BlinkingCursorEnabled".value = true;
            "Interaction Options"."AutoCopySelectedText".value = true;
          };
        };
      };
      # this would be the new way to configure konsole but it's not working
      # programs.konsole = {
      #   defaultProfile = "dark";
      #   profiles = [
      #     {
      #       name = "daark";
      #       colorScheme = "Breeze";
      #       font = {
      #         name = "JetBrainsMono Nerd Font";
      #         size = 9;
      #       };
      #       "Cursor Options"."CursorShape".value = 1;
      #       command = lib.getExe pkgs.zsh;
      #     }
      #     {
      #       name = "light ";
      #       colorScheme = "BlackOnWhite";
      #       font = {
      #         name = "JetBrainsMono Nerd Font";
      #         size = 9;
      #       };
      #       command = lib.getExe pkgs.zsh;
      #     }
      #   ];
      #   extraConfig = {
      #     "konsolerc" = {
      #       "MainWindow" = {
      #         "MenuBar".value = "Disabled";
      #         # a base64 encoded string of the state of the window
      #         "State".value = "AAAA/wAAAAD9AAAAAQAAAAAAAAAAAAAAAPwCAAAAAvsAAAAiAFEAdQBpAGMAawBDAG8AbQBtAGEAbgBkAHMARABvAGMAawAAAAAA/////wAAAXwBAAAD+wAAABwAUwBTAEgATQBhAG4AYQBnAGUAcgBEAG8AYwBrAAAAAAD/////AAABFQEAAAMAAAeAAAAD8AAAAAQAAAAEAAAACAAAAAj8AAAAAQAAAAIAAAACAAAAFgBtAGEAaQBuAFQAbwBvAGwAQgBhAHIAAAAAAP////8AAAAAAAAAAAAAABwAcwBlAHMAcwBpAG8AbgBUAG8AbwBsAGIAYQByAAAAAAD/////AAAAAAAAAAA=";
      #       };
      #     };
      #   };
      # };
    };
  };
}
