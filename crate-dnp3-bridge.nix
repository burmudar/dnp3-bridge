{ craneLib
, lib
, qemu
, pkg-config
, patchelf
, stdenv
, target
}:
let
  envTarget = lib.toUpper (builtins.replaceStrings [ "-" ] [ "_" ] target);
  interpreter = if target == "aarch64-linux" then "/lib/ld-linux-aarch64.so.1" else "/lib/ld-linux-armhf.so.3";
in
craneLib.buildPackage {
  src = craneLib.cleanCargoSource ./.;
  strictDeps = true;

  depsBuildBuild = [
    qemu
  ];

  nativeBuildInputs = [
    pkg-config
    stdenv.cc
    patchelf
  ];
  buildInputs = [
    pkg-config
  ];

  installPhase = ''
    mkdir -p $out/bin
    ls -lRa
    cp ./target/${target}/release/dnp3-bridge $out/bin

    patchelf --set-interpreter ${interpreter} $out/bin/dnp3-bridge
  '';
  CARGO_PROFILE_RELEASE_BUILD_OVERRIDE_DEBUG = true;
  RUST_BACKTRACE = 1;
  # stdenv.cc.targetPrefix is empty if this package is called with pkgs.pkgsBuildHost
  # so make sure to call it with base pkgs
  "CARGO_TARGET_${envTarget}_LINKER" = "${stdenv.cc.targetPrefix}gcc";
  "CARGO_TARGET_${envTarget}_RUNNER" = "qemu-arm7";
  cargoExtraArgs = "--target ${target}";
  # if we don't set these then it uses normal cc which is incorrect, it should use armv7-unknown-linux-gnuabihf-cc / gcc
  HOST_CC = "${stdenv.cc.nativePrefix}gcc";
  TARGET_CC = "${stdenv.cc.targetPrefix}gcc";
  CARGO_TARGET_ARCH = "aarch64";
}
