# DNP3 in rust

## Development

We use nix shells for the development environment

* To manually enter the nix development env run `nix develop`.
* To automatically enter the nix development env ensure you have `direnv` installed, then run the following:
```bash
$ echo "use flake" > .envrc
$ direnv allow .
```

## Cross compilation with Nix

### Host platform
To just build for the current platform (which should be x86_64-linux or aarch64-darwin)

1. Build `nix build '.#dnp3-bridge'
2. Run `./result/bin/dnp3-bridge`


### armv7l
The flake can cross-compile to armv7l (from linux).

1. Build `nix build '.#dnp3-bridge-arm'`
2. Run `qemu-arm ./result/bin/dnp3-bridge`
