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
      hostName = mkOption {
        type = types.str;
        default = "librespeed.${config.hostName}";
        description = "The hostname of the librespeed instance";
      };
      port = mkOption {
        type = types.int;
        default = 8085;
        description = "The port on which Adguard will listen";
      };
    };
  };

  config = mkIf config.librespeed.enable {
    virtualisation.oci-containers.containers.speedtest = {
      ports = [
        "${toString config.librespeed.port}:80"
      ];
      image = "ghcr.io/librespeed/speedtest";
    };
  };
}
