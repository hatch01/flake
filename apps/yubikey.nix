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

  generateU2FAuthFile =
    username: entries: pkgs.writeText "u2f" "${username}:${lib.concatStringsSep ":" entries}";
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
        # pamu2fcfg -n # remove the leading :
        authfile = generateU2FAuthFile "root" [
          "Ei8K9Ma3LL+ois6vcU4N9q4rZcj94L0Lxw4EAFw2doe7DErUQfgkg2Q7MoEmj9IA70tdFpWgvftqL5uvhQT2CQ==,CkQXn6XxgcsSLXuI4/CqZk0xueBDfk83pSsbwW9iklO4YAuROhYg6NcpMunW5sohado5jgIQCrxBbob8SG8diA==,es256,+presence"
          "wueuhWZKeN1FIp5KNKZ/wdanqf8LKRZuS6/D3TOg1fj3iTuisXnAsP8faLhjiI1KagEPZXbpbNNwiBpB9QreAg==,EhK2Y5OWgzpdAzuyHPUtxd1/xCJWqQ78Yyh0l7LOYcRCO1kBVaIOHJWlrkITj6Kn4pY5upZvFyho8CqtipELFA==,es256,+presence"
        ];
        # authfile = pkgs.writeText "u2f" ''
        #   root:Ei8K9Ma3LL+ois6vcU4N9q4rZcj94L0Lxw4EAFw2doe7DErUQfgkg2Q7MoEmj9IA70tdFpWgvftqL5uvhQT2CQ==,CkQXn6XxgcsSLXuI4/CqZk0xueBDfk83pSsbwW9iklO4YAuROhYg6NcpMunW5sohado5jgIQCrxBbob8SG8diA==,es256,+presence:wueuhWZKeN1FIp5KNKZ/wdanqf8LKRZuS6/D3TOg1fj3iTuisXnAsP8faLhjiI1KagEPZXbpbNNwiBpB9QreAg==,EhK2Y5OWgzpdAzuyHPUtxd1/xCJWqQ78Yyh0l7LOYcRCO1kBVaIOHJWlrkITj6Kn4pY5upZvFyho8CqtipELFA==,es256,+presence
        # '';
      };
    };

    environment.systemPackages = with pkgs; [
      yubioath-flutter
      yubikey-manager
      kdePackages.kleopatra
    ];

    hardware.gpgSmartcards.enable = true;
    services.udev.packages = [ pkgs.yubikey-personalization ];
    hm = {
      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        enableZshIntegration = true;
      };
      programs.gpg.scdaemonSettings = {
        disable-ccid = true;
      };
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
