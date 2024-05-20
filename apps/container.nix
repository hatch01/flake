{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      docker-compose
      podman-compose
      distrobox
    ];
  };

  virtualisation = {
    docker = {
      enable = true;
      storageDriver = "btrfs";
      enableNvidia = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
