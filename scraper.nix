{ pkgs ? import <nixpkgs> {} }:
pkgs.stdenv.mkDerivation {
    name = "chorddown-scraper";

    src = ./.;

    buildInputs = [
        pkgs.crystal
        pkgs.openssl
        pkgs.pkg-config
        pkgs.pcre
        pkgs.ripgrep
        pkgs.fish
    ];

    buildPhase = ''
        mkdir -p $out/bin
        outfile=$out/bin/chorddown-scraper
        crystal build chorddown-scraper.cr -o $outfile

        outfile=$out/bin/chorddown-scraper-my-tabs
        echo '#!${pkgs.fish}/bin/fish' > $outfile
        echo 'set --append PATH ${pkgs.pcre}/bin' >> $outfile
        echo 'set --append PATH ${pkgs.ripgrep}/bin' >> $outfile
        cat < scrape-my-tabs.fish >> $outfile
        chmod +x $outfile
    '';

    dontInstall = true;
}

