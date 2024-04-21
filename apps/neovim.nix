{
  config,
  pkgs,
  ...
}: {
  home.file.".config/nvim" = {
    source = pkgs.fetchFromGitHub {
      owner = "NvChad";
      repo = "NvChad";
      rev = "ff99797242f37dbc118baad3d31aa125e08da90f"; #hash of the v2.0 because it does not work using the tag
      hash = "sha256-sy0qSRTjKA87A9z2Qnp/ruMIINbY4C7KBWoPfMDM2rY=";
    };
    recursive = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs; [
      vimPlugins.vim-startify
    ];
    extraConfig = ''
      set shiftwidth=2
      set ignorecase
    '';
    #configure = {
    #  customRC = ''
    #	set shiftwidth=2
    #	'';
    #   };
  };
}
