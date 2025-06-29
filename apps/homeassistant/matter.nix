{
  lib,
  config,
  base_domain_name,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    matter = {
      enable = mkEnableOption "enable matter";
      port = mkOption {
        type = types.int;
        default = 5580;
        description = "The port on which matter will listen";
      };
    };
  };

  config = mkIf config.matter.enable {
    services.matter-server = {
      enable = true;
      port = config.matter.port;
    };
  };
}
