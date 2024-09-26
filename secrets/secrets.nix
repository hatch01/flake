let
  eymeric = "age1aq7l5msnq4leddht4sr3sm56v9qu408r94txwyutvz690tlxmdjss9lm94";

  all = [eymeric];
in {
  "tulipe/userPassword.age".publicKeys = all;
  "tulipe/rootPassword.age".publicKeys = all;
  "githubToken.age".publicKeys = all;
  "wifi.age".publicKeys = all;

  "jonquille/userPassword.age".publicKeys = all;
  "jonquille/rootPassword.age".publicKeys = all;
  "jonquille/nextcloudAdmin.age".publicKeys = all;
  "jonquille/nextcloudSecretFile.age".publicKeys = all;
  "jonquille/onlyofficeDocumentServerKey.age".publicKeys = all;
  "jonquille/homepage.age".publicKeys = all;
  "jonquille/selfSignedCert.age".publicKeys = all;
  "jonquille/selfSignedCertKey.age".publicKeys = all;
  "jonquille/smtpPassword.age".publicKeys = all;
  "jonquille/matrix_oidc.age".publicKeys = all;
  "jonquille/matrix_shared_secret.age".publicKeys = all;
  "jonquille/matrix_sliding_sync.age".publicKeys = all;
  "jonquille/cache-priv-key.pem.age".publicKeys = all;
  "jonquille/dyndns.age".publicKeys = all;

  "jonquille/gitlab/databasePasswordFile.age".publicKeys = all;
  "jonquille/gitlab/initialRootPasswordFile.age".publicKeys = all;
  "jonquille/gitlab/secretFile.age".publicKeys = all;
  "jonquille/gitlab/otpFile.age".publicKeys = all;
  "jonquille/gitlab/dbFile.age".publicKeys = all;
  "jonquille/gitlab/jwsFile.age".publicKeys = all;
  "jonquille/gitlab/openIdKey.age".publicKeys = all;
  "jonquille/gitlab/runnerRegistrationConfigFile.age".publicKeys = all;

  "jonquille/authelia/storageKey.age".publicKeys = all;
  "jonquille/authelia/jwtKey.age".publicKeys = all;
  "jonquille/authelia/authBackend.age".publicKeys = all;
  "jonquille/authelia/oAuth2PrivateKey.age".publicKeys = all;
}
