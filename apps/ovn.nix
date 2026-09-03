{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    types
    ;
  cfg_central = config.services.ovn-central;
  cfg_host = config.services.ovn-host;
in
{
  options.services.ovn-central = {
    enable = mkEnableOption "ovn central service";
    package = mkPackageOption pkgs "ovn" { };
    ovn_ctl_opts = mkOption {
      type = types.lines;
      default = "";
      description = "Extra options to pass to ovn-ctl";
    };
  };

  options.services.ovn-host = {
    enable = mkEnableOption "ovn host service";
    package = mkPackageOption pkgs "ovn" { };
    ovn_ctl_opts = mkOption {
      type = types.lines;
      default = "";
      description = "Extra options to pass to ovn-ctl";
    };
  };

  config = mkIf (cfg_central.enable || cfg_host.enable) {
    environment.persistence."/persistent" = mkIf cfg_host.enable {
      directories = [ "/var/lib/openvswitch" ];
    };

    systemd.tmpfiles.rules = mkIf cfg_host.enable [
      "d /var/lib/openvswitch 0755 root root -"
    ];

    environment.systemPackages = lib.mkMerge [
      (mkIf cfg_central.enable [ cfg_central.package ])
      (mkIf cfg_host.enable [ cfg_host.package ])
    ];

    systemd.services = mkMerge [
      (mkIf cfg_host.enable {
        ovn-host = {
          enable = true;
          description = "Open Virtual Network host components";
          after = [ "network.target" ];
          requires = [ "network.target" ];
          wants = [ "ovn-controller.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "/run/current-system/sw/bin/true";
            ExecStop = "/run/current-system/sw/bin/true";
            RemainAfterExit = "yes";
          };
          wantedBy = [ "multi-user.target" ];
        };

        ovn-config = {
          enable = true;
          description = "Configure Open vSwitch for OVN";
          requires = [ "ovsdb.service" ];
          after = [ "ovsdb.service" ];
          partOf = [ "ovn-host.service" ];
          wantedBy = [ "ovn-controller.service" ];
          path = [ pkgs.openvswitch ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = "yes";
          };
          script = ''
            ovs-vsctl set open_vswitch . \
              external_ids:ovn-remote=unix:/run/ovn/ovnsb_db.sock \
              external_ids:ovn-encap-type=geneve \
              external_ids:ovn-encap-ip=127.0.0.1
          '';
        };

        ovn-controller = {
          enable = true;
          description = "Open Virtual Network host control daemon";
          path = [
            cfg_host.package
            pkgs.openvswitch
            pkgs.util-linux
          ];
          requires = [
            "ovsdb.service"
            "ovn-config.service"
          ];
          after = [
            "network.target"
            "ovsdb.service"
            "ovn-config.service"
          ];
          preStart = ''
            SYSTEM_ID_FILE=/var/lib/openvswitch/system-id

            if [ ! -s "$SYSTEM_ID_FILE" ]; then
              ${pkgs.util-linux}/bin/uuidgen > "$SYSTEM_ID_FILE"
            fi

            ${pkgs.openvswitch}/bin/ovs-vsctl \
              set Open_vSwitch . external_ids:system-id="$(cat "$SYSTEM_ID_FILE")"
          '';
          partOf = [ "ovn-host.service" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig = {
            Type = "forking";
            ExecStart = "${cfg_host.package}/share/ovn/scripts/ovn-ctl start_controller --ovn-manage-ovsdb=no --no-monitor ${cfg_host.ovn_ctl_opts}";
            ExecStop = "${cfg_host.package}/share/ovn/scripts/ovn-ctl stop_controller --no-monitor";
            Restart = "on-failure";
            LimitNOFILE = "65535";
            TimeoutStopSec = "15";
          };
        };
      })

      (mkIf cfg_central.enable {
        ovn-central = {
          enable = true;
          description = "Open Virtual Network central components";
          after = [ "network.target" ];
          wants = [
            "ovn-northd.service"
            "ovn-nb-ovsdb.service"
            "ovn-sb-ovsdb.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "/run/current-system/sw/bin/true";
            ExecStop = "/run/current-system/sw/bin/true";
            RemainAfterExit = "yes";
          };
          wantedBy = [ "multi-user.target" ];
        };

        ovn-northd = {
          enable = true;
          description = "Open Virtual Network central control daemon";
          path = [ cfg_central.package ];
          after = [
            "network.target"
            "ovn-nb-ovsdb.service"
            "ovn-sb-ovsdb.service"
          ];
          partOf = [ "ovn-central.service" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig = {
            Type = "forking";
            ExecStart = "${cfg_central.package}/share/ovn/scripts/ovn-ctl start_northd --ovn-manage-ovsdb=no --no-monitor ${cfg_central.ovn_ctl_opts}";
            ExecStop = "${cfg_central.package}/share/ovn/scripts/ovn-ctl stop_northd --no-monitor";
            Restart = "on-failure";
            LimitNOFILE = "65535";
            TimeoutStopSec = "15";
          };
        };

        ovn-nb-ovsdb = {
          enable = true;
          description = "Open vSwitch database server for OVN Northbound database";
          path = [ cfg_central.package ];
          after = [ "network.target" ];
          partOf = [ "ovn-central.service" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig = {
            Type = "simple";
            ExecStart = "${cfg_central.package}/share/ovn/scripts/ovn-ctl run_nb_ovsdb ${cfg_central.ovn_ctl_opts}";
            ExecStop = "${cfg_central.package}/share/ovn/scripts/ovn-ctl stop_nb_ovsdb";
            Restart = "on-failure";
            LimitNOFILE = "65535";
            TimeoutStopSec = "15";
          };
        };

        ovn-sb-ovsdb = {
          enable = true;
          description = "Open vSwitch database server for OVN Southbound database";
          path = [ cfg_central.package ];
          after = [ "network.target" ];
          partOf = [ "ovn-central.service" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig = {
            Type = "simple";
            ExecStart = "${cfg_central.package}/share/ovn/scripts/ovn-ctl run_sb_ovsdb ${cfg_central.ovn_ctl_opts}";
            ExecStop = "${cfg_central.package}/share/ovn/scripts/ovn-ctl stop_sb_ovsdb";
            Restart = "on-failure";
            LimitNOFILE = "65535";
            TimeoutStopSec = "15";
          };
        };
      })
    ];
  };
}
