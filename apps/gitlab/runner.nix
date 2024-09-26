{
  lib,
  config,
  mkSecret,
  pkgs,
  ...
}: let
  inherit (lib) mkIf;
in {
  config = mkIf config.gitlab.enable {
    age.secrets = mkSecret "gitlab/runnerRegistrationConfigFile" {
      # owner = "root";
      # group = "users";
      # mode = "400";
    };

    boot.kernel.sysctl."net.ipv4.ip_forward" = true;
    virtualisation.docker.enable = true;
    services.gitlab-runner = {
      enable = true;
      settings = {
        concurrent = 4;
        network_mode = "host";
      };
      services = {
        # test = {
        #   dockerImage = "nixos/nix";
        #   authenticationTokenConfigFile = config.age.secrets."gitlab/runnerRegistrationConfigFile".path;
        #   # preBuildScript = ''
        #   #   apk add --no-cache git
        #   #   git clone https://gitlab.com/gitlab-org/gitlab-runner.git
        #   #   cd gitlab-runner
        #   #   ./scripts/build-alpine
        #   # '';
        # };
        # runner for building in docker via host's nix-daemon
        # nix store will be readable in runner, might be insecure
        nix = with lib; {
          # File should contain at least these two variables:
          # `CI_SERVER_URL`
          # `REGISTRATION_TOKEN`
          authenticationTokenConfigFile = config.age.secrets."gitlab/runnerRegistrationConfigFile".path;
          dockerImage = "alpine";
          dockerVolumes = [
            "/nix/store:/nix/store:rw"
            "/nix/var/nix/db:/nix/var/nix/db:rw"
            "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
          ];
          dockerDisableCache = true;
          preBuildScript = pkgs.writeScript "setup-container" ''
            mkdir -p -m 0755 /nix/var/log/nix/drvs
            mkdir -p -m 0755 /nix/var/nix/gcroots
            mkdir -p -m 0755 /nix/var/nix/profiles
            mkdir -p -m 0755 /nix/var/nix/temproots
            mkdir -p -m 0755 /nix/var/nix/userpool
            mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
            mkdir -p -m 1777 /nix/var/nix/profiles/per-user
            mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
            mkdir -p -m 0700 "$HOME/.nix-defexpr"
            mkdir -p -m 0755 /etc/nix
            echo "trusted-users = root" >> /etc/nix/nix.conf
            . ${pkgs.nix}/etc/profile.d/nix-daemon.sh
            ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixos-unstable  nixpkgs
            ${pkgs.nix}/bin/nix-channel --update nixpkgs
            ${pkgs.nix}/bin/nix-env -i ${concatStringsSep " " (with pkgs; [nix cacert git openssh])}
          '';
          environmentVariables = {
            ENV = "/etc/profile";
            USER = "root";
            NIX_REMOTE = "daemon";
            PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
          };
          # tagList = ["nix"];
        };
      };
    };
  };
}
