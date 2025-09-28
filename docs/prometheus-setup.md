# Multi-Host Prometheus Setup with Tailscale

This document explains how to set up Prometheus monitoring across multiple hosts using Tailscale networking.

## Architecture Overview

- **Prometheus Server** (jonquille): Runs the main Prometheus instance and scrapes metrics
- **Remote Hosts** (lilas, etc.): Run exporters that expose metrics over Tailscale network
- **Tailscale Network**: Provides secure networking and hostname resolution between hosts

## Configuration Steps

### 1. Configure Prometheus Server (jonquille)

In `systems/jonquille/default.nix`:

```nix
prometheus = {
  enable = true;
  remoteHosts = {
    lilas = {
      exporters = [
        "node"      # System metrics
        "systemd"   # Service status
        "process"   # Process metrics
      ];
    };
    # Add more hosts as needed
    another-host = {
      exporters = ["node" "systemd"];
    };
  };
};
```

### 2. Configure Remote Hosts (lilas, etc.)

In `systems/lilas/default.nix`:

```nix
prometheus.exporters = {
  enable = true;
  enabled = [
    "node"      # System metrics
    "systemd"   # Service status
    "process"   # Process metrics
  ];
};

# Open firewall ports for exporters
networking.firewall.allowedTCPPorts = [
  # ... your existing ports ...
] ++ lib.optionals config.prometheus.exporters.enable [
  9100  # node_exporter
  9256  # process_exporter
  9308  # systemd_exporter
];
```

## Available Exporters

The following exporters can be enabled on remote hosts:

- `node` - System metrics (CPU, memory, disk, network)
- `systemd` - Service status and systemd metrics
- `process` - Process monitoring and statistics
- `zfs` - ZFS filesystem metrics (if ZFS is available)

## Security Notes

- Exporters on remote hosts listen on all interfaces but are protected by firewall
- Tailscale provides secure networking and hostname resolution
- No authentication is needed as Tailscale handles network security
- Firewall rules allow access only on exporter ports
- Local exporters (on Prometheus server) still use localhost for security

## Troubleshooting

### Check if exporters are running

```bash
# On remote host
systemctl status prometheus-*-exporter

# Check if listening on Tailscale IP
ss -tlnp | grep :9100
```

### Test connectivity from Prometheus server

```bash
# From jonquille, test connection to lilas using hostname
curl http://lilas:9100/metrics
```

### Check Prometheus targets

Visit `https://prometheus.your-domain.com/targets` to see all configured targets and their status.

## Adding New Hosts

1. Add exporter configuration to the new host's `default.nix`
2. Add the host to `prometheus.remoteHosts` on jonquille (use the hostname)
3. Rebuild both configurations
4. Check targets in Prometheus web UI

## Example: Adding a third host "rose"

**On rose** (`systems/rose/default.nix`):

```nix
prometheus.exporters = {
  enable = true;
  enabled = ["node" "systemd"];
};
```

**On jonquille** (`systems/jonquille/default.nix`):

```nix
prometheus.remoteHosts = {
  lilas = { /* ... existing config ... */ };
  rose = {
    exporters = ["node" "systemd"];
  };
};
```
