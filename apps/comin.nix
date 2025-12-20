{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  imports = [ inputs.comin.nixosModules.comin ];

  options = {
    comin.enable = mkEnableOption "Enable service";
  };

  config = mkIf config.comin.enable {
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = "https://${config.forgejo.domain}/eymeric/flake.git";
          branches.main.name = "main";
        }
      ];
    };
  };
}
