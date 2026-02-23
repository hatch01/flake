{
  lib,
  config,
  base_domain_name,
  mkSecret,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    ;
in
{
  options = {
    headscale.enable = mkEnableOption "Enable service";
    headscale.port = mkOption {
      type = lib.types.int;
      default = 8092;
      description = "The port of the headscale";
    };
    headscale.domain = mkOption {
      type = lib.types.str;
      default = "headscale.${base_domain_name}";
      description = "The domain of the cockpit";
    };
  };

  config = mkIf config.headscale.enable {
    programs.bash.shellInit = ''
      eval "$(headscale completion bash)"
    '';

    hm.programs.zsh.initContent = ''
      eval "$(headscale completion zsh)"
    '';

    age.secrets = mkSecret "headscale_oidc" {
      owner = "headscale";
      group = "headscale";
    };

    services.headscale = {
      enable = true;
      port = config.headscale.port;
      settings = {
        server_url = "https://${config.headscale.domain}";

        dns = {
          base_domain = "onyx.lan";
          magic_dns = true;
          search_domains = [ config.headscale.domain ];
          nameservers.global = [
            "9.9.9.9"
          ];
        };

        policy.path =
          let
            mkRule = src: dst: ports: {
              action = "accept";
              inherit src;
              dst = map (d: "${d}:${lib.concatStringsSep "," (map toString ports)}") dst;
            };

            tulipe = "100.64.0.1";
            cyclamen = "100.64.0.2";
            lavande = "100.64.0.3";
            jonquille = "100.64.0.4";
            lilas = "100.64.0.5";
            homeassistant = "100.64.0.6";
            pimprenelles = "100.64.0.7";
            polytech = "100.64.0.8";
            papa = "100.64.0.9";
            lotus = "100.64.0.10";
            alexandre = "100.64.0.11";
          in
          pkgs.writers.writeJSON "policy.json" {
            acls = [
              # mkRule source destination ports
              (mkRule [ tulipe lavande lotus jonquille ] [ cyclamen jonquille lilas polytech ] [ 22 ]) # allow remote ssh on servers
              (mkRule [ tulipe lavande lotus ] [ lilas ] [ 80 443 config.cockpit.port ]) # allow access to pikvm (80,443) and cockpit admin panel
              (mkRule [ cyclamen ] [ lilas ] [ 443 ]) # pikvm monitoring
              (mkRule [ cyclamen ] [ "*" ] [ config.beszel.agent.port ]) # allow jonquille to monitor all devices
              (mkRule [ lavande jonquille lotus tulipe ] [ pimprenelles ] [ 22 8080 8081 8000 3306 5900 ]) # allow access to pimprenelles
              (mkRule [ jonquille lavande tulipe lotus papa ] [ homeassistant ] [ 22 8123 ]) # allow access to homeassistant
              (mkRule [ tulipe ] [ jonquille ] [ config.bitcoin.server.portRpc ]) # allow jonquille to use bitcoin controller
              (mkRule [ alexandre ] [ polytech ] [ 22 ])
            ];
          };

        oidc = {
          issuer = "https://${config.authelia.domain}";
          client_id = "headscale";
          client_secret_path = config.age.secrets.headscale_oidc.path;
          scope = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          pkce = {
            enabled = true;
            code_challenge_method = "S256";
          };
        };
      };
    };
  };
}
