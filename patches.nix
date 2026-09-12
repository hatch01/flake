{
  stable = [
    {
      pr = 537545;
      name = "headscale: 0.28.0 -> 0.29.2";
    }
    {
      pr = 547112;
      name = "headscale: 0.29.2 -> 0.29.3";
    }
    {
      pr = 537576;
      name = "headplane: 0.6.2 -> 0.6.3";
    }
    {
      pr = 538802;
      name = "headplane: 0.6.3 -> 0.7.0, inherit headplane-agent from headplane, nixos/headplane: clean up deprecated options";
    }
  ];

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
  ];

  common = [
    {
      pr = 402608;
      name = "satochip-utils";
    }
  ];
}
