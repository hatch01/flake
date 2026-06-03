{
  config,
  username,
  inputs,
  stable,
  pkgs,
  lib,
  mkSecrets,
  ...
}:
{
  specialisation.polyjam = {
    inheritParentConfig = false;
    configuration = {

      imports = with inputs; [
        ./batterie.nix
        ./hardware-configuration.nix # maybe good to have a system that boot up
        inputs.lanzaboote.nixosModules.lanzaboote
        # seems unneded as we are onnly the specialisation and not the main system, but we will see if it cause any issue
        disko.nixosModules.disko
        agenix.nixosModules.default
        nix-index-database.nixosModules.nix-index
        (if stable then home-manager-stable else home-manager).nixosModules.home-manager

        impermanence.nixosModules.impermanence # needed because common -> apps -> element-call
        ../../configs/common.nix
        ../../configs/wifi.nix
      ];

      # disable things enabled by common.nix
      container.enable = false;
      nix-related.enable = false;
      beszel.agent.enable = false;
      comin.enable = false;
      services.tailscale.enable = false;
      programs.msmtp.enable = false;
      services.openssh.enable = false;
      nix.optimise.automatic = false;

      programs.firefox.enable = true;
      multimedia.audio.enable = true;
      programs.nix-ld.enable = true;
      yubikey.enable = true; # to allow using root access with yubikey

      services.xserver = {
        enable = true;
        windowManager.i3 = {
          enable = true;
          extraPackages = with pkgs; [
            i3lock # default i3 screen locker
          ];
        };
      };

      services.libinput = {
        enable = true;
        touchpad.naturalScrolling = true;
      };
      services.displayManager = {
        defaultSession = "none+i3";
        autoLogin = {
          enable = true;
          user = username;
        };
      };
      hm.xsession.windowManager.i3 = {
        enable = true;
        config = {
          modifier = "Mod4";
          fonts.names = [ "JetBrainsMono Nerd Font" ];
          keybindings = lib.mkOptionDefault {
            "Mod4+Return" = "exec kitty";
            "XF86MonBrightnessUp" = "exec ${lib.getExe pkgs.brightnessctl} set +5%";
            "XF86MonBrightnessDown" = "exec ${lib.getExe pkgs.brightnessctl} set 5%-";
          };
          assigns = {
            "1" = [ { class = "ardour"; } ];
            "2" = [
              { class = "open-stage-control"; }
              { class = "nmcli-password"; }
            ];
          };
          startup = [
            {
              command = "i3-msg workspace 1";
              always = true;
            }
            {
              command = "${lib.getExe pkgs.numlockx} on";
              always = true;
            }
            {
              command = "${lib.getExe pkgs.ardour} /home/eymeric/Nextcloud/music/batterie/polyjam/polyjam/polyjam.ardour";
              always = true;
            }
            {
              command = "${pkgs.kitty}/bin/kitty --class nmcli-password --hold bash -c '${lib.getExe' pkgs.networkmanager "nmcli"} device wifi show-password'";
              always = true;
            }
            {
              command = "${pkgs.kitty}/bin/kitty --class open-stage-control ${lib.getExe pkgs.open-stage-control-headless} --send 127.0.0.1:3819 --load /home/eymeric/Nextcloud/music/batterie/osc/ardour-control/ardour.json --custom-module /home/eymeric/Nextcloud/music/batterie/osc/ardour-control/ardour-plugins-module.js";
              always = true;
            }
          ];
        };
      };

      environment.enableAllTerminfo = true; # fix 'xterm-kitty': unknown terminal type.
      hm.programs.kitty = {
        enable = true;

        settings = {
          enable_audio_bell = false;
          window_padding_width = 15;
          themeFile = "Catppuccin-Latte";
        };

        font = {
          name = "JetBrains Mono";
          size = 12;
        };
      };

      nix.settings = {
        trusted-users = [ username ];
        max-jobs = 1; # how many derivation built at the same time
        cores = 1; # how many cores attributed to one build
      };

      users.users."${username}" = {
        hashedPasswordFile = config.age.secrets.userPassword.path;
        extraGroups = [ "networkmanager" ];
      };
      services.logind.settings.Login.HandleLidSwitch = "ignore";

      # Bootloader.
      system.nixos.tags = [ "polyjam" ];

      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };

      # Enable networking
      networking.networkmanager.enable = true;
      networking.wireless.enable = true;
      # systemd.services.wpa_supplicant.wantedBy = lib.mkForce [ ]; # Don't start wpa_supplicant at boot, we will start it manually when we want to use it
      # systemd.services."NetworkManager-wait-online".wantedBy = lib.mkForce [ ]; # Disable dependent service
      # systemd.services."NetworkManager-dispatcher".wantedBy = lib.mkForce [ ]; # Disable dependent service

      networking.firewall.enable = true;
      networking.firewall.allowedTCPPorts = [ 8080 ]; # open stage control
      networking.firewall.trustedInterfaces = [ "wlo1" ];

      # Auto-start WiFi hotspot on boot
      systemd.services.networkmanager-hotspot = {
        description = "NetworkManager WiFi Hotspot";
        after = [ "NetworkManager.service" ];
        wants = [ "NetworkManager.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          EnvironmentFile = config.age.secrets."polyjam_wifi_password".path;
          ExecStart = ''${pkgs.networkmanager}/bin/nmcli device wifi hotspot ifname wlo1 ssid polyjam password "$WIFI_PASS"'';
          ExecStop = "${pkgs.networkmanager}/bin/nmcli connection down id polyjam";
        };
      };

      # Configure console keymap
      console.keyMap = "fr";

      security.tpm2.enable = true;

      age = {
        identityPaths = [ "/etc/age/key" ];
        secrets = mkSecrets {
          "userPassword" = { };
          "polyjam_wifi_password" = { };
        };
      };
    };
  };
}
