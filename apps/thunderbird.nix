{
  config,
  pkgs,
  ...
}: {
  hm = {
    programs.thunderbird = {
      enable = true;
      profiles.default_thunderbird = {
        isDefault = true;
      };
      settings = {
        "spellchecker.dictionary" = "fr,en-US";
        "mail.pane_config.dynamic" = 0;
      };
    };

    accounts.email.accounts.eymericdechelette_gmail = {
      realName = "Eymeric Déchelette";
      address = "eymericdechelette@gmail.com";
      flavor = "gmail.com";
      userName = "eymericdechelette@gmail.com";

      thunderbird = {
        enable = true;
        profiles = ["default_thunderbird"];
        settings = id: {
          "mail.smtpserver.smtp_${id}.authMode" = 10;
          "mail.server.server_${id}.authMethod" = 10;
        };
      };
    };

    accounts.email.accounts.hatchlechien_yahoo = {
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
        profiles = ["default_thunderbird"];
        settings = id: {
          "mail.smtpserver.smtp_${id}.authMode" = 10;
          "mail.server.server_${id}.authMethod" = 10;
        };
      };
    };

    accounts.email.accounts.eymericdechelette_free = {
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
        profiles = ["default_thunderbird"];
      };
    };

    accounts.email.accounts.hatchlechien_gmail = {
      realName = "Eymeric Déchelette";
      address = "hatchlechien@gmail.com";
      flavor = "gmail.com";

      userName = "hatchlechien@gmail.com";
      thunderbird = {
        enable = true;
        profiles = ["default_thunderbird"];
        settings = id: {
          "mail.smtpserver.smtp_${id}.authMode" = 10;
          "mail.server.server_${id}.authMethod" = 10;
        };
      };
    };

    accounts.email.accounts.univ_email = {
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
        profiles = ["default_thunderbird"];
      };
    };
  };
}
