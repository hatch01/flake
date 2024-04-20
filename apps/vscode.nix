{config, pkgs, ...}:
{
  home.packages = with pkgs; [
    nil
  ];
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;

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
    ];

    userSettings = {
      "cmake.configureOnOpen" = true;
      "editor.fontFamily" = "'Iosevka Nerd Font', monospace";
      "editor.fontSize" = 16;
      "editor.fontLigatures" = true;
      "editor.formatOnSave" = true;
      "editor.inlineSuggest.enabled" = true;
      "files.autoSave" = "afterDelay";
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
      "rust-analyzer.check.command" = "clippy";
      "terminal.integrated.fontFamily" = "JetBrainsMono Nerd Font";
      "workbench.colorTheme" = "Catppuccin Mocha";
      "errorLens.messageBackgroundMode" = "message";
      "dart.checkForSdkUpdates" =  false;
      "cmake.showOptionsMovedNotification" = false;
      "rust-analyzer.inlayHints.typeHints.enable" = false;
      "git.openRepositoryInParentFolders" = true;

      # fix for segfault on hyprland
      "window.titleBarStyle" = "custom";
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
}
