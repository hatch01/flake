{mkSecret, ...}: {
  imports = [
    ../apps/proxmox.nix
  ];

  environment = {
    systemPackages = [
    ];
  };

  services.vscode-server = {
    enable = true;
    enableFHS = true;
  };

  age.secrets = mkSecret "server/cockpit_private_key" {
    mode = "600";
    root = true;
    path = "/root/.ssh/id_rsa";
  };

  systemd.user.services.auto-fix-vscode-server.enable = true;
}
