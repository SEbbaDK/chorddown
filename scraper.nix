{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation {
    name = "chorddown-scraper";

	src = ./.;

    buildInputs = [
		pkgs.crystal
		pkgs.openssl
		pkgs.pkg-config
    ];

    buildPhase = ''
    	mkdir -p $out/bin
    	outfile=$out/bin/chorddown-scraper
		crystal build chorddown-scraper.cr -o $outfile
		#ln -s $outfile $out/bin/cds
    '';

    dontInstall = true;
}

