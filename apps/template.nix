{
  lib,
  config,
  base_domain_name,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    optionals
    ;
in
{
  options = {
    service.enable = mkEnableOption "Enable service";
    service.port = mkOption {
      type = lib.types.int;
      default = 1234;
      description = "The port of the service";
    };
    service.domain = mkOption {
      type = lib.types.str;
      default = "service.${base_domain_name}";
      description = "The domain of the cockpit";
    };
  };

  config = mkIf config.service.enable {
  };
}
