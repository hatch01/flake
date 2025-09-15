{
  config,
  lib,
  pkgs,
  base_domain_name,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;

  interval = "30s";
  alerts = [ { type = "email"; } ];

  mkGatusCheck =
    {
      name,
      url,
      conditions ? [ ],
      group ? "onyx",
    }:
    {
      inherit interval alerts group;
      name = name;
      url = url;
      conditions = [
        "[STATUS] == 200"
        "[RESPONSE_TIME] < 10000"
      ]
      ++ conditions;
    };
in
{
  options = {
    gatus = {
      enable = mkEnableOption "enable gatus";
      domain = mkOption {
        type = types.str;
        default = "gatus.${base_domain_name}";
        description = "The domain of the gatus instance";
      };
      port = mkOption {
        type = types.int;
        default = 8087;
        description = "The port to listen on";
      };
    };
  };

  imports = [ ];

  config = mkIf config.gatus.enable {
    services.postgresql.enable = true;
    services.gatus = {
      enable = true;
      environmentFile = config.age.secrets."server/smtpPasswordEnv".path;

      # convert to yaml code stollen in nixpkgs repo
      configFile = pkgs.callPackage (
        {
          runCommand,
          remarshal_0_17,
        }:
        runCommand "gatus.yaml"
          {
            nativeBuildInputs = [ remarshal_0_17 ];
            value = builtins.toJSON {
              web.port = config.gatus.port;
              storage = {
                type = "postgres";
                path = "postgresql:///gatus?host=/run/postgresql";
              };
              endpoints = [
                (mkGatusCheck {
                  name = "authelia";
                  url = "https://${config.authelia.domain}/api/health";
                  conditions = [ "[BODY].status == OK" ];
                })
                (mkGatusCheck {
                  name = "nextcloud";
                  url = "https://${config.nextcloud.domain}/status.php";
                  conditions = [
                    "[BODY].installed == true"
                    "[BODY].maintenance == false"
                    "[BODY].needsDbUpgrade == false"
                  ];
                })
                (mkGatusCheck {
                  name = "forge";
                  url = "https://${config.forgejo.domain}/api/healthz";
                  conditions = [ "[BODY].status == pass" ];
                })
                (mkGatusCheck {
                  name = "homepage";
                  url = "https://${config.homepage.domain}";
                })
                (mkGatusCheck {
                  name = "portfolio";
                  url = "https://${config.portfolio.domain}";
                  group = "clement";
                })
                (mkGatusCheck {
                  name = "speedtest";
                  url = "https://${config.librespeed.domain}/";
                })
                (mkGatusCheck {
                  name = "matrix synapse health";
                  url = "https://${config.matrix.domain}/health";
                  conditions = [
                    "[BODY] == OK"
                  ];
                })
                (mkGatusCheck {
                  name = "home_assistant";
                  url = "https://${config.home_assistant.domain}/manifest.json";
                })
                (mkGatusCheck {
                  name = "nodered";
                  url = "https://${config.nodered.domain}/health";
                })
                (mkGatusCheck {
                  name = "grafana";
                  url = "https://${config.influxdb.grafana.domain}/api/health";
                  conditions = [
                    "[BODY].database == ok"
                  ];
                })
                (mkGatusCheck {
                  name = "adguard";
                  url = "https://${config.adguard.domain}/";
                })
                (mkGatusCheck {
                  name = "polypresence back";
                  url = "https://polypresence.fr/api/status";
                  conditions = [
                    "[BODY].status == ok"
                  ];
                  group = "polypresence";
                })
                (mkGatusCheck {
                  name = "polypresence front";
                  url = "https://polypresence.fr/";
                  group = "polypresence";
                })

                (mkGatusCheck {
                  name = "pimprenelles";
                  url = "https://www.pimprenelles.bio";
                })
              ];
            };
            passAsFile = [ "value" ];
            preferLocalBuild = true;
          }
          ''
            json2yaml "$valuePath" "$out"
              echo "
            alerting:
              email:
                client:
                  insecure: true
                default-alert:
                  send-on-resolved: true
                from: Gatus <gatus@free.fr>
                host: smtp.free.fr
                password: \"\$SMTP_PASSWORD\"
                port: 587
                to: eymeric.monitoring@free.fr
                username: eymeric.monitoring
                overrides:
                  - group: clement
                    to: clement.reniers00@gmail.com" >> "$out"
          ''
      ) { };
    };

    postgres.initialScripts = [
      ''
        CREATE ROLE "gatus" LOGIN;
        CREATE DATABASE "gatus" WITH OWNER "gatus";
      ''
    ];
  };
}
