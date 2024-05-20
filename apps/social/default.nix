{pkgs, ...}: {
  imports = [
    ./vesktop
  ];

  environment.systemPackages = with pkgs; [
    signal-desktop
    beeper
    zapzap
    skypeforlinux
  ];
}
