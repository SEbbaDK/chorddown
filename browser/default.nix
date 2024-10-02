{ pkgs ? import <nixpkgs> {} }:
pkgs.crystal.buildCrystalPackage rec {
    pname = "chorddown-browser";
    version = builtins.head (builtins.match ".*\nversion: ([0-9.]+).*" (builtins.readFile ./shard.yml));
    unpackPhase = ''
    	mkdir -p browser
    	cp ${../.}/{chorddown.cr,shenmuse.cr} ./
    	cp -r ${./.}/{shard.yml,*.cr} ./
    	substituteInPlace chorddown-browser.cr \
    		--replace "../" "./"
    '';

	format = "shards";
	lockFile = ./shard.lock;
	shardsFile = ./shards.nix;

	preBuild = ''
		echo PREBUILD
		ls
	'';

    buildInputs = [
        pkgs.pcre
        pkgs.crystal
        pkgs.unibilium
        pkgs.readline
    ];

    doCheck = false;
    doInstallCheck = false;
}

