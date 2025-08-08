let
  keys = rec {
    tulipe = [ "age1aq7l5msnq4leddht4sr3sm56v9qu408r94txwyutvz690tlxmdjss9lm94" ];
    lavande = [ "age17w7zsvgvdfr7tdkz9uwy2jhmjlt2273ktu6wtt976782nen0sfkql94ez6" ];
    jonquille = [ "age1ags68rkarp5ewj8dqzq74l48v8q7zdzesed3vp498e352grl3dzsqq3mww" ];
    lilas = [ "age1xphfpwj7v5wwvnuhhqyvwlp7susnmmnx2ttccmn630wd9q8y0a2swy8ekj" ];
    lotus = [ "age1lcw62jx877aqxcwlu855q2x6sq35khqart0we3j6qy8595dmsp6s8xyxnc" ];
    server = jonquille ++ lavande ++ lilas ++ lotus;
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
      "netdata_notify"
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

      "apolline"
      "node_red"

      "foodi"
    ]
    // defineSecrets "lavande" [
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
