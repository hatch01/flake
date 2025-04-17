{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  pkg-config,
  alsa-lib,
  flatbuffers,
  libjpeg_turbo,
  mbedtls,
  mdns,
  pipewire,
  qt6Packages,
  qmqtt,
  xz,
  sdbus-cpp_2,
  plutovg,
  lunasvg,
  nanopb,
  linalg,
  stb,
}:

let
  inherit (lib)
    cmakeBool
    ;
in

stdenv.mkDerivation rec {
  pname = "hyperhdr";
  version = "21.0.0.0";

  src = fetchFromGitHub {
    owner = "awawa-dev";
    repo = "HyperHDR";
    rev = "master";
    hash = "sha256-FlR915UC1RnQccF7ayr3+o5bugD8z618QIEA2o3lMJQ=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6Packages.wrapQtAppsHook
  ];

  patches = [
    # Allow completly unvendoring hyperhdr
    # need to be merged and a new release created to remove
    (fetchpatch {
      name = "USE_SYSTEM_LIBS";
      url = "https://github.com/awawa-dev/HyperHDR/pull/1158.patch";
      hash = "sha256-Wm12ahepIqQz3mQ2zNycjAtwY3W+leHf23Y14C1YVfg=";
    })
  ];

  cmakeFlags = [
    "-DPLATFORM=linux"
    (cmakeBool "USE_SYSTEM_SDBUS_CPP_LIBS" true)
    (cmakeBool "USE_SYSTEM_MQTT_LIBS" true)
    (cmakeBool "USE_SYSTEM_FLATBUFFERS_LIBS" true)
    (cmakeBool "USE_SYSTEM_MBEDTLS_LIBS" true)
    (cmakeBool "USE_SYSTEM_NANOPB_LIBS" true)
    (cmakeBool "USE_SYSTEM_LUNASVG_LIBS" true)
    (cmakeBool "USE_SYSTEM_STB_LIBS" true)
  ];

  buildInputs = [
    alsa-lib
    flatbuffers
    libjpeg_turbo
    mdns
    mbedtls
    pipewire
    qmqtt
    qt6Packages.qtbase
    qt6Packages.qtserialport
    xz
    sdbus-cpp_2
    lunasvg
    plutovg
    nanopb
    linalg
    stb
  ];

  meta = with lib; {
    description = "Highly optimized open source ambient lighting implementation based on modern digital video and audio stream analysis for Windows, macOS and Linux (x86 and Raspberry Pi / ARM";
    homepage = "https://github.com/awawa-dev/HyperHDR";
    changelog = "https://github.com/awawa-dev/HyperHDR/blob/${src.rev}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = with maintainers; [ hexa ];
    mainProgram = "hyperhdr";
    platforms = platforms.linux;
  };
}
