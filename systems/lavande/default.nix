# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  mkSecrets,
  ...
}: {
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["@wheel"];
  };

  age = {
    identityPaths = ["/persistent/key"];

    secrets = mkSecrets {
      "server/smtpPassword" = {
        group = "smtp";
        mode = "440";
        root = true;
      };
      "server/smtpPasswordEnv" = {
        group = "smtp";
        mode = "440";
        root = true;
      };
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "fr_FR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  # Configure console keymap
  console.keyMap = "fr";

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  nix.optimise.automatic = true;
  nix.optimise.dates = ["03:45"]; # Optional; allows customizing optimisation schedule

  nix.extraOptions = ''
    !include ${config.age.secrets.githubToken.path}
  '';
}
