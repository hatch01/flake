{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    krename
    localsend
    minder
    kshutdown
    textpieces
    kdePackages.filelight
    electrum
    geogebra6

    zap # cybersecurity website test
    (ollama.override {acceleration = "cuda";})

    #math
    nasc
    kalker
  ];
}
