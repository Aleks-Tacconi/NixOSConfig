{
  pkgs,
  config,
  lib,
  osConfig,
  ...
}:
let
  androidPackages = pkgs.androidenv.composeAndroidPackages {
    platformToolsVersion = "35.0.1";
    buildToolsVersions = [
      "35.0.0"
      "36.0.0"
    ];
    platformVersions = [
      "35"
      "36"
    ];
    cmdLineToolsVersion = "11.0";
    includeEmulator = true;
    emulatorVersion = "36.3.10";
    includeSystemImages = true;
    systemImageTypes = [ "google_apis_playstore" ];
    abiVersions = [ "x86_64" ];
    includeNDK = true;
    ndkVersion = "27.1.12297006";
    includeCmake = true;
    cmakeVersions = [ "3.22.1" ];
  };
  androidSdk = androidPackages.androidsdk;
  androidSdkPath = "${androidSdk}/libexec/android-sdk";
  androidSdkStablePath = "${config.home.homeDirectory}/.android-sdk";
  androidNdkPath = "${androidSdkStablePath}/ndk/27.1.12297006";
in
{
  home.packages = [
    androidSdk
    pkgs.eas-cli
  ];

  # Copy the SDK to a writable location so Android Studio can create AVDs,
  # download system images, and write other SDK data. The read-only Nix store
  # symlink approach silently blocks these writes, causing "An Android SDK is
  # required to create an AVD" and the AVD wizard Finish button doing nothing.
  home.activation.setupAndroidSdk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    MARKER="${androidSdkStablePath}/.nix-source"
    if [ ! -d "${androidSdkStablePath}" ] || [ ! -f "$MARKER" ] || [ "$(cat "$MARKER")" != "${androidSdkPath}" ]; then
      $DRY_RUN_CMD rm -rf "${androidSdkStablePath}"
      $DRY_RUN_CMD cp -rL "${androidSdkPath}" "${androidSdkStablePath}"
      $DRY_RUN_CMD chmod -R u+w "${androidSdkStablePath}"
      $DRY_RUN_CMD echo "${androidSdkPath}" > "${androidSdkStablePath}/.nix-source"
    fi
  '';

  home.activation.forceAndroidEmulatorGpuHost = lib.mkIf (osConfig.networking.hostName == "laptop") (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      AVD_DIR="/home/aleks/.android/avd"

      if [ -d "$AVD_DIR" ]; then
        for cfg in "$AVD_DIR"/*.avd/config.ini; do
          [ -f "$cfg" ] || continue

          if ${pkgs.gnugrep}/bin/grep -q '^hw\.gpu\.enabled=' "$cfg"; then
            $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's/^hw\.gpu\.enabled=.*/hw.gpu.enabled=yes/' "$cfg"
          else
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/printf 'hw.gpu.enabled=yes\n' >> "$cfg"
          fi

          if ${pkgs.gnugrep}/bin/grep -q '^hw\.gpu\.mode=' "$cfg"; then
            $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's/^hw\.gpu\.mode=.*/hw.gpu.mode=host/' "$cfg"
          else
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/printf 'hw.gpu.mode=host\n' >> "$cfg"
          fi
        done
      fi
    ''
  );

  home.sessionVariables = {
    ANDROID_HOME = androidSdkStablePath;
    ANDROID_SDK_ROOT = androidSdkStablePath;
    ANDROID_NDK_HOME = androidNdkPath;
    ANDROID_NDK_ROOT = androidNdkPath;
    NDK_HOME = androidNdkPath;
  };

  home.sessionPath = [
    "${androidSdkStablePath}/platform-tools"
    "${androidSdkStablePath}/cmdline-tools/latest/bin"
  ];
}
