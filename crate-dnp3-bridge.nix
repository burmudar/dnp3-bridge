{
  craneLib,
  qemu,
  pkg-config,
  stdenv,
  libiconv,
}: craneLib.buildPackage {
  src = craneLib.cleanCargoSource ./.;
  strictDeps = true;

  depsBuildBuild = [
    qemu
  ];

  nativeBuildInputs = [
    pkg-config
    stdenv.cc
  ];
  buildInputs = [
    pkg-config
    libiconv
  ];

  CARGO_PROFILE_RELEASE_BUILD_OVERRIDE_DEBUG=true;
  RUST_BACKTRACE=1;
  # stdenv.cc.targetPrefix is empty if this package is called with pkgs.pkgsBuildHost
  # so make sure to call it with base pkgs
  CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER = "${stdenv.cc.targetPrefix}gcc";
  CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_RUNNER = "qemu-arm7";
  cargoExtraArgs = "--target armv7-unknown-linux-gnueabihf";
  # if we don't set these then it uses normal cc which is incorrect, it should use armv7-unknown-linux-gnuabihf-cc / gcc
  HOST_CC = "${stdenv.cc.nativePrefix}cc";
  TARGET_CC = "${stdenv.cc.targetPrefix}cc";
}
