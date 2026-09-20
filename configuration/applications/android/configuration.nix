{ pkgs, ... }:

let
  androidSdk = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ "36" ];
    buildToolsVersions = [ "36.0.0" ];

    includeEmulator = true;

    includeSystemImages = true;
    systemImageTypes = [ "google_apis" ];
    abiVersions = [ "x86_64" ];
  };
in
{
  nixpkgs.config.android_sdk.accept_license = true;

  environment.systemPackages = [
    androidSdk.androidsdk
  ];

  users.users.aleks.extraGroups = [
    "kvm"
  ];
}
