let
  keys = rec {
    tulipe = [ "age1aq7l5msnq4leddht4sr3sm56v9qu408r94txwyutvz690tlxmdjss9lm94" ];
    cyclamen = [ "age1uvmenjw9k5y6qtvlu2clxfxe6ma9a4ecwl2gv36tlc2n99jaq4cq6e5fnt" ];
    jonquille = [ "age1ags68rkarp5ewj8dqzq74l48v8q7zdzesed3vp498e352grl3dzsqq3mww" ];
    lilas = [ "age1xphfpwj7v5wwvnuhhqyvwlp7susnmmnx2ttccmn630wd9q8y0a2swy8ekj" ];
    lotus = [ "age1lcw62jx877aqxcwlu855q2x6sq35khqart0we3j6qy8595dmsp6s8xyxnc" ];
    server = jonquille ++ cyclamen ++ lilas ++ lotus;
    desktop = tulipe;
    all = desktop ++ server;
  };

  secrets =
    defineSecrets "" [
      "githubToken"
    ]
    // defineSecrets "desktop" [
      "wifi"
    ]
    // defineSecrets "server" [
      "smtpPassword"
      "smtpPasswordEnv"
      "cockpit_private_key"
      "restic_key"
      "influx_root_token"
      "wakapi_salt"
      "kvmd"
    ]
    // defineSecrets "tulipe" [
      "userPassword"
      "rootPassword"
    ]
    // defineSecrets "lilas" [
      "rootPassword"
    ]
    // defineSecrets "lotus" [
      "rootPassword"
    ]
    // defineSecrets "jonquille" [
      "rootPassword"

      # Nextcloud
      "nextcloudAdmin"
      "nextcloudSecretFile"
      "nextcloudDspPassword"
      "onlyofficeDocumentServerKey"

      # Homepage
      "homepage"

      # Matrix
      "matrix_shared_secret"
      "matrix_sliding_sync"
      "mas_config"

      # cache
      "cache-priv-key.pem"

      # dynDNS
      "dyndns"

      # Gitlab
      "gitlab/databasePasswordFile"
      "gitlab/initialRootPasswordFile"
      "gitlab/secretFile"
      "gitlab/otpFile"
      "gitlab/dbFile"
      "gitlab/jwsFile"
      "gitlab/openIdKey"
      "gitlab/runnerRegistrationConfigFile"

      # Authelia
      "authelia/storageKey"
      "authelia/jwtKey"
      "authelia/authBackend"
      "authelia/oAuth2PrivateKey"
      "authelia/gitlabSecret"
      "authelia/oAuth2HmacSecret"

      "apolline"
      "node_red"

      # forgejo
      "forgejo_runner_token"
    ]
    // defineSecrets "cyclamen" [
      "rootPassword"
    ];

  defineSecrets =
    name: secrets:
    builtins.listToAttrs (
      map (secret: {
        name = "${if name != "" then "${name}/" else ""}${secret}.age";
        value = {
          publicKeys = keys.${if name != "" then name else "all"};
        };
      }) secrets
    );
in
secrets
