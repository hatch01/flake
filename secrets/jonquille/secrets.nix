let
  eymeric = "age17w7zsvgvdfr7tdkz9uwy2jhmjlt2273ktu6wtt976782nen0sfkql94ez6";

  all = [eymeric];
in {
  "userPassword.age".publicKeys = all;
  "rootPassword.age".publicKeys = all;
  "githubToken.age".publicKeys = all;
  "nextcloudAdmin.age".publicKeys = all;
  "nextcloudSecretFile.age".publicKeys = all;
  "onlyofficeKey.age".publicKeys = all;
  "homepage.age".publicKeys = all;
  "selfSignedCert.age".publicKeys = all;
  "selfSignedCertKey.age".publicKeys = all;
  "smtpPassword.age".publicKeys = all;
  "matrix_oidc.age".publicKeys = all;
  "matrix_shared_secret.age".publicKeys = all;
  "matrix_sliding_sync.age".publicKeys = all;
  "cache-priv-key.pem.age".publicKeys = all;
  "dyndns.age".publicKeys = all;

  "gitlab/databasePasswordFile.age".publicKeys = all;
  "gitlab/initialRootPasswordFile.age".publicKeys = all;
  "gitlab/secretFile.age".publicKeys = all;
  "gitlab/otpFile.age".publicKeys = all;
  "gitlab/dbFile.age".publicKeys = all;
  "gitlab/jwsFile.age".publicKeys = all;
  "gitlab/openIdKey.age".publicKeys = all;
  "gitlab/runnerRegistrationConfigFile.age".publicKeys = all;

  "authelia/storageKey.age".publicKeys = all;
  "authelia/jwtKey.age".publicKeys = all;
  "authelia/authBackend.age".publicKeys = all;
  "authelia/oAuth2PrivateKey.age".publicKeys = all;
}
