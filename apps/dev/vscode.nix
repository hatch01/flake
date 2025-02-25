{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    vscode.enable = mkEnableOption "vscode";
  };
  config = {
    hm = mkIf config.vscode.enable {
      home.sessionVariables.NIXOS_OZONE_WL = "1";
      programs.vscode = {
        enable = true;
        enableUpdateCheck = false;
        profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            # style
            # bierner.markdown-preview-github-styles
            catppuccin.catppuccin-vsc

            # git
            donjayamanne.githistory
            eamodio.gitlens

            # misc
            github.copilot
            github.copilot-chat
            github.vscode-github-actions
            github.vscode-pull-request-github
            editorconfig.editorconfig
            mkhl.direnv
            usernamehw.errorlens
            wakatime.vscode-wakatime

            # nix
            jnoortheen.nix-ide

            # python
            # donjayamanne.python-environment-manager
            ms-python.python
            ms-python.vscode-pylance

            #flutter
            dart-code.flutter
            dart-code.dart-code

            #cpp
            ms-vscode.makefile-tools
            ms-vscode.cpptools

            #rust
            rust-lang.rust-analyzer
            tamasfe.even-better-toml
          ];

          userSettings = {
            "cmake.configureOnOpen" = true;
            "editor.fontFamily" = "'Iosevka Nerd Font', monospace";
            "editor.fontSize" = 16;
            "editor.fontLigatures" = true;
            "editor.formatOnSave" = true;
            "editor.inlineSuggest.enabled" = true;
            "files.autoSave" = "afterDelay";
            "rust-analyzer.check.command" = "clippy";
            "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
            "workbench.colorTheme" = "Catppuccin Mocha";
            "errorLens.messageBackgroundMode" = "message";
            "dart.checkForSdkUpdates" = false;
            "cmake.showOptionsMovedNotification" = false;
            "rust-analyzer.inlayHints.typeHints.enable" = false;
            "git.openRepositoryInParentFolders" = true;
            "editor.cursorSmoothCaretAnimation" = "on";
            "editor.smoothScrolling" = true;
            "workbench.list.smoothScrolling" = true;
            "terminal.integrated.smoothScrolling" = true;
            # "platformio-ide.useBuiltinPIOCore" = false;

            # fix for segfault on hyprland
            "window.titleBarStyle" = "custom";

            #nix setup
            "nix.serverPath" = "nixd";
            "nix.enableLanguageServer" = true;
            "nix.serverSettings" = {
              "nixd" = {
                "formatting" = {
                  "command" = ["alejandra"]; # // or nixfmt or nixpkgs-fmt
                };
                "options" = {
                  nixpkgs.expr = "(builtins.getFlake \"/home/eymeric/tmp/flake\").inputs.nixpkgs";
                  nixpkgs-unstable.expr = "(builtins.getFlake \"/home/eymeric/tmp/flake\").inputs.nixpkgs-unstable";
                  nixpkgs-stable.expr = "(builtins.getFlake \"/home/eymeric/tmp/flake\").inputs.nixpkgs-stable";
                  tulipe.expr = "(builtins.getFlake \"/home/eymeric/tmp/flake\").nixosConfigurations.tulipe.options";
                  jonquille.expr = "(builtins.getFlake \"/home/eymeric/tmp/flake\").nixosConfigurations.jonquille.options";
                  lavande.expr = "(builtins.getFlake \"/home/eymeric/tmp/flake\").nixosConfigurations.lavande.options";
                };
              };
            };
            "nixpkgs" = {
              "expr" = "import <nixpkgs> { }";
            };
            "formatting" = {
              "command" = ["alejandra"]; # or nixfmt or nixpkgs-fmt
            };

            # vue
            "[vue]" = {
              "editor.defaultFormatter" = "Vue.volar";
            };

            "[json]" = {
              "editor.defaultFormatter" = "vscode.json-language-features";
            };

            "[svelte]" = {
              "editor.defaultFormatter" = "svelte.svelte-vscode";
            };

            "github.copilot.enable" = {
              "*" = true;
              "markdown" = true;
            };

            "debug.allowBreakpointsEverywhere" = true;
            "C_Cpp.debugShortcut" = true;
            "svelte.enable-ts-plugin" = true;
          };
          keybindings = [
            {
              key = "ctrl+c";
              command = "workbench.action.terminal.copySelection";
              when = "terminalTextSelectedInFocused || terminalFocus && terminalHasBeenCreated && terminalTextSelected || terminalFocus && terminalProcessSupported && terminalTextSelected || terminalFocus && terminalTextSelected && terminalTextSelectedInFocused || terminalHasBeenCreated && terminalTextSelected && terminalTextSelectedInFocused || terminalProcessSupported && terminalTextSelected && terminalTextSelectedInFocused";
            }
            {
              key = "ctrl+v";
              command = "workbench.action.terminal.paste";
              when = "terminalFocus && terminalHasBeenCreated || terminalFocus && terminalProcessSupported";
            }
          ];
        };
      };
    };
  };
}
