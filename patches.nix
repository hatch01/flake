{
  stable = [
  ];

  unstable = [
    {
      # pr = 510662;
      branch = "mautrix-telegram-go";
      name = "mautrix-telegram";
    }
    {
      pr = 526514;
      name = "ratatouille-lv2: init at 0.9.11";
    }
    {
      # pr = 527621;
      branch = "matrix-authentification-service-unstable";
      name = "matrix-authentification-service module";
    }
    {
      pr = 537261;
      name = "matrix-authentification-service: add support for custom settings";
    }
  ];

  common = [
    {
      pr = 402608;
      name = "satochip-utils";
    }
  ];
}
