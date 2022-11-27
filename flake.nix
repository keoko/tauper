{
  description = "A very basic flake";

  inputs = {
    nixpkgs = { url = "github:NixOS/nixpkgs/nixos-22.05"; };
    flake-utils = { url = "github:numtide/flake-utils"; };
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };

      elixir = pkgs.beam.packages.erlang.elixir;
    in
    with pkgs;
    {
      devShell = pkgs.mkShell {
        buildInputs = [
	        inotify-tools
          elixir
          glibcLocales
        ];
      };
    });
}
