{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    espanso.enable = mkEnableOption "espanso";
  };

  config = mkIf config.espanso.enable {
    services.espanso = {
      enable = true;
      # TODO update this to the new config format probably using hm
      # package = pkgs.espanso-wayland;
      # configs = {
      #   default = {
      #     toggle_key = "RIGHT_SHIFT";
      #     keyboard_layout = {
      #       layout = "fr";
      #     };
      #     search_shortcut = "SHIFT+SPACE";
      #   };
      # };
      #   matches = {
      #     base = {
      #       matches = [
      #         {
      #           trigger = ":date";
      #           replace = "{{mydate}}";
      #           vars = [
      #             {
      #               name = "mydate";
      #               type = "date";
      #               params = {
      #                 format = "%m/%d/%Y";
      #               };
      #             }
      #           ];
      #         }
      #         {
      #           trigger = ":shell";
      #           replace = "{{output}}";
      #           vars = [
      #             {
      #               name = "output";
      #               type = "shell";
      #               params = {
      #                 cmd = "echo 'Hello from your shell'";
      #               };
      #             }
      #           ];
      #         }
      #         {
      #           trigger = ":ip";
      #           replace = "{{ip}}";
      #           vars = [
      #             {
      #               name = "ip";
      #               type = "shell";
      #               params = {
      #                 cmd = "hostname -I | awk '{print $1}'";
      #               };
      #             }
      #           ];
      #         }
      #       ];
      #     };
      #   };
    };
  };
}
