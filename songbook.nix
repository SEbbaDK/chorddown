{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation {
    name = "chorddown-songbook";

	src = ./.;

    buildInputs = [
		pkgs.crystal
    ];

    buildPhase = ''
    	mkdir -p $out/bin
    	outfile=$out/bin/chorddown-songbook
		crystal build chorddown-songbook.cr -o $outfile
    '';

    dontInstall = true;
}

