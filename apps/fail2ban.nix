{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
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
          # bantime = "1d";
          # findtime = "1d";
          # chain = "DOCKER-USER";
          # action = "iptables-allports[name=authelia]";
        };
      };
    };

    environment.etc = {
      "fail2ban/filter.d/authelia.local".text = pkgs.lib.mkDefault (pkgs.lib.mkAfter ''
            # Fail2Ban filter for Authelia

        # Make sure that the HTTP header "X-Forwarded-For" received by Authelia's backend
        # only contains a single IP address (the one from the end-user), and not the proxy chain
        # (it is misleading: usually, this is the purpose of this header).

        # the failregex rule counts every failed 1FA attempt (first line, wrong username or password) and failed 2FA attempt
        # second line) as a failure.
        # the ignoreregex rule ignores info and warning messages as all authentication failures are flagged as errors
        # the third line catches incorrect usernames entered at the password reset form
        # the fourth line catches attempts to spam via the password reset form or 2fa device reset form. This requires debug logging to be enabled

        [Definition]
        failregex = ^.*Unsuccessful (1FA|TOTP|Duo|U2F) authentication attempt by user .*remote_ip"?(:|=)"?<HOST>"?.*$
                    ^.*user not found.*path=/api/reset-password/identity/start remote_ip"?(:|=)"?<HOST>"?.*$
                    ^.*Sending an email to user.*path=/api/.*/start remote_ip"?(:|=)"?<HOST>"?.*$

        ignoreregex = ^.*level"?(:|=)"?info.*
                      ^.*level"?(:|=)"?warning.*
      '');
    };
  };
}
