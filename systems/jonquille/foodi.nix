{
  inputs,
  mkSecret,
  config,
  ...
}: {
  imports = [
    inputs.foodi.nixosModules.default
  ];

  age.secrets = mkSecret "foodi" {};

  services.foodi = {
    enable = true;
    environmentFile = config.age.secrets."foodi".path;
    hour = 9;
    minute = 0;
  };
}
