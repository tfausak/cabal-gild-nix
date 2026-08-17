{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      version = "1.8.4.2";
      assets = {
        aarch64-darwin = {
          suffix = "darwin-arm64";
          hash = "sha256-VcZGNWyj/P/62CLNSoKc0kjqyVF8KXZ0K0Th/ig5rkw=";
        };
        aarch64-linux = {
          suffix = "linux-arm64";
          hash = "sha256-GA9nUTRSW4S7EJyGImTmkJ7FQHLfF+mJcYxU6HYSQTA=";
        };
        x86_64-darwin = {
          suffix = "darwin-x64";
          hash = "sha256-ROtnNMqQLVHY6UKLg4y8az8x4An96ue+6TjkUZMjZyc=";
        };
        x86_64-linux = {
          suffix = "linux-x64";
          hash = "sha256-hjELAPg9lJcG01YmzR9lRjQj7bZXceAv4rRBlwfF0WI=";
        };
      };
      forAllSystems = nixpkgs.lib.genAttrs (builtins.attrNames assets);
      mkCabalGild =
        pkgs:
        let
          asset = assets.${pkgs.stdenv.hostPlatform.system};
        in
        pkgs.stdenv.mkDerivation {
          pname = "cabal-gild";
          inherit version;
          src = pkgs.fetchurl {
            url = "https://github.com/tfausak/cabal-gild/releases/download/${version}/cabal-gild-${version}-${asset.suffix}.tar.gz";
            inherit (asset) hash;
          };
          sourceRoot = ".";
          nativeBuildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            pkgs.autoPatchelfHook
          ];
          buildInputs = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            pkgs.gmp
          ];
          installPhase = ''
            install -Dm755 cabal-gild $out/bin/cabal-gild
          '';
          meta = {
            description = "Formats package descriptions";
            homepage = "https://github.com/tfausak/cabal-gild";
            license = pkgs.lib.licenses.mit;
            mainProgram = "cabal-gild";
            platforms = builtins.attrNames assets;
          };
        };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = mkCabalGild pkgs;
        }
      );

      overlays.default = _final: prev: {
        cabal-gild = mkCabalGild prev;
      };
    };
}
