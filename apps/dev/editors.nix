{pkgs, ...}: {
  imports = [
    ./vscode.nix
  ];

  environment.systemPackages = with pkgs; [
    jetbrains.idea-ultimate
    jetbrains.pycharm-professional
    jetbrains.clion
    jetbrains.rust-rover
    jetbrains.phpstorm
    #android-studio
    neovide
    kate
  ];
}
