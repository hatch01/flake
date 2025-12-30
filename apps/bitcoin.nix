{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types mkIf mkMerge;
in
{
  options = {
    bitcoin.client.enable = mkEnableOption "Enable bitcoin client tools";
    bitcoin.server = {
      enable = mkEnableOption "Enable bitcoin server";
      port = mkOption {
        type = types.int;
        default = 8333;
        description = "The port of the homepage";
      };
      portRpc = mkOption {
        type = types.int;
        default = 8332;
        description = "The port of the RPC";
      };
    };
  };

  config = mkMerge [
    (mkIf config.bitcoin.client.enable {
      services.pcscd.enable = true;
      environment.systemPackages = with pkgs; [
        pcsclite
        sparrow
      ];
      # hm.home = {
      #   file.".sparrow/config".text = builtins.toJSON {
      #     "mode" = "ONLINE";
      #     "bitcoinUnit" = "AUTO";
      #     "unitFormat" = "DOT";
      #     "blockExplorer" = "https=//mempool.space";
      #     "feeRatesSource" = "MEMPOOL_SPACE";
      #     "fiatCurrency" = "EUR";
      #     "exchangeSource" = "COINGECKO";
      #     "loadRecentWallets" = true;
      #     "validateDerivationPaths" = true;
      #     "groupByAddress" = true;
      #     "includeMempoolOutputs" = true;
      #     "notifyNewTransactions" = true;
      #     "checkNewVersions" = true;
      #     "theme" = "LIGHT";
      #     "openWalletsInNewWindows" = false;
      #     "hideEmptyUsedAddresses" = false;
      #     "showTransactionHex" = true;
      #     "showLoadingLog" = true;
      #     "showAddressTransactionCount" = false;
      #     "showDeprecatedImportExport" = false;
      #     "signBsmsExports" = false;
      #     "preventSleep" = false;
      #     "recentWalletFiles" = [
      #       "/home/eymeric/.sparrow/wallets/bitcoin.mv.db"
      #     ];
      #     "dustAttackThreshold" = 1000;
      #     "hwi" = "/tmp/hwi-3.0.02766058920806208471.tmp";
      #     "enumerateHwPeriod" = 30;
      #     "useZbar" = true;
      #     "serverType" = "PUBLIC_ELECTRUM_SERVER";
      #     "publicElectrumServer" = "ssl=//blockstream.info=700|blockstream.info";
      #     "useLegacyCoreWallet" = false;
      #     "useProxy" = false;
      #     "autoSwitchProxy" = true;
      #     "maxServerTimeout" = 34;
      #     "maxPageSize" = 100;
      #     "usePayNym" = false;
      #     "mempoolFullRbf" = false;
      #     "appWidth" = 1072.0;
      #     "appHeight" = 800.0;
      #   };
      # };
    })
    (mkIf config.bitcoin.server.enable {
      services.bitcoind.bitcoin = {
        enable = true;
        prune = 20 * 1024; # use 20GB
        port = config.bitcoin.server.port;
        rpc = {
          port = config.bitcoin.server.portRpc;
          users.eymeric.passwordHMAC = "a389e7d06c32b0708df55f48b2443754$5ac271542e5ecf9136d13a60149ca4e2ce5e96a47c476fd075817298ac7c7c80";
        };
        extraConfig = ''
          rpcbind=127.0.0.1
          rpcbind=100.64.0.4
          rpcallowip=127.0.0.1
          rpcallowip=100.64.0.0/24
        '';
      };

      networking.firewall.allowedTCPPorts = [ config.bitcoin.server.port ];


      environment.persistence."/persistent".directories = [ config.services.bitcoind.bitcoin.dataDir ];
    })
  ];
}
