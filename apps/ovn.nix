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
      description = "Extra options to pass to ovs-ctl";
    };
  };

  options.services.ovn-host = {
    enable = mkEnableOption "ovn host service";
    package = mkPackageOption pkgs "ovn" { };
    ovn_ctl_opts = mkOption {
      type = types.lines;
      default = "";
      description = "Extra options to pass to ovs-ctl";
    };
  };

  config = mkIf (cfg_central.enable || cfg_host.enable) {
    environment.systemPackages = lib.mkMerge [
      (mkIf cfg_central.enable [ cfg_central.package ])
      (mkIf cfg_host.enable [ cfg_host.package ])
    ];

    boot.kernelModules = [
      "tun"
      "openvswitch"
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

        ovn-controller = {
          enable = true;
          description = "Open Virtual Network host control daemon";
          path = [ pkgs.gawk ];
          requires = [ "openvswitch-switch.service" ];
          after = [
            "network.target"
            "openvswitch-switch.service"
          ];
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

        openvswitch-switch = {
          enable = true;
          description = "Open vSwitch";
          after = [
            "ovsdb-server.service"
            "network-pre.target"
            "ovs-vswitchd.service"
          ];
          before = [ "network.target" ];
          partOf = [ "network.target" ];
          requires = [
            "ovsdb-server.service"
            "ovs-vswitchd.service"
          ];
          path = [ pkgs.gawk ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "/run/current-system/sw/bin/true";
            ExecStop = "${cfg_host.package}/share/openvswitch/scripts/ovs-ctl --no-ovsdb-server stop";
            ExecReload = "${cfg_host.package}/share/openvswitch/scripts/ovs-systemd-reload";
            RemainAfterExit = "yes";
          };
        };

        ovs-vswitchd = {
          enable = true;
          description = "Open vSwitch Forwarding Unit";
          after = [
            "ovsdb-server.service"
            "network-pre.target"
            "systemd-udev-settle.service"
          ];
          before = [
            "network.target"
            "networking.service"
          ];
          partOf = [ "openvswitch-switch.service" ];
          path = [
            pkgs.gawk
            pkgs.kmod
          ];
          requires = [ "ovsdb-server.service" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig = {
            Type = "forking";
            ExecStart = "${cfg_host.package}/share/openvswitch/scripts/ovs-ctl --no-ovsdb-server --no-monitor --system-id=random --no-record-hostname start ${cfg_host.ovn_ctl_opts}";
            ExecStop = "${cfg_host.package}/share/openvswitch/scripts/ovs-ctl --no-ovsdb-server stop";
            Restart = "on-failure";
            ExecReload = "${cfg_host.package}/share/openvswitch/scripts/ovs-ctl --no-ovsdb-server --no-monitor --system-id=random --no-record-hostname restart ${cfg_host.ovn_ctl_opts}";
            LimitNOFILE = "1048576";
            TimeoutSec = "300";
            OOMScoreAdjust = "900";
          };
        };

        ovsdb-server = {
          enable = true;
          description = "Open vSwitch Database Unit";
          after = [
            "systemd-journald.socket"
            "network-pre.target"
            "dpdk.service"
            "local-fs.target"
          ];
          before = [
            "network.target"
            "networking.service"
          ];
          partOf = [ "openvswitch-switch.service" ];
          path = [
            pkgs.gawk
            pkgs.util-linux
          ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig = {
            Type = "forking";
            ExecStart = "${cfg_host.package}/share/openvswitch/scripts/ovs-ctl --no-ovs-vswitchd --no-monitor --system-id=random --no-record-hostname start ${cfg_host.ovn_ctl_opts}";
            ExecStop = "${cfg_host.package}/share/openvswitch/scripts/ovs-ctl --no-ovs-vswitchd stop";
            Restart = "on-failure";
            ExecReload = "${cfg_host.package}/share/openvswitch/scripts/ovs-ctl --no-ovs-vswitchd --no-record-hostname --no-monitor restart ${cfg_host.ovn_ctl_opts}";
            LimitNOFILE = "1048576";
            TimeoutSec = "300";
            OOMScoreAdjust = "900";
            RuntimeDirectory = "openvswitch";
            RuntimeDirectoryMode = "0755";
            RuntimeDirectoryPreserve = "yes";
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
          path = [ "/tmp" ];
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
          path = [ "/tmp" ];
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
