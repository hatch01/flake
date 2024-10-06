{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options = {
    bitcoinClient.enable = mkEnableOption "Enable bitcoin client tools";
  };

  config = mkIf config.bitcoinClient.enable {
    environment.systemPackages = with pkgs; [
      pcsclite
      sparrow
    ];
    hm.home = {
      file.".sparrow/config".text =
        builtins.toJSON
        {
          "mode" = "ONLINE";
          "bitcoinUnit" = "AUTO";
          "unitFormat" = "DOT";
          "blockExplorer" = "https=//mempool.space";
          "feeRatesSource" = "MEMPOOL_SPACE";
          "fiatCurrency" = "EUR";
          "exchangeSource" = "COINGECKO";
          "loadRecentWallets" = true;
          "validateDerivationPaths" = true;
          "groupByAddress" = true;
          "includeMempoolOutputs" = true;
          "notifyNewTransactions" = true;
          "checkNewVersions" = true;
          "theme" = "LIGHT";
          "openWalletsInNewWindows" = false;
          "hideEmptyUsedAddresses" = false;
          "showTransactionHex" = true;
          "showLoadingLog" = true;
          "showAddressTransactionCount" = false;
          "showDeprecatedImportExport" = false;
          "signBsmsExports" = false;
          "preventSleep" = false;
          "recentWalletFiles" = [
            "/home/eymeric/.sparrow/wallets/bitcoin.mv.db"
          ];
          "dustAttackThreshold" = 1000;
          "hwi" = "/tmp/hwi-3.0.02766058920806208471.tmp";
          "enumerateHwPeriod" = 30;
          "useZbar" = true;
          "serverType" = "PUBLIC_ELECTRUM_SERVER";
          "publicElectrumServer" = "ssl=//blockstream.info=700|blockstream.info";
          "useLegacyCoreWallet" = false;
          "useProxy" = false;
          "autoSwitchProxy" = true;
          "maxServerTimeout" = 34;
          "maxPageSize" = 100;
          "usePayNym" = false;
          "mempoolFullRbf" = false;
          "appWidth" = 1072.0;
          "appHeight" = 800.0;
        };
    };
  };
}
