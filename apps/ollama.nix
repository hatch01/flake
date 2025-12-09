{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    ollama.enable = mkEnableOption "Enable nix-related";
    ollama.cudaEnabled = mkEnableOption "Enable CUDA";
  };
  config = mkIf config.ollama.enable {
    services.ollama = {
      enable = true;
      package = if config.ollama.cudaEnabled then pkgs.ollama-cuda else pkgs.ollama;
    };
  };
}
