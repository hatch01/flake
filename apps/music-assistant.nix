{
  config,
  lib,
  base_domain_name,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
in
{
  options = {
    music-assistant = {
      enable = mkEnableOption "enable music-assistant";
      domain = mkOption {
        type = types.str;
        default = "music.${base_domain_name}";
        description = "The domain of the music-assistant instance";
      };
      port = mkOption {
        type = types.int;
        default = 8095;
        description = "The port to listen on";
      };
    };
  };

  config = mkIf config.music-assistant.enable {
    services.music-assistant = {
      enable = true;
      providers = [
        "spotify"
        "filesystem_local"
      ];
    };

    environment.persistence."/persistent".directories = [
      "/var/lib/private/music-assistant"
    ];
  };
}
