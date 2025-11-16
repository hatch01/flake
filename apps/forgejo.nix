{
  config,
  lib,
  pkgs,
  base_domain_name,
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
    forgejo = {
      enable = mkEnableOption "enable ForgeJo";
      domain = mkOption {
        type = types.str;
        default = "forge.${base_domain_name}";
        description = "The domain of the ForgeJo instance";
      };
      port = mkOption {
        type = types.int;
        default = 3004;
        description = "The port to listen on";
      };
    };
  };

  imports = [ ];

  config = mkIf config.forgejo.enable {
    age.secrets = mkSecret "forgejo_runner_token" { };

    # mkforce to fix conflict with other services
    services.openssh.settings.AcceptEnv = lib.mkForce "GIT_PROTOCOL LANG LC_*";

    services = {
      forgejo = {
        enable = true;
        package = pkgs.forgejo; # forgejo-lts by default

        database = {
          type = "postgres";
          createDatabase = true;
        };
        # Enable support for Git Large File Storage
        lfs.enable = true;
        settings = {
          DEFAULT.APP_NAME = "Onyx's forge";

          server = {
            DOMAIN = config.forgejo.domain;
            # You need to specify this to remove the port from URLs in the web UI.
            ROOT_URL = "https://${config.forgejo.domain}/";
            HTTP_PORT = config.forgejo.port;
            START_SSH_SERVER = false;
            BUILTIN_SSH_SERVER_USER = "forgejo";
          };

          oauth2 = {
            # providers are configured in the admin panel
            ENABLED = true;
          };

          authelia = {
            ENABLE_OPENID_SIGNIN = true;
            ENABLE_OPENID_SIGNUP = true;
          };

          service = {
            DISABLE_REGISTRATION = false;
            ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
            SHOW_REGISTRATION_BUTTON = false;
            ENABLE_INTERNAL_SIGNIN = false;
            ENABLE_BASIC_AUTHENTICATION = false;
          };

          # Add support for actions, based on act: https://github.com/nektos/act
          actions = {
            ENABLED = true;
            DEFAULT_ACTIONS_URL = "https://${config.forgejo.domain}";
          };
          # Sending emails is completely optional
          # You can send a test email from the web UI at:
          # Profile Picture > Site Administration > Configuration >  Mailer Configuration
          mailer = {
            ENABLED = true;
            SMTP_ADDR = "smtp.free.fr";
            FROM = "noreply@${config.forgejo.domain}";
            USER = "eymeric.monitoring";
          };
        };
        secrets.mailer.PASSWD = config.age.secrets."server/smtpPassword".path;
        stateDir = "/storage/forgejo";
      };

      gitea-actions-runner = {
        package = pkgs.forgejo-runner;
        instances.onyx = {
          enable = true;
          name = "onyx-runner";
          url = "https://${config.forgejo.domain}/";
          tokenFile = config.age.secrets.forgejo_runner_token.path;
          labels = [
            "docker:docker://node:24-alpine"
            "alpine-latest:docker://node:24-alpine"
            "ubuntu-latest:docker://catthehacker/ubuntu:act-latest"
            "native:host"
          ];

          settings = {
            log.level = "info";
            container.network = "host";
            runner = {
              capacity = 4;
              timeout = "5h";
              insecure = false;
            };
          };
        };
      };
    };

    nix.settings = {
      trusted-users = [ "gitea-runner" ];
    };
    # Takes the form of "gitea-runner-<instance>"
    systemd.services.gitea-runner-onyx = {
      # Prevents Forgejo runner deployments
      # from being restarted on a system switch,
      # thus breaking a deployment.
      # You'll have to restart the runner manually
      # or reboot the system after a deployment!
      restartIfChanged = false;

      path = with pkgs; [ nix openssh ];

      serviceConfig = {
        MemoryMax = "10G";
        CPUQuota = "80%";
        Nice = 10;
      };
    };
  };
}
