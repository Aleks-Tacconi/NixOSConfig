{ pkgs, config, ... }:
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
  home.packages = [ androidSdk ];

  home.file.".android-sdk".source = androidSdkPath;

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
