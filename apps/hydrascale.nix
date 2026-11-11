{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    optional
    types
    ;

  cfg = config.hydrascale;
  settingsFormat = pkgs.formats.yaml { };

  # Ports of the host that the onyx tailnet publishes to its peers.
  publishedPorts = [
    "tcp/22"
  ]
  ++ optional config.cockpit.enable "tcp/${toString config.cockpit.port}";

  # Ports of the host that the onyx namespace may reach on the host itself.
  # When Headscale runs on this host, tailscaled inside the namespace reaches
  # it through nginx on the HTTPS port, so that port must be allowed locally.
  # That port is not published to the tailnet's peers.
  localPorts = publishedPorts ++ optional config.headscale.enable "tcp/443";

  defaultTailnets = [
    {
      id = "onyx";
      control_url = "https://${config.headscale.domain}";
      host_access = true;
      publish = publishedPorts;
    }
    {
      id = "tailscale";
      host_access = true;
    }
  ];

  tailnets = defaultTailnets ++ cfg.extraTailnets;

  # The host may reach the peers of every tailnet.
  hostRules = map (tailnet: {
    from = "host";
    to = tailnet.id;
  }) tailnets;

  # Every tailnet may reach the public internet through the host.
  internetRules = map (tailnet: {
    from = tailnet.id;
    to = "internet";
  }) tailnets;
in
{
  options.hydrascale = {
    enable = mkEnableOption "Hydrascale, a daemon that runs several Tailscale tailnets on one host";

    extraTailnets = mkOption {
      type = types.listOf settingsFormat.type;
      default = [ ];
      description = "Extra tailnets to add to Hydrascale configuration.";
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;
        options.version = mkOption {
          type = types.int;
          default = 2;
          description = "Schema version of the configuration file.";
        };
      };
      default = {
        version = 2;

        inherit tailnets;

        # Hydrascale serves an unauthenticated web console on 127.0.0.1:9443
        # by default. This host is managed remotely, so keep it closed.
        console.enabled = false;

        access = {
          mode = "enforce";
          rules =
            hostRules
            ++ internetRules
            ++ [
              {
                from = "onyx";
                to = "host";
                ports = localPorts;
              }
            ];
        };
      };
      description = ''
        Contents of {file}`/etc/hydrascale/config.yaml`. See the
        [configuration reference](https://crank-git.github.io/Hydrascale/reference/configuration/)
        for the available keys.

        The default joins the `onyx` Headscale tailnet and Tailscale's hosted
        control server, and gives the host access to both. The `onyx` tailnet
        publishes SSH plus Cockpit when it is enabled; the `tailscale` tailnet
        publishes no port. Override this to use other tailnets.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.hydrascale = {
      enable = true;
      inherit (cfg) settings;
    };

    # Hydrascale owns the tailnet connections on the host.
    services.tailscale.enable = lib.mkForce false;
  };
}
