{
  lib,
  stdenv,
  fetchFromGitHub,
}:
stdenv.mkDerivation rec {
  pname = "lialg";
  version = "2.2";

  src = fetchFromGitHub {
    owner = "sgorsten";
    repo = "linalg";
    tag = "v${version}";
    hash = "sha256-2I+sJca0tf/CcuoqaldfwPVRrzNriTXO60oHxsFQSnE=";
  };

  installPhase = ''
    mkdir -p $out/include
    cp linalg.h $out/include/
  '';

  meta = with lib; {
    description = "Single-header, public domain, short vector math library for C++";
    homepage = "https://github.com/sgorsten/linalg";
    license = licenses.publicDomain;
    maintainers = [ maintainers.eymeric ];
  };
}
