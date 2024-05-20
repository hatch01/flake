{
  config,
  lib,
  ...
}: let
  ipv4 = {method = "auto";};
  ipv6 = {
    addr-gen-mode = "default";
    method = "auto";
  };
in {
  age = {
    identityPaths = ["/etc/age/key"];
    secrets = {
      wifi.file = ../secrets/wifi.age;
    };
  };
  #networks
  networking.networkmanager.ensureProfiles = {
    environmentFiles = ["${config.age.secrets.wifi.path}"];
    profiles = {
      HHCuisine = {
        connection = {
          id = "HHCuisine";
          uuid = "4da44d32-bd84-4e91-9f7b-649567c0bced";
          type = "wifi";
          permissions = "";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "HHCuisine";
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$HHCuisine_password";
        };
        inherit ipv4 ipv6;
      };
      HHCuisine5G = {
        connection = {
          id = "HHCuisine5G";
          uuid = "af23e6ba-5e1d-490c-898f-0d194055107e";
          type = "wifi";
          permissions = "";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "HHCuisine5G";
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$HHCuisine_password";
        };
        inherit ipv4 ipv6;
      };
      "Installe onyx !" = {
        connection = {
          id = "Installe onyx !";
          uuid = "30112829-d494-4582-beb9-caa22bfc02ca";
          type = "wifi";
          permissions = "";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "Installe onyx !";
        };
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$onyx_password";
        };
        inherit ipv4 ipv6;
      };
      eduroam = {
        connection = {
          id = "eduroam";
          type = "wifi";
          permissions = "";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "eduroam";
        };
        wifi-security = {
          key-mgmt = "wpa-eap";
        };
        "802-1x" = {
          eap = "peap";
          identity = "$eduroam_user";
          password-flags = "1";
          password = "$eduroam_password";
          phase2-auth = "mschapv2";
        };
        inherit ipv4 ipv6;
      };
    };
  };
}
