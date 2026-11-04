# Build the personal Pommy CLI from its Cargo project.
{
  lib,
  rustPlatform,
  makeWrapper,
  libnotify,
}:

rustPlatform.buildRustPackage {
  pname = "pommy";
  version = "0.1.0";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./src
    ];
  };
  cargoLock.lockFile = ./Cargo.lock;
  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
    wrapProgram $out/bin/pommy --prefix PATH : ${lib.makeBinPath [ libnotify ]}
  '';
}
