{pkgs, ...}: {
  imports = [
    ./editors.nix
  ];

  environment.systemPackages = with pkgs; [
    insomnia
    android-tools
    scrcpy
    minikube
    httpy-cli
    jq
    openjdk19
  ];
}
