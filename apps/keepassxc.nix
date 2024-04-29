{
  config,
  pkgs,
  ...
}: {
  programs.plasma = {
    configFile = {
      "kwalletrc"."org.freedesktop.secrets"."apiEnabled".value = false;

      # keepassxc
      "keepassxc/keepassxc.ini"."SSHAgent"."Enabled".value = true;
      "keepassxc/keepassxc.ini"."FdoSecrets"."Enabled".value = true;
      "keepassxc/keepassxc.ini"."General"."HideWindowOnCopy".value = true;
      "keepassxc/keepassxc.ini"."Browser"."Enabled".value = true;
      "keepassxc/keepassxc.ini"."PasswordGenerator"."SpecialChars".value = true;
    };
  };
}
