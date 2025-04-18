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
        ];
      };

      devShells.x86_64-linux.client = pkgs.mkShell {
        packages = with pkgs; [
          ninja
          clang
          libmpdclient
          curl
          tomlc99
        ];
      };
    };
}
