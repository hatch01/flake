{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;

  yaziExtraPackages = with pkgs; [
    bat
    btrfs-progs
    coreutils
    diffutils
    git
    lazygit
    nushell
    ouch
    rsync
    sudo-rs
    udisks
    util-linux
    wl-clipboard
  ];
  yaziPackage = pkgs.yazi.override { extraPackages = yaziExtraPackages; };
  timeTravel = pkgs.yaziPlugins.time-travel.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      substituteInPlace main.lua \
        --replace-fail \
          $'local function btrfs_uuids(cwd)\n    local cmd, _ = run_with_sudo("btrfs", { "subvolume", "show", cwd })' \
          $'local function btrfs_uuids(cwd)\n    local rootid_cmd, _ = run_with_sudo("btrfs", { "inspect-internal", "rootid", cwd })\n    if not rootid_cmd then\n        return nil\n    end\n    local rootid = trim(rootid_cmd.stdout)\n    local cmd, _ = run_with_sudo("btrfs", { "subvolume", "show", "-r", rootid, cwd })' \
        --replace-fail \
          'local path = mountpoint .. "/" .. name' \
          'local path = name == "<FS_TREE>" and mountpoint or mountpoint .. "/" .. name'
    '';
  });
  catppuccinMochaBlue = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/catppuccin/yazi/main/themes/mocha/catppuccin-mocha-blue.toml";
    sha256 = "sha256-DR84Cv8VaTTuHBrrLB5VBbIajNiSwgb5g4/AYhurGOk=";
  };
in
{
  options.yazi.enable = mkEnableOption "Enable yazi file manager";

  config = mkIf config.yazi.enable {
    programs.yazi = {
      enable = true;
      package = yaziPackage;
      initLua = pkgs.writeText "yazi-init.lua" ''
        require("git"):setup({ ["order"] = 1500 })
      '';
      plugins = {
        git = pkgs.yaziPlugins.git;
        sudo = pkgs.yaziPlugins.sudo;
        ouch = pkgs.yaziPlugins.ouch;
        diff = pkgs.yaziPlugins.diff;
        piper = pkgs.yaziPlugins.piper;
        mount = pkgs.yaziPlugins.mount;
        rsync = pkgs.yaziPlugins.rsync;
        lazygit = pkgs.yaziPlugins.lazygit;
        "time-travel" = timeTravel;
      };
      settings = {
        yazi.plugin = {
          prepend_fetchers = [
            {
              url = "*";
              run = "git";
              group = "git";
            }
            {
              url = "*/";
              run = "git";
              group = "git";
            }
          ];
          prepend_previewers = [
            {
              mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}";
              run = "ouch";
            }
            {
              url = "*.md";
              run = "piper -- bat -p --color=always --style=plain \"$1\"";
            }
          ];
        };
        theme = builtins.fromTOML (builtins.readFile catppuccinMochaBlue);
        keymap.mgr.prepend_keymap = [
          {
            on = [ "<C-d>" ];
            run = "plugin diff";
            desc = "Diff selected and hovered files";
          }
          {
            on = [ "C" ];
            run = "plugin ouch";
            desc = "Compress with ouch";
          }
          {
            on = [ "M" ];
            run = "plugin mount";
            desc = "Manage mounts";
          }
          {
            on = [ "R" ];
            run = "plugin rsync";
            desc = "Copy with rsync";
          }
          {
            on = [
              "g"
              "i"
            ];
            run = "plugin lazygit";
            desc = "Open lazygit";
          }
          {
            on = [
              "<A-s>"
              "p"
            ];
            run = "plugin sudo -- paste";
            desc = "Paste with sudo";
          }
          {
            on = [
              "<A-s>"
              "d"
            ];
            run = "plugin sudo -- remove";
            desc = "Remove with sudo";
          }
          {
            on = [
              "z"
              "h"
            ];
            run = "plugin time-travel prev";
            desc = "Go to previous snapshot";
          }
          {
            on = [
              "z"
              "l"
            ];
            run = "plugin time-travel next";
            desc = "Go to next snapshot";
          }
          {
            on = [
              "z"
              "e"
            ];
            run = "plugin time-travel exit";
            desc = "Exit snapshot browsing";
          }
        ];
      };
    };
  };
}
