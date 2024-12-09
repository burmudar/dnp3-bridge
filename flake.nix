{
  description = "flake for rust development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    unstable-nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, unstable-nixpkgs, crane, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (localSystem:
      let
        crossSystemArmv7 = {
          system = "armv7l-linux";
          # we need to set this otherwise we errors like:
          # cc1: error: '-mfloat-abi=hard': selected architecture lacks an FPU
          gcc = {
            fpu = "vfp";
          };
        };
        crossSystemArm = {
          system = "aarch64-linux";
          # we need to set this otherwise we errors like:
          # cc1: error: '-mfloat-abi=hard': selected architecture lacks an FPU
          # gcc = {
          #   fpu = "vfp";
          # };
        };
        overlays = [ rust-overlay.overlays.default ];
        pkgs = import nixpkgs {
          inherit overlays;
          system = localSystem;
        };
        pkgsArmv7 = import nixpkgs {
          inherit overlays localSystem; crossSystem = crossSystemArmv7;
        };
        pkgsArm = import nixpkgs {
          inherit overlays localSystem; crossSystem = crossSystemArm;
        };

        lib = pkgsArmv7.pkgsBuildHost.lib;

        craneCrossBuild = (pkgs: target:
          let
            # we want to override the buildHosts rust with the additional target
            craneLib = (crane.mkLib pkgs).overrideToolchain (p: p.pkgsBuildHost.rust-bin.stable.latest.default.override { targets = [ target ]; });
          in
          pkgs.callPackage ./crate-dnp3-bridge.nix { inherit craneLib target; }
        );

        craneLib = (crane.mkLib pkgs);

        # we call it with the base pkgs here and not just pkgsBuildHost, since the base pkgs has information regarding the target / host systems which
        # is used in the crate
        dnp3-bridge-armv7 = craneCrossBuild pkgsArmv7 "armv7-unknown-linux-gnueabihf";
        dnp3-bridge-arm = craneCrossBuild pkgsArm "aarch64-unknown-linux-gnu";

        # Use lib.sources.trace to see what the filter below filters
        src = lib.cleanSourceWith {
          src = craneLib.path ./.;
          name = "source";
        };


        commonArgs = {
          inherit src;
          strictDeps = true;

          nativeBuildInputs = [
            pkgs.pkg-config
          ];

          buildInputs = [
            pkgs.glibc.dev
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.libiconv
            pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
          ];
        };
        cargoArtifacts = craneLib.buildDepsOnly (commonArgs);

        # Build the actual Rust package
        # this actually builds the package with `--release`
        dnp3-bridge = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;
        });


      in
      {

        checks = {
          default = dnp3-bridge;
          inherit dnp3-bridge;
          inherit dnp3-bridge-armv7;
          inherit dnp3-bridge-arm;

          dnp3-bridge-clippy = craneLib.cargoClippy (commonArgs // {
            inherit cargoArtifacts;
            cargoClippyExtraArgs = "-- -D warnings";
          });
        };

        packages = {
          default = dnp3-bridge;
          inherit dnp3-bridge-armv7;
          inherit dnp3-bridge-arm;
        };


        formatter = pkgs.nixpkgs-fmt;

        devShells.default = craneLib.devShell (commonArgs // {
          packages = (commonArgs.nativeBuildInputs or [ ]) ++ (commonArgs.buildInputs or [ ]) ++ [
            pkgs.rust-analyzer
          ];

        });
        # shell to inspect the env when we cross compile to arm
        devShells.dnp3-arm = craneLib.devShell {
          inputsFrom = [ dnp3-bridge-arm ];
        };
        # shell to inspect the env when we cross compile to arm
        devShells.dnp3-armv7 = craneLib.devShell {
          inputsFrom = [ dnp3-bridge-armv7 ];
        };
      });
}
