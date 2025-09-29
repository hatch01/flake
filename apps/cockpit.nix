{
  lib,
  config,
  base_domain_name,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf;
in
{
  options = {
    cockpit.enable = mkEnableOption "Enable cockpit";
    cockpit.port = mkOption {
      type = lib.types.int;
      default = 9090;
      description = "The port of the cockpit";
    };
    cockpit.domain = mkOption {
      type = lib.types.str;
      default = "cockpit.${base_domain_name}";
      description = "The domain of the cockpit";
    };
  };

  config = mkIf config.cockpit.enable {
    virtualisation = {
      libvirtd.enable = true;
    };

    users = {
      users.libvirtdbus = {
        isSystemUser = true;
        group = "libvirtdbus";
        description = "Libvirt D-Bus bridge";
      };
      groups.libvirtdbus = { };
    };

    systemd.packages = [ pkgs.libvirt-dbus ];

    environment.systemPackages = with pkgs; [
      libvirt-dbus
      virt-manager
      cockpit-files
      cockpit-machines
      cockpit-podman
    ];

    services.cockpit = {
      enable = true;
      port = config.cockpit.port;
      allowed-origins = [
        "https://${config.cockpit.domain}"
        "wss://${config.cockpit.domain}"
      ];
      settings = {
        "WebService" = {
          ProtocolHeader = "X-Forwarded-Proto";
          ForwardedForHeader = "X-Forwarded-For";
        };
        #   "basic" = {
        #     "action" = "none";
        #   };
      };
    };
  };
}
