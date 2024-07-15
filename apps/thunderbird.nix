{
  config,
  pkgs,
  lib,
  ...
}: let
  thunderbird_profile = "default_thunderbird";

  inherit (lib) mkEnableOption mkDefault mkIf;
in {
  options = {
    thunderbird.enable = mkEnableOption "Enable Thunderbird";
    thunderbird.account.eymericdechelette_gmail.enable = mkEnableOption "Enable Eymeric Déchelette Gmail account";
    thunderbird.account.hatchlechien_yahoo.enable = mkEnableOption "Enable Hatchlechien Yahoo account";
    thunderbird.account.eymericdechelette_free.enable = mkEnableOption "Enable Eymeric Déchelette Free account";
    thunderbird.account.eymericmonitoring_free.enable = mkEnableOption "Enable Eymeric Monitoring Free account";
    thunderbird.account.hatchlechien_gmail.enable = mkEnableOption "Enable Hatchlechien Gmail account";
    thunderbird.account.univ_email.enable = mkEnableOption "Enable University email account";
  };

  config = mkIf config.thunderbird.enable {
    # set every account to be enabled by default
    thunderbird.account = {
      eymericdechelette_gmail.enable = mkDefault true;
      hatchlechien_yahoo.enable = mkDefault true;
      eymericdechelette_free.enable = mkDefault true;
      eymericmonitoring_free.enable = mkDefault true;
      hatchlechien_gmail.enable = mkDefault true;
      univ_email.enable = mkDefault true;
    };

    hm = {
      programs.thunderbird = {
        enable = true;
        profiles."${thunderbird_profile}" = {
          isDefault = true;
        };
        settings = {
          "spellchecker.dictionary" = "fr,en-US";
          "mail.pane_config.dynamic" = 0;
        };
      };

      accounts.email.accounts = with config; {
        eymericdechelette_gmail = mkIf thunderbird.account.eymericdechelette_gmail.enable {
          realName = "Eymeric Déchelette";
          address = "eymericdechelette@gmail.com";
          flavor = "gmail.com";
          userName = "eymericdechelette@gmail.com";

          thunderbird = {
            enable = true;
            profiles = ["${thunderbird_profile}"];
            settings = id: {
              "mail.smtpserver.smtp_${id}.authMode" = 10;
              "mail.server.server_${id}.authMethod" = 10;
              "mail.identity.id_${id}.reply_on_top" = 1;
            };
          };
        };

        hatchlechien_yahoo = mkIf thunderbird.account.hatchlechien_yahoo.enable {
          realName = "Eymeric Déchelette";
          address = "hatchchien@yahoo.fr";
          userName = "hatchchien@yahoo.fr";
          imap.host = "imap.mail.yahoo.com";
          imap.port = 993;
          imap.tls.enable = true;
          smtp.host = "smtp.mail.yahoo.com";
          smtp.port = 465;
          smtp.tls.enable = true;
          thunderbird = {
            enable = true;
            profiles = ["${thunderbird_profile}"];
            settings = id: {
              "mail.smtpserver.smtp_${id}.authMode" = 10;
              "mail.server.server_${id}.authMethod" = 10;
              "mail.identity.id_${id}.reply_on_top" = 1;
            };
          };
        };

        eymericdechelette_free = mkIf thunderbird.account.eymericdechelette_free.enable {
          realName = "Eymeric Déchelette";
          address = "eymeric.dechelette@free.fr";
          userName = "eymeric.dechelette";
          imap.host = "imap.free.fr";
          imap.port = 993;
          imap.tls.enable = true;
          smtp.host = "smtp.free.fr";
          smtp.port = 465;
          smtp.tls.enable = true;
          primary = true;
          thunderbird = {
            enable = true;
            profiles = ["${thunderbird_profile}"];
            settings = id: {
              "mail.identity.id_${id}.reply_on_top" = 1;
            };
          };
        };

        eymericmonitoring_free = mkIf thunderbird.account.eymericmonitoring_free.enable {
          realName = "Eymeric Déchelette";
          address = "eymeric.monitoring@free.fr";
          userName = "eymeric.monitoring";
          imap.host = "imap.free.fr";
          imap.port = 993;
          imap.tls.enable = true;
          smtp.host = "smtp.free.fr";
          smtp.port = 465;
          smtp.tls.enable = true;
          thunderbird = {
            enable = true;
            profiles = ["${thunderbird_profile}"];
            settings = id: {
              "mail.identity.id_${id}.reply_on_top" = 1;
            };
          };
        };

        hatchlechien_gmail = mkIf thunderbird.account.hatchlechien_gmail.enable {
          realName = "Eymeric Déchelette";
          address = "hatchlechien@gmail.com";
          flavor = "gmail.com";

          userName = "hatchlechien@gmail.com";
          thunderbird = {
            enable = true;
            profiles = ["${thunderbird_profile}"];
            settings = id: {
              "mail.smtpserver.smtp_${id}.authMode" = 10;
              "mail.server.server_${id}.authMethod" = 10;
              "mail.identity.id_${id}.reply_on_top" = 1;
            };
          };
        };

        univ_email = mkIf thunderbird.account.univ_email.enable {
          realName = "Eymeric Dechelette";
          address = "eymeric.dechelette@etu.univ-lyon1.fr";
          userName = "P2202851";
          imap.host = "accesbv.univ-lyon1.fr";
          imap.port = 993;
          imap.tls.enable = true;
          smtp.host = "smtpbv.univ-lyon1.fr";
          smtp.port = 587;
          smtp.tls.enable = true;
          smtp.tls.useStartTls = true;

          thunderbird = {
            enable = true;
            profiles = ["${thunderbird_profile}"];
            settings = id: {
              "mail.identity.id_${id}.reply_on_top" = 1;
            };
          };
        };
      };
    };
  };
}
