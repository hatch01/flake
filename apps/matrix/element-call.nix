{
  config,
  lib,
  mkSecret,
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
    matrix.elementCall = {
      enable = mkEnableOption "enable Element Call with LiveKit backend";
      livekitPort = mkOption {
        type = types.int;
        default = 7880;
        description = "Port for LiveKit SFU WebSocket connection";
      };
      jwtServicePort = mkOption {
        type = types.int;
        default = 8093;
        description = "Port for lk-jwt-service";
      };
    };
  };

  config = mkIf config.matrix.elementCall.enable {
    assertions = [
      {
        assertion = config.matrix.enable;
        message = "Matrix must be enabled to use Element Call";
      }
    ];

    age.secrets = mkSecret "livekit_api_key" { };

    services.livekit = {
      enable = true;
      keyFile = config.age.secrets.livekit_api_key.path;
      openFirewall = true;

      redis = {
        createLocally = true;
        port = 6380;
      };

      settings = {
        port = config.matrix.elementCall.livekitPort;

        logging = {
          level = "debug";
        };

        rtc = {
          use_external_ip = true;
          port_range_start = 50000;
          port_range_end = 50200;
        };

        redis = {
          address = "${config.services.livekit.redis.host}:${toString config.services.livekit.redis.port}";
        };
      };
    };

    services.lk-jwt-service = {
      enable = true;
      port = config.matrix.elementCall.jwtServicePort;
      keyFile = config.age.secrets.livekit_api_key.path;
      livekitUrl = "wss://${config.matrix.domain}/livekit/sfu";
    };

    environment.persistence."/persistent".directories = [ "/var/lib/livekit" ];
  };
}
