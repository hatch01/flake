{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
in
{
  options = {
    sslh = {
      enable = mkEnableOption "enable sslh";
      port = mkOption {
        type = types.int;
        default = 443;
        description = "The port on which sslh will listen";
      };
    };
  };

  config = mkIf config.sslh.enable {
    services.nginx = mkIf config.nginx.enable {
      defaultListen = [
        {
          addr = "127.0.0.1";
          port = 4443;
          ssl = true;
        }
        {
          addr = "0.0.0.0";
          port = 80;
          ssl = false;
        }
      ];
    };
    services.sslh = {
      enable = true;
      listenAddresses = [
        "0.0.0.0"
        "[::]"
      ];
      port = config.sslh.port;
      settings = {
        timeout = 1000;
        transparent = true;
        protocols = [
          {
            name = "ssh";
            host = "localhost";
            port = "22";
          }
          {
            name = "tls";
            host = "localhost";
            port = "4443";
          }
        ];
      };
    };
  };
}
