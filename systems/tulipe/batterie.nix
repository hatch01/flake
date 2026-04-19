{
  inputs,
  lib,
  pkgs,
  system,
  username,
  ...
}:
let
  frame_per_period = 256; # Buffer size for low-latency monitoring
  # Buffer size 256 @ 48kHz = ~5.3ms latency

  jack_bufsize = lib.getExe' pkgs.jack-example-tools "jack_bufsize";
  jack_lsp = lib.getExe' pkgs.jack-example-tools "jack_lsp";
  jack_disconnect = lib.getExe' pkgs.jack-example-tools "jack_disconnect";
  jack_connect = lib.getExe' pkgs.jack-example-tools "jack_connect";
  ardour = lib.getExe pkgs.ardour;
  alesis-midi-converter =
    lib.getExe
      inputs.alesis_midi_converter.packages.${system}.alesis-midi-converter;

  # Shell utilities
  xargs = lib.getExe' pkgs.findutils "xargs";
  grep = lib.getExe pkgs.gnugrep;
  head = lib.getExe' pkgs.coreutils "head";
  sleep = lib.getExe' pkgs.coreutils "sleep";
  systemd-inhibit = lib.getExe' pkgs.systemd "systemd-inhibit";

  batterieDesktopItem = pkgs.makeDesktopItem {
    name = "batterie-setup";
    desktopName = "Batterie Setup";
    comment = "Lance le setup Ardour/MIDI pour la batterie";
    exec = "${pkgs.systemd}/bin/systemctl --user restart batterie-setup.service";
    icon = "media-playback-start"; # ou le chemin vers une icône personnalisée
    terminal = false;
    categories = [
      "AudioVideo"
      "Music"
    ];
  };

  setupScript = pkgs.writeShellScript "batterie-setup" ''
    set -uexo pipefail
    echo "Batterie setup: Starting..." >&2

    # Start alesis-midi-converter
    ${alesis-midi-converter} &
    echo "Alesis MIDI converter started" >&2

    # Wait for JACK server to be available
    for i in {1..30}; do
      if ${jack_lsp} >/dev/null 2>&1; then
        echo 'JACK server is available' >&2
        break
      fi
      ${sleep} 0.5
    done

    # Change JACK buffer size for low latency
    echo "Attempting to set JACK buffer size to ${toString frame_per_period} ..." >&2
    if ${jack_bufsize} ${toString frame_per_period} 2>&1; then
      echo 'JACK buffer size set to ${toString frame_per_period}' >&2
    else
      echo "jack_bufsize failed with exit code $?" >&2
    fi

    # Start Ardour session
    ${ardour} &
    echo "Ardour started with drum session" >&2

    # Wait for DrumGizmo to load in Ardour
    echo "Waiting for DrumGizmo to be available..." >&2
    for i in {1..60}; do
      DRUMGIZMO_IN=$(${jack_lsp} -c | ${grep} -i drumgizmo | ${grep} -i in | ${head} -n1 | ${xargs} || true)
      if [ -n "$DRUMGIZMO_IN" ]; then
        echo "DrumGizmo MIDI input found: $DRUMGIZMO_IN" >&2
        break
      fi
      ${sleep} 0.5
    done

    if [ -z "$DRUMGIZMO_IN" ]; then
      echo 'DrumGizmo MIDI input not found after 30 seconds' >&2
      echo "Available JACK ports:" >&2
      ${jack_lsp} -c 2>&1 || true
    fi

    # Disconnect Alesis MIDI port from DrumGizmo if connected
    echo "Disconnecting Alesis from DrumGizmo..." >&2
    ALESIS_PORT=$(${jack_lsp} | ${grep} -i "alesis.*capture" | ${head} -n1 || true)
    if [ -n "$ALESIS_PORT" ]; then
      ${jack_disconnect} "$ALESIS_PORT" "$DRUMGIZMO_IN" 2>/dev/null && echo "Disconnected $ALESIS_PORT from $DRUMGIZMO_IN" >&2 || echo "Alesis was not connected to DrumGizmo" >&2
    else
      echo "Alesis port not found" >&2
    fi

    # Connect RtMidiOut to DrumGizmo
    RTMIDI_OUT=$(${jack_lsp} | ${grep} -i 'RtMidiout' | ${head} -n1 | ${xargs} || true)
    if [ -z "$RTMIDI_OUT" ]; then
      echo 'RtMidiOut Client:RtMidi output not found' >&2
      echo "Available JACK MIDI ports:" >&2
      ${jack_lsp} -t midi 2>&1 || true
    else
      echo "Found RtMidiOut: $RTMIDI_OUT" >&2
    fi

    if [ -n "$RTMIDI_OUT" ] && [ -n "$DRUMGIZMO_IN" ]; then
      ${jack_connect} "$RTMIDI_OUT" "$DRUMGIZMO_IN" && echo "Connected $RTMIDI_OUT to $DRUMGIZMO_IN" >&2 || echo "Failed to connect $RTMIDI_OUT to $DRUMGIZMO_IN" >&2
    else
      echo "Skipping JACK connection (missing ports)" >&2
    fi

    echo "Setup complete!" >&2
  '';

in
{
  imports = [
    inputs.musnix.nixosModules.musnix
  ];

  environment.systemPackages = [ batterieDesktopItem ];

  # Enable musnix for real-time audio support
  musnix.enable = true;
  musnix.soundcardPciId = "07:00.6";
  # musnix.rtirq.enable = true;
  musnix.kernel.packages = pkgs.linuxPackages_latest;
  musnix.kernel.realtime = true;

  # Enable rtkit for realtime scheduling
  security.rtkit.enable = true;
  security.rtkit.args = [
    "--our-realtime-priority=89"
    "--max-realtime-priority=85"
  ];

  services.pipewire.extraConfig.pipewire."92-low-latency" = {
    "context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.quantum" = frame_per_period;
      "default.clock.min-quantum" = frame_per_period;
      "default.clock.max-quantum" = frame_per_period;
    };
  };

  systemd.user.services.pipewire = {
    serviceConfig = {
      LimitRTPRIO = 95;
      LimitMEMLOCK = "infinity";
      LimitNICE = 40; # allows nice -19
    };
  };

  systemd.user.services.pipewire-pulse = {
    serviceConfig = {
      LimitRTPRIO = 95;
      LimitMEMLOCK = "infinity";
    };
  };

  services.udev.extraRules = ''
    # Trigger system service when Alesis Turbo drum kit is connected
    ATTR{idVendor}=="13b2", ATTR{idProduct}=="009f", ACTION=="add", RUN+="${pkgs.systemd}/bin/systemctl start batterie-udev-trigger@${username}.service"
    # Stop user service when device is removed
    ENV{ID_VENDOR_ID}=="13b2", ENV{ID_MODEL_ID}=="009f", ACTION=="remove", RUN+="${pkgs.systemd}/bin/systemctl start batterie-udev-cleanup@${username}.service"
  '';

  # System-level services that properly transition to user context.
  # We use 'su' instead of 'systemctl --machine' to avoid PAM session issues
  # that occur in recent systemd versions when udev tries to create user sessions.
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

  systemd.user.services.batterie-setup = {
    description = "Setup Ardour and MIDI for Alesis drum kit";
    serviceConfig = {
      Type = "forking";
      ExecStart = "${systemd-inhibit} --what=sleep --why='Batterie active' ${setupScript}";
      Restart = "no";
      RemainAfterExit = true;
    };
  };
}
