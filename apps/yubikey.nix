{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    types
    ;
in
{
  options = {
    yubikey = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable YubiKey service";
      };
    };
  };

  config = mkIf config.yubikey.enable {
    security.pam.u2f = {
      enable = true;
      settings = {
        # pamu2fcfg -uroot
        authfile = pkgs.writeText "u2f" ''
          # 13/10/2025
          root:W9CHKqgATqKYaenRfuNjkc1cAXRjoshq3bpcF0vcOBh4s/MeoBodACyBo9qUoJHvkt8n7W7uJ2KfD/p9Q5xukw==,Hx2Jld8EMTl8C9eT+oIg6lzCMnTl2QF4PdlhFtdZuukuV3/hDlHf7Ltwo3/h+Go7X+xdgIb6AHCv7z2Enj6Bag==,es256,+presence
          root:IGjPOv3ojp/lcJbrgX5uhUc7NlZLomMlXdFnsOnQaJDTVAzAEtmlCZzf+rnC9yUvHhMbKMjJKdQFXFDxnmStZg==,4an7GeeOLfKFyIlLO2iP1h/0vabU466rQ6EIs+Ms5fj9cU5tvnKRMET+uoVO+55gpVYXIfDRBh89CgH0Omtk1w==,es256,+presence
        '';
      };
    };

    environment.systemPackages = with pkgs; [
      yubioath-flutter
      yubikey-manager
    ];

    services.pcscd.enable = true;
    hardware.gpgSmartcards.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
    hm.services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableZshIntegration = true;

    };

    boot.initrd.systemd.enable = true;
    boot.initrd.kernelModules = [
      "usb_storage"
      "usbhid"
      "hid_generic"
      "hid"
      "vfat"
      "nls_cp437"
      "nls_iso8859-1"
      "usbhid"
    ];

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
