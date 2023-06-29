#!/usr/bin/env crystal

require "colorize"

require "./chorddown"

if ARGV[0]?.nil?
    STDERR.puts "Need to give input file as first argument".colorize(:red)
    exit 1
end

TEXTMODE = (ARGV[1]? == "text")

def clean(string)
    string.gsub('[', " {[").gsub(']', "]}").gsub('#', "\\#")
    #.gsub(/\(([^\)]+)\)/) do |s|
    #    "\\textit{" + s.delete_at(0).delete_at(-1) + "}"
    #end
end

def cclean(string)
    clean(string.gsub('#', "$\\sharp$").gsub('b', "$\\flat$"))
end

def chord(chord : ChordDown::LengthedChord)
    c = chord.chord
    output = "\\chordroot{" + cclean(c.root.to_s) + "}"
    output += "\\chordmod{#{c.modifier}}" unless c.modifier.empty?
    output += "\\!\\textfractionsolidus\\!#{cclean(c.combined.to_s.downcase)}" unless c.combined.nil?
    output + "\\ "
end

def printsong(song)
    begin
        file = ChordDown.load song
    rescue ex : ChordDown::MissingOptionException | ChordDown::InvalidOptionException
        STDERR.puts ex.message.colorize(:red)
        exit 2
    end

    title = file.title
    artist = file.artists.join(" \\& ")
    capo = file.data["CAPO"]?
    comment = file.data["COMMENT"]?
    
    file.transpose(capo.to_i) if capo
    
    puts "\\renewcommand{\\songtitle}{#{title}}"
    puts "\\renewcommand{\\songartist}{#{artist}}"
    puts "\\renewcommand{\\songcomment}{}"
    puts "\\renewcommand{\\songcomment}{#{comment}}" if comment
    puts "\\renewcommand{\\songcapo}{}"
    puts "\\renewcommand{\\songcapo}{#{capo}}" if capo
    puts "{\\presong %"
    
    file.sections.each do |section|
        if /Tabs/i =~ section.name
            next
        end
        if /Chords|Solo|Link|Intro|Outro|Instrumental/i =~ section.name && TEXTMODE
            next
        end
        sectext = ""
        section.data.each do |line|
            if line.is_a? String
                if line.blank?
                    sectext += "\n"
                else
                    sectext += clean(line) + " \\newline\n"
                end
            elsif line.is_a? ChordDown::ChordedLine
                output = ""
                line.each_segment do |chord, text|
                    if TEXTMODE || chord.nil?
                        output += clean(text)
                    else
                        if text.blank?
                            output += "\\postack{#{chord(chord)}}"
                        else
                            output += "\\instack{#{chord(chord)}}" + clean(text)
                        end
                    end
                end
                sectext += output + " {} \\newline\n" unless output.blank?
            elsif line.is_a? ChordDown::ChordLine && ! TEXTMODE
                line.data.each do |lc|
                    sectext += chord(lc)
                end
        		sectext += "\\newline\n"
            end
        end
        # Chop off last newline
        if sectext.includes? "\\newline"
            sectext.rindex("\\newline").try do |i|
                sectext = sectext.sub(i.., "")
            end
        end
        if /^Chorus|Omkvæd|Refrain$/ =~ section.name
            printf "{\\chorusformat " + sectext.squeeze('\n') + "}\n\n"
        else
            printf "{\\verseformat " + sectext.squeeze('\n') + "}\n\n"
        end
    end
    
    puts "\\postsong}"
end

puts "\\documentclass{book}
\\usepackage[utf8]{inputenc}
\\usepackage{parskip,textcomp}

\\usepackage{stackengine}
\\newcommand{\\instack}[2]{\\stackengine{\\stackgap}{\\vphantom{M}#2}{#1}{O}{l}{F}{T}{S}}
\\newcommand{\\postack}[1]{\\stackengine{\\stackgap}{\\vphantom{M}}{#1}{O}{l}{F}{F}{S}}
\\newcommand{\\chordroot}[1]{\\textup{\\textsf{#1}}}
\\newcommand{\\chordmod}[1]{\\raisebox{0.3\\baselineskip}{\\scriptsize{#1}}}

% Stops paragraphs from being broken
\\widowpenalties 1 10000
\\raggedbottom

\\newcommand{\\presong}{}
\\newcommand{\\postsong}{}
\\newcommand{\\chorusformat}{}
\\newcommand{\\verseformat}{}
\\newcommand{\\iftextmode}[1]{}
\\newcommand{\\unlesstextmode}[1]{#1}

\\newcommand{\\songtitle}{}
\\newcommand{\\songartist}{}
\\newcommand{\\songcomment}{}
\\newcommand{\\songcapo}{}
"

puts "\\renewcommand{\\iftextmode}[1]{#1}" if TEXTMODE
puts "\\renewcommand{\\unlesstextmode}[1]{}" if TEXTMODE

songbookfile = Path.new ARGV[0]
songbook = File.read(songbookfile)

puts "\\begin{document}" unless songbook.includes? "---SONGBOOK---"

songbook.lines.each do |l|
    if l == "---SONGBOOK---"
        puts "\\begin{document}"
    elsif l[0]? == '#'
        printsong(Path[songbookfile.dirname] / l.lchop)
    else
        puts l
    end
end

puts "\\end{document}"
