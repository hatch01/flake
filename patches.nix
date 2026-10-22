{
  stable = [ ];

  unstable = [
    {
      # pr = 510662;
      branch = "mautrix-telegram-go";
      name = "mautrix-telegram";
    }
    {
      pr = 553636;
      name = "sforzando";
    }
    {
      pr = 553642;
      name = "dsksfzplayer";
    }
    {
      pr = 553949;
      name = "guitarmidi-lv2";
    }
    {
      pr = 559444;
      name = "tone3000";
    }
    {
      pr = 573587;
      name = "gdi2m";
    }
    {
      pr = 569444;
      name = "nix-ccache writeCBin";
    }
    {
      # pr = 576853;
      branch = "php";
      name = "php patch";
    }
    {
      pr = 576411;
      name = "fix musescore build";
    }
    {
      branch = "drumgizmo";
      name = "use latest drumgizmo patch";
    }
    {
      pr = 575861;
      name = "fix v4l2";
    }
  ];

  common = [
    {
      pr = 402608;
      name = "satochip-utils";
    }
    {
      pr = 576147;
      name = "patch nom";
    }
  ];
}
