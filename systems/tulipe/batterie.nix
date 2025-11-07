{
  inputs,
  lib,
  pkgs,
  system,
  username,
  ...
}:
let
  ardour_projet_path = "/home/${username}/Musique/ardour/drum";
  frame_per_period = "512";

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

    # Change JACK buffer size
    echo "Attempting to set JACK buffer size to ${frame_per_period} ..." >&2
    if ${jack_bufsize} ${frame_per_period} 2>&1; then
      echo 'JACK buffer size set to ${frame_per_period}' >&2
    else
      echo "jack_bufsize failed with exit code $?" >&2
    fi

    # Start Ardour session
    ${ardour} ${ardour_projet_path} &
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
      exit 1
    fi

    # Disconnect Alesis MIDI port from DrumGizmo if connected
    echo "Disconnecting Alesis from DrumGizmo..." >&2
    ALESIS_PORT=$(${jack_lsp} | ${grep} -i "alesis.*capture" | ${head} -n1)
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
      exit 1
    fi
    echo "Found RtMidiOut: $RTMIDI_OUT" >&2

    ${jack_connect} "$RTMIDI_OUT" "$DRUMGIZMO_IN" && echo "Connected $RTMIDI_OUT to $DRUMGIZMO_IN" >&2

    echo "Setup complete!" >&2
  '';

  udevTriggerScript = pkgs.writeShellScript "batterie-udev-trigger" ''
    set -uexo pipefail
    echo "Alesis device connected, triggering systemd service" | systemd-cat
    systemctl --user --machine=${username}@.host restart batterie-setup.service
  '';

  udevCleanupScript = pkgs.writeShellScript "batterie-udev-cleanup" ''
    set -uexo pipefail
    echo "Alesis device removed, stopping systemd service" | systemd-cat
    systemctl --user --machine=${username}@.host stop batterie-setup.service
  '';

in
{
  services.udev.extraRules = ''
    ATTR{idVendor}=="13b2", ATTR{idProduct}=="009f", ACTION=="add", RUN+="${udevTriggerScript}"
    ENV{ID_VENDOR_ID}=="13b2", ENV{ID_MODEL_ID}=="009f", ACTION=="remove", RUN+="${udevCleanupScript}"
  '';

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
