{
  inputs,
  lib,
  pkgs,
  system,
  username,
  ...
}:
let
  alesis-midi-converter =
    lib.getExe
      inputs.alesis_midi_converter.packages.${system}.alesis-midi-converter;

  # ─── Setup batterie (script simplifié, délègue à alesis-midi-converter) ────
  setupScript = pkgs.writeShellScript "batterie-setup" ''
    set -uexo pipefail
    echo "Batterie setup: Starting..." >&2
    ${alesis-midi-converter} &
    echo "Alesis MIDI converter started" >&2
  '';

  # ─── Desktop items ──────────────────────────────────────────────────────────
  batterieDesktopItem = pkgs.makeDesktopItem {
    name = "batterie-setup";
    desktopName = "Batterie Setup";
    comment = "Lance le setup Ardour/MIDI pour la batterie";
    exec = "${pkgs.systemd}/bin/systemctl --user restart batterie-setup.service";
    icon = "media-playback-start";
    terminal = false;
    categories = [
      "AudioVideo"
      "Music"
    ];
  };

in
{
  # ─── Packages ───────────────────────────────────────────────────────────────
  environment.systemPackages = [
    batterieDesktopItem
  ];

  # ─── udev : détection de la batterie Alesis ─────────────────────────────────
  services.udev.extraRules = ''
    ATTR{idVendor}=="13b2", ATTR{idProduct}=="009f", ACTION=="add",    RUN+="${pkgs.systemd}/bin/systemctl start batterie-udev-trigger@${username}.service"
    ENV{ID_VENDOR_ID}=="13b2", ENV{ID_MODEL_ID}=="009f", ACTION=="remove", RUN+="${pkgs.systemd}/bin/systemctl start batterie-udev-cleanup@${username}.service"
  '';

  # ─── Services système pour bridge udev → user ───────────────────────────────
  systemd.services."batterie-udev-trigger@" = {
    description = "Trigger batterie-setup for user %i";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.su}/bin/su -s ${pkgs.bash}/bin/bash %i -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) ${pkgs.systemd}/bin/systemctl --user restart batterie-setup.service'";
    };
  };

  systemd.services."batterie-udev-cleanup@" = {
    description = "Stop batterie-setup for user %i";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.su}/bin/su -s ${pkgs.bash}/bin/bash %i -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) ${pkgs.systemd}/bin/systemctl --user stop batterie-setup.service'";
    };
  };

  # ─── Service user : batterie-setup ──────────────────────────────────────────
  systemd.user.services.batterie-setup = {
    description = "Setup Ardour and MIDI for Alesis drum kit";
    serviceConfig = {
      Type = "forking";
      ExecStart = setupScript;
      Restart = "no";
      RemainAfterExit = true;
    };
  };
}
