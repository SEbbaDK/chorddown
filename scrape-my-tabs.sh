#!/usr/bin/env fish

if [ -z $argv[1] ] || [ -z $argv[2] ]
	echo "USAGE: scrape-my-tabs [INPUT HTML FILE] [OUTPUT FOLDER] <EXCEPT FOLDER>" > /dev/stderr
	echo "Will get the tabs from the ultimate guitar my tabs page given as INPUT HTML FILE, and put them into the OUTPUT FOLDER. If an EXCEPT FOLDER is given, the tool will not fetch the tab if any tab file in the tab folder has a SOURCE tag that matches the tab."
	exit 1
end

if [ ! -z "$argv[3]" ]
    echo "RUNNING IN EXCEPT MODE"
    echo "Finding sources"
    set sources (rg "SOURCE: ([a-z0-9.:/-]+)" --replace '$1' --no-filename)
    echo "Sources found"
end

echo "Extracting tabs"
for t in (pcregrep --buffer-size=1000000 -o1 'https://tabs\.ultimate-guitar\.com/tab/([^\"]*)' $argv[1])
	echo "Found tab: $t"

	if contains "https://tabs.ultimate-guitar.com/tab/$t" $sources
		echo "Skipping because sources contains $t"
		continue
	end

	echo "Fetching $t"
	
	#set filename (echo "$t" | pcregrep -o1 -o2 '(^\d+$)|^([-a-z/0-9]+?)-\d+$' | string replace -- "/" "--")
	set -e IFS
	set output (chorddown-scraper "https://tabs.ultimate-guitar.com/tab/$t")

	set title (echo "$output" | pcregrep -o1 'TITLE: (.+)')
	#set artist (echo "$output" | pcregrep -o1 'ARTIST: (.+)')

	set folder (readlink -f $argv[2])
	set filename (echo "$title" | string replace --all -- ' ' '-' | string lower)
	echo "$output" > "$folder/$filename"
end

