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
          "konsole/dark.profile" = {
            "Appearance" = {
              "ColorScheme".value = "Breeze";
              "Font".value = "JetBrainsMono Nerd Font,9,-1,5,50,0,0,0,0,0";
              "TabColor".value = "27,30,32,0";
            };

            "Cursor Options"."CursorShape".value = 1;

            "General" = {
              "Command".value = "${lib.getExe pkgs.zsh}";
              "Name".value = "dark";
            };
            "Scrolling"."HistoryMode".value = 2;

            "Terminal Features"."BlinkingCursorEnabled".value = true;
            "Interaction Options"."AutoCopySelectedText".value = true;
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
        };
      };
    };
  };
}
