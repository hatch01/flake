{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    gatus = {
      enable = mkEnableOption "enable gatus";
      domain = mkOption {
        type = types.str;
        default = "gatus.${config.networking.domain}";
        description = "The domain of the gatus instance";
      };
      port = mkOption {
        type = types.int;
        default = 8087;
        description = "The port to listen on";
      };
    };
  };

  imports = [];

  config = mkIf config.gatus.enable {
    services.gatus = {
      enable = true;
      environmentFile = config.age.secrets."server/smtpPasswordEnv".path;

      configFile = pkgs.callPackage ({
        runCommand,
        remarshal_0_17,
      }:
        runCommand "gatus.yaml" {
          nativeBuildInputs = [remarshal_0_17];
          value = builtins.toJSON {
            web.port = config.gatus.port;
            endpoints = [
              {
                name = "authelia";
                url = "https://${config.authelia.domain}/api/health";
                interval = "5m";
                conditions = [
                  "[STATUS] == 200"
                  "[BODY].status == OK"
                  "[RESPONSE_TIME] < 300"
                ];
                alerts = [{type = "email";}];
              }
              {
                name = "nextcloud";
                url = "https://${config.nextcloud.domain}/status.php";
                interval = "5m";
                conditions = [
                  "[STATUS] == 200"
                  "[BODY].installed == true"
                  "[BODY].maintenance == false"
                  "[BODY].needsDbUpgrade == false"
                  "[RESPONSE_TIME] < 300"
                ];
                alerts = [{type = "email";}];
              }
              {
                name = "forge";
                url = "https://${config.forgejo.domain}/api/healthz";
                interval = "5m";
                conditions = [
                  "[STATUS] == 200"
                  "[BODY].status == pass"
                  "[RESPONSE_TIME] < 300"
                ];
                alerts = [{type = "email";}];
              }
              {
                name = "speedtest";
                url = "https://${config.librespeed.domain}/";
                interval = "5m";
                conditions = [
                  "[STATUS] == 200"
                  "[RESPONSE_TIME] < 300"
                ];
                alerts = [{type = "email";}];
              }
              {
                name = "matrix synapse health";
                url = "https://${config.matrix.domain}/health";
                interval = "5m";
                conditions = [
                  "[STATUS] == 200"
                  "[BODY] == OK"
                  "[RESPONSE_TIME] < 300"
                ];
                alerts = [{type = "email";}];
              }
              {
                name = "homeassistant";
                url = "https://${config.homeassistant.domain}/manifest.json";
                interval = "5m";
                conditions = [
                  "[STATUS] == 200"
                  "[RESPONSE_TIME] < 300"
                ];
                alerts = [{type = "email";}];
              }
              {
                name = "nodered";
                url = "https://${config.nodered.domain}/health";
                interval = "5m";
                conditions = [
                  "[STATUS] == 200"
                  "[RESPONSE_TIME] < 300"
                ];
                alerts = [{type = "email";}];
              }
              {
                name = "adguard";
                url = "109.26.63.39";
                dns = {
                  query-name = "onyx.ovh";
                  query-type = "A";
                };
                interval = "5m";
                conditions = [
                  "[BODY] == 109.26.63.39"
                  "[DNS_RCODE] == NOERROR"
                ];
                alerts = [{type = "email";}];
              }
              {
                name = "grafana";
                url = "https://${config.influxdb.grafana.domain}/api/health";
                interval = "5m";
                conditions = [
                  "[STATUS] == 200"
                  "[BODY].database == ok"
                  "[RESPONSE_TIME] < 300"
                ];
                alerts = [{type = "email";}];
              }
            ];
          };
          passAsFile = ["value"];
          preferLocalBuild = true;
        } ''          json2yaml "$valuePath" "$out"
            echo "
          alerting:
            email:
              client:
                insecure: true
              default-alert:
                failure-threshold: 5
                send-on-resolved: true
                success-threshold: 5
              from: gatus@free.fr
              host: smtp.free.fr
              password: \"\$SMTP_PASSWORD\"
              port: 587
              to: eymeric.monitoring@free.fr
              username: eymeric.monitoring" >> "$out"
        '') {};
    };
  };
}
