{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    homebank
  ];

  hm = {
    programs.plasma = {
      configFile = {
        "homebank/preferences" = {
          "Exchange" = {
            "DateFmt".value = 1;
          };
        };
      };
    };
  };
}
