{
  config,
  mkSecret,
  ...
}: let
  ipv4 = {method = "auto";};
  ipv6 = {
    addr-gen-mode = "default";
    method = "auto";
  };
in {
  age = {
    # secrets = mkSecrets {
    #   "desktop/wifi" = {root = true;};
    # };
    secrets = mkSecret "desktop/wifi" {root = true;};
  };
  #networks
  networking.networkmanager.ensureProfiles = {
    environmentFiles = ["${config.age.secrets."desktop/wifi".path}"];
    profiles = let
      mkWifi = name: args: {
        name = {
          connection = {
            id = name;
            # uuid = "4da44d32-bd84-4e91-9f7b-649567c0bced";
            type = "wifi";
            permissions = "";
          };
          wifi = {
            mode = "infrastructure";
            ssid = name;
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk =
              if (args.password or "") != ""
              then args.password
              else "$${name}_password";
          };
          inherit ipv4 ipv6;
        };
      };
    in
      mkWifi "HHCuisine" {}
      // mkWifi "HHCuisine5G" {password = "$HHCuisine_password";}
      // mkWifi "Onyx" {}
      // mkWifi "Onyx 5G" {password = "$Onyx_password";}
      // mkWifi "Installe onyx !" {password = "$onyx2_password";}
      // {
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
