{...}: {
  disabledModules = ["services/matrix/mautrix-discord.nix"];
  imports = [
    ./mautrix-discord.nix
  ];
}
