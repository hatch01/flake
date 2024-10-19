{
  inputs,
  pkgs,
  ...
}: {
  environment = {
    systemPackages = with pkgs; [
    ];
  };

  services.vscode-server = {
    enable = true;
    enableFHS = true;
  };

  systemd.user.services.auto-fix-vscode-server.enable = true;
}
