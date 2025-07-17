{
  lib,
  config,
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
      acceleration = mkIf config.ollama.cudaEnabled "cuda";
    };
  };
}
