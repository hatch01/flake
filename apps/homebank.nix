{
  config,
  pkgs,
  ...
}: {
  hm = {
    home.packages = with pkgs; [
      homebank
    ];

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
