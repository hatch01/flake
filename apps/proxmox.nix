{
  lib,
  config,
  inputs,
  system,
  base_domain_name,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
in
{
  imports = [ inputs.proxmox-nixos.nixosModules.proxmox-ve ];

  options = {
    proxmox = {
      enable = mkEnableOption "Enable Proxmox";
      domain = mkOption {
        type = types.str;
        default = "proxmox.${base_domain_name}";
        description = "The domain name for the Proxmox server";
      };
      port = mkOption {
        type = types.int;
        default = 8006;
        description = "The port for the Proxmox server";
      };
    };
  };

  config = mkIf config.proxmox.enable {
    systemd.services.pveproxy.environment = {
      PROXY_REAL_IP_HEADER = "X-Forwarded-For";
      PROXY_REAL_IP_ALLOW_FROM = "127.0.0.1,::1";
    };

    # enable proxmox
    services.proxmox-ve = {
      enable = true;
      ipAddress = "192.168.0.1";
    };
    nixpkgs.overlays = [
      inputs.proxmox-nixos.overlays.${system}
    ];

    # networking.bridges.vmbr0.interfaces = ["ens18"];
    # networking.interfaces.vmbr0.useDHCP = lib.mkDefault true;

    networking.bridges.vmbr0.interfaces = [ "eno1" ];
    networking.interfaces.vmbr0.useDHCP = lib.mkDefault true;

    programs.fuse.userAllowOther = true;

    environment.persistence."/persistent".directories = [
      "/var/lib/vz"
      "/var/lib/pve-cluster"
      "/var/lib/pve-firewall"
      "/var/lib/pve-manager"
      # {
      # directory = "/etc/pve";
      # user = "root";
      # group = "www-data";
      # }
    ];
  };
}
