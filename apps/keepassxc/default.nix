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
    keepassxc.enable = mkEnableOption "keepassxc";
    keepassxc.autostart = mkEnableOption "keepassxc autostart";
  };

  config = mkIf config.keepassxc.enable {
    environment.systemPackages = with pkgs; [
      keepassxc
    ];

    hm = {
      programs.plasma = {
        configFile = {
          # "kwalletrc"."org.freedesktop.secrets"."apiEnabled".value = false;

          # keepassxc
          "keepassxc/keepassxc.ini"."SSHAgent"."Enabled".value = false;
          "keepassxc/keepassxc.ini"."FdoSecrets"."Enabled".value = true;
          "keepassxc/keepassxc.ini"."General"."HideWindowOnCopy".value = true;
          "keepassxc/keepassxc.ini"."Browser"."Enabled".value = true;
          "keepassxc/keepassxc.ini"."PasswordGenerator"."SpecialChars".value = true;
        };
      };

      # autostart keepassxc
      home.file.".config/autostart/org.keepassxc.KeePassXC.desktop" =
        lib.mkIf config.keepassxc.autostart
          {
            source = ./org.keepassxc.KeePassXC.desktop;
            force = true;
          };
    };
  };
}
