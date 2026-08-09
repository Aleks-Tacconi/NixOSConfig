{ pkgs, quickshell, ... }:

let
  upstreamQs = quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  patchedUnwrapped = upstreamQs.unwrapped.overrideAttrs (previous: {
    patches = (previous.patches or [ ]) ++ [ ./patches/app-menu-registrar.patch ];
  });
  qs = upstreamQs.overrideAttrs (previous: {
    installPhase = ''
      mkdir -p $out
      cp -r ${patchedUnwrapped}/* $out
    '';
    passthru = (previous.passthru or { }) // {
      unwrapped = patchedUnwrapped;
      withModules =
        modules:
        qs.overrideAttrs (attrs: {
          buildInputs = attrs.buildInputs ++ modules;
        });
    };
  });
in
pkgs.stdenv.mkDerivation {
  pname = "quickshell-wrapper";
  version = "unstable";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    pkgs.makeWrapper
    pkgs.qt6.wrapQtAppsHook
  ];

  buildInputs = with pkgs; [
    qs
    kdePackages.qtwayland
    kdePackages.qtpositioning
    kdePackages.qtlocation
    kdePackages.syntax-highlighting
    gsettings-desktop-schemas
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qt5compat
    qt6.qtimageformats
    qt6.qtmultimedia
    qt6.qtpositioning
    qt6.qtquicktimeline
    qt6.qtsensors
    qt6.qtsvg
    qt6.qttools
    qt6.qttranslations
    qt6.qtvirtualkeyboard
    qt6.qtwayland
    kdePackages.kirigami
    kdePackages.kdialog
    vulkan-headers
    libdrm
    cpptrace
    jemalloc
    mesa
  ];

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${qs}/bin/qs $out/bin/qs \
      --prefix XDG_DATA_DIRS : ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}
  '';

  passthru = qs.passthru // {
    wrapped = qs;
  };
}
