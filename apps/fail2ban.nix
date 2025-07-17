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
    fail2ban = {
      enable = mkEnableOption "enable fail2ban";
    };
  };

  config = mkIf config.fail2ban.enable {
    services.fail2ban = {
      enable = true;
      maxretry = 10;
      ignoreIP = [
        # Whitelist some subnets
        "127.0.0.1"
        "192.168.0.0/16"
        "109.26.63.39"
      ];
      bantime = "24h"; # Ban IPs for one day on the first ban
      bantime-increment = {
        enable = true; # Enable increment of bantime after each violation
        formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
        maxtime = "168h"; # Do not ban for more than 1 week
        overalljails = true; # Calculate the bantime based on all the violations
      };
      jails = {
        authelia.settings = {
          enabled = true;
          port = "http,https";
          filter = "authelia";
          logpath = "/var/lib/authelia-main/authelia.log";
          maxretry = 5;
        };
        cockpit.settings = {
          enabled = true;
          backend = "systemd";
          port = "http,https";
          filter = "cockpit";
          maxretry = 5;
        };
        homeassistant.settings = {
          enabled = true;
          port = "http,https";
          filter = "homeassistant";
          backend = "systemd";
          maxretry = 5;
        };
      };
    };

    environment.etc = {
      "fail2ban/filter.d/authelia.local".text = ''
        [Definition]
        failregex = ^.*Unsuccessful (1FA|TOTP|Duo|U2F) authentication attempt by user .*remote_ip"?(:|=)"?<HOST>"?.*$
                    ^.*user not found.*path=/api/reset-password/identity/start remote_ip"?(:|=)"?<HOST>"?.*$
                    ^.*Sending an email to user.*path=/api/.*/start remote_ip"?(:|=)"?<HOST>"?.*$

        ignoreregex = ^.*level"?(:|=)"?info.*
                      ^.*level"?(:|=)"?warning.*
      '';
      "fail2ban/filter.d/cockpit.local".text = ''
        [Definition]
        failregex = pam_unix\(cockpit:auth\): authentication failure; logname=.* uid=.* euid=.* tty=.* ruser=.* rhost=<HOST>
        journalmatch = SYSLOG_FACILITY=10 PRIORITY=5
      '';
      "fail2ban/filter.d/homeassistant.local".text = ''
        [Definition]
        failregex = ^.*Login attempt or request with invalid authentication from <HOST>.*$
        journalmatch = _SYSTEMD_UNIT=docker-homeassistant.service
      '';
    };
  };
}
