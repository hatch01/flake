{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    syncthing
    syncthingtray
    nextcloud-client
  ];
}
