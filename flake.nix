{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    { nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.server = pkgs.mkShell {
        packages = with pkgs; [
          gleam
          erlang
		  rebar3
        ];
      };

      devShells.x86_64-linux.scrobble-client = pkgs.mkShell {
        packages = with pkgs; [
          go
		  mpc
        ];
      };
    };
}
