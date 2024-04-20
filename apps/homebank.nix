{ config, pkgs, ... }:
let 
pandocCommand = "\"--mathjax --wrap=preserve -L /home/eymeric/.local/share/pandoc/filters/search_replace/filter.lua --filter=/home/eymeric/.local/share/pandoc/filters/asciimathml-pandocfilter/asciimathfilter.js  -f markdown+hard_line_breaks --template=eisvogel\"";
in
{

  home.packages = with pkgs;
  [
    homebank
  ];

  programs.plasma = {
    configFile = {
      "homebank/preferences" = {
        "Exchange" = {
          "DateFmt".value=1;
        };
      };
    };
  };
}

