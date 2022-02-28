{ pkgs ? import <nixpkgs> {} }:
let
	call = file: (import file) { inherit pkgs; };
in
{
	viewer = call ./viewer.nix;
	scraper = call ./scraper.nix;
}
