{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options = {
    librespeed = {
      enable = mkEnableOption "enable librespeed";
      domain = mkOption {
        type = types.str;
        default = "librespeed.${config.networking.domain}";
        description = "The domain of the librespeed instance";
      };
      port = mkOption {
        type = types.int;
        default = 8085;
        description = "The port on which librespeed will listen";
      };
    };
  };

  config = mkIf config.librespeed.enable {
    virtualisation.oci-containers.containers.speedtest = {
      ports = [
        "[::1]:${toString config.librespeed.port}:8080"
      ];
      image = "ghcr.io/librespeed/speedtest";
    };
  };
}
