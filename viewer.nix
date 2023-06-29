{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation {
    name = "chorddown-viewer";

    src = ./.;

    buildInputs = [
        pkgs.pcre
        pkgs.crystal
    ];

    buildPhase = ''
        mkdir -p $out/bin
        outfile=$out/bin/chorddown-viewer
        crystal build chorddown-viewer.cr -o $outfile
        ln -s $outfile $out/bin/cdv
    '';

    dontInstall = true;
}

