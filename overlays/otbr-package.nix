(final: prev: {
  openthread-border-router = prev.openthread-border-router.overrideAttrs (oldAttrs: {
    postFixup = builtins.concatStringsSep "\n" [
      (oldAttrs.postFixup or "")
      ''
        substituteInPlace $out/bin/otbr-firewall \
          --replace-fail '#!/bin/bash' '#!${prev.bash}/bin/bash'
      ''
    ];
  });
})
