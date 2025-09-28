{
  config,
  mkSecret,
  lib,
  base_domain_name,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
in
{
  options = {
    homepage = {
      enable = mkEnableOption "Enable homepage";
      domain = mkOption {
        type = types.str;
        default = base_domain_name;
        description = "The domain of the homepage";
      };
      port = mkOption {
        type = types.int;
        default = 8082;
        description = "The port of the homepage";
      };
    };
  };

  config = mkIf config.homepage.enable {
    age.secrets = mkSecret "homepage" {
      owner = "root";
      group = "users";
      mode = "400";
    };
    services = {
      homepage-dashboard = {
        enable = true;
        openFirewall = false;
        environmentFile = config.age.secrets.homepage.path;
        bookmarks = [ ];
        listenPort = config.homepage.port;
        allowedHosts = config.homepage.domain;

        settings = {
          title = "Onyx Homepage";
          background = "https://images.unsplash.com/photo-1485431142439-206ba3a9383e?q=80&w=1966&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D";
          headerStyle = "boxed";
          language = "fr";
          theme = "light";
          quicklaunch = {
            prompt = "duckduckgo";
            showSearchSuggestions = true;
            searchDescriptions = true;
          };
          layout = {
            "All users tools" = {
              style = "row";
              columns = 4;
              icon = "nextcloud.png";
            };
          };
        };
        services = [
          {
            "All users tools" = [
              {
                "Nextcloud" = {
                  icon = "nextcloud.png";
                  description = "Nextcloud c'est vraiment cool";
                  href = "https://${config.nextcloud.domain}";
                  siteMonitor = "https://${config.nextcloud.domain}";
                  widget = {
                    type = "nextcloud";
                    url = "https://${config.nextcloud.domain}";
                    username = "root";
                    password = "{{HOMEPAGE_VAR_NEXTCLOUD_PASS}}";
                  };
                };
              }
              {
                "ForgeJo" = {
                  icon = "forgejo.png";
                  description = "Forgejo c'est vraiment cool";
                  href = "https://${config.forgejo.domain}/";
                  siteMonitor = "https://${config.forgejo.domain}/";
                };
              }
              {
                "speedtest" = {
                  icon = "librespeed.png";
                  description = "Librespeed c'est vraiment cool";
                  href = "https://${config.librespeed.domain}/";
                  siteMonitor = "https://${config.librespeed.domain}/";
                };
              }
              {
                "Matrix" = {
                  icon = "element.png";
                  description = "Matrix c'est vraiment cool";
                  href = "https://${config.matrix.domain}/";
                  siteMonitor = "https://${config.matrix.domain}/";
                };
              }
              {
                "wakapi" = {
                  icon = "wakapi.png";
                  description = "Wakapi c'est vraiment cool";
                  href = "https://${config.wakapi.domain}/";
                  siteMonitor = "https://${config.wakapi.domain}/";
                };
              }
            ];
          }
          {
            "Home" = [
              {
                "Home Assistant" = {
                  icon = "home-assistant.png";
                  description = "HomeAssistant c'est vraiment cool";
                  href = "https://${config.home_assistant.domain}";
                  siteMonitor = "https://${config.home_assistant.domain}";
                  widget = {
                    type = "homeassistant";
                    url = "https://${config.home_assistant.domain}";
                    key = "{{HOMEPAGE_VAR_HOMEASSISTANT}}";
                  };
                };
              }
              {
                "Node Red" = {
                  icon = "node-red.png";
                  description = "Node-Red c'est vraiment cool";
                  href = "https://${config.nodered.domain}";
                  siteMonitor = "https://${config.nodered.domain}";
                };
              }
              {
                "Zigbee2MQTT" = {
                  icon = "zigbee2mqtt.png";
                  description = "Zigbee2MQTT c'est vraiment cool";
                  href = "https://${config.zigbee2mqtt.domain}";
                  siteMonitor = "https://${config.zigbee2mqtt.domain}";
                };
              }
              {
                "Grafana" = {
                  icon = "grafana.png";
                  description = "Grafana c'est vraiment cool";
                  href = "https://${config.influxdb.grafana.domain}";
                  siteMonitor = "https://${config.influxdb.grafana.domain}";
                };
              }
              {
                "Esp Home" = {
                  icon = "esphome.png";
                  description = "Esp Home c'est vraiment cool";
                  href = "https://${config.esp_home.domain}";
                  siteMonitor = "https://${config.esp_home.domain}";
                  widget = {
                    type = "esphome";
                    url = "http://[::1]:${toString config.esp_home.port}";
                  };
                };
              }
            ];
          }
          {
            "Administration" = [
              {
                "Adguard" = {
                  icon = "adguard-home.png";
                  description = "Adguard c'est vraiment cool";
                  href = "https://${config.adguard.domain}";
                  siteMonitor = "https://${config.adguard.domain}";
                  widget = {
                    type = "adguard";
                    url = "https://${config.adguard.domain}";
                    username = "admin"; # unused creds
                    password = "password";
                  };
                };
              }
              {
                "Cockpit" = {
                  icon = "cockpit.png";
                  description = "cockpit c'est vraiment cool";
                  href = "https://${config.cockpit.domain}";
                  siteMonitor = "https://${config.cockpit.domain}";
                };
              }
              {
                "Gatus" = {
                  icon = "gatus.png";
                  description = "gatus c'est vraiment cool";
                  href = "https://${config.gatus.domain}";
                  widget = {
                    type = "gatus";
                    url = "http://192.168.1.202:${toString config.gatus.port}";
                  };
                };
              }
              {
                "incus" = {
                  icon = "incus.png";
                  description = "incus c'est vraiment cool";
                  href = "https://${config.incus.domain}";
                  siteMonitor = "https://${config.incus.domain}";
                };
              }
              {
                "Prometheus" = {
                  icon = "prometheus.png";
                  description = "Prometheus monitoring system";
                  href = "https://${config.prometheus.domain}";
                  siteMonitor = "https://${config.prometheus.domain}";
                  widget = {
                    type = "prometheus";
                    url = "http://[::1]:${toString config.prometheus.port}";
                  };
                };
              }
              {
                "Alertmanager" = {
                  icon = "alertmanager.png";
                  description = "Prometheus Alertmanager";
                  href = "https://${config.prometheus.alertManager.domain}";
                  siteMonitor = "https://${config.prometheus.alertManager.domain}";
                  widget = {
                    type = "prometheusmetric";
                    url = "http://[::1]:${toString config.prometheus.port}";
                    refreshInterval = 5000;
                    metrics = [
                      {
                        label = "Active Alerts";
                        query = "sum(alertmanager_alerts{state=\"active\"})";
                        format = {
                          type = "number";
                          options = {
                            maximumFractionDigits = 0;
                          };
                        };
                      }
                      {
                        label = "Firing Alerts";
                        query = "sum(alertmanager_alerts{state=\"firing\"})";
                        format = {
                          type = "number";
                          options = {
                            maximumFractionDigits = 0;
                          };
                        };
                      }
                    ];
                  };
                };
              }
            ];
          }
        ];

        widgets = [
          {
            prometheusmetric = {
              type = "prometheusmetric";
              url = "http://[::1]:${toString config.prometheus.port}";
              refreshInterval = 10000;
              metrics = [
                {
                  label = "CPU Usage";
                  query = "(100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100))";
                  format = {
                    type = "percent";
                    options = {
                      maximumFractionDigits = 1;
                    };
                  };
                }
                {
                  label = "Memory Usage";
                  query = "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100";
                  format = {
                    type = "percent";
                    options = {
                      maximumFractionDigits = 1;
                    };
                  };
                }
                {
                  label = "Disk Usage";
                  query = "(1 - (node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"})) * 100";
                  format = {
                    type = "percent";
                    options = {
                      maximumFractionDigits = 1;
                    };
                  };
                }
                {
                  label = "Uptime";
                  query = "time() - node_boot_time_seconds";
                  format = {
                    type = "duration";
                  };
                }
              ];
            };
          }
          {
            datetime = {
              text_size = "4x1";
              format = {
                timeStyle = "medium";
                dateStyle = "full";
              };
            };
          }
          {
            logo.icon = "https://raw.githubusercontent.com/onyx-lyon1/onyx/main/apps/onyx/assets/icon_transparent.png";
          }
          {
            openmeteo = {
              label = "Lyon";
              latitude = 45.7779057;
              longitude = 4.8817357;
              timezone = "Europe/Paris";
              units = "metric";
              cache = 5;
              format.maximumFractionDigits = 2;
            };
          }
          {
            resources = {
              cpu = true;
              memory = true;
              disk = [ "/dev/disk/by-partlabel/disk-main-root" ];
              cputemp = true;
              tempmin = 0;
              tempmax = 100;
              uptime = true;
              units = "metric";
              refresh = 300;
              diskUnit = "bytes";
            };
          }
        ];
        kubernetes = [ ];
        docker = [ ];
        customJS = "";
        customCSS = "";
      };
    };
  };
}
