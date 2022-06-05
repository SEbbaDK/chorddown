#!/usr/bin/env crystal

require "colorize"

require "./chorddown"

if ARGV[0]?.nil?
    STDERR.puts "Need to give input file as first argument".colorize(:red)
    exit 1
end

if ARGV[1]? == "text"
    textmode = true
else
    textmode = false
end

begin
    file = ChordDown.load ARGV[0]
rescue ex : ChordDown::MissingOptionException | ChordDown::InvalidOptionException
    STDERR.puts ex.message.colorize(:red)
    exit 2
end

puts "\\documentclass[10pt,a5paper]{book}
\\usepackage[utf8]{inputenc}
\\usepackage[top=1cm,bottom=1cm]{geometry}
\\usepackage{parskip}
\\geometry{a5paper}
\\usepackage{leadsheets}
\\setleadsheets{align-chords=l}
\\setchords{output-notation=german}
\\begin{document}
"

title = file.data["TITLE"]
artist = file.data["ARTIST"]
capo = file.data["CAPO"]? || 0
puts "\\begin{song}{title={#{title}},lyrics={#{artist}},capo={#{capo}}}"

file.text.each do |line|
    if line.is_a? String
        if line == ""
            puts
        else
            puts line + " \\\\"
        end
    elsif line.is_a? ChordDown::ChordedLine
        line.each_segment do |chord, text|
            if textmode || chord.nil?
                printf text
            else
                printf "\\chord{#{chord.to_s.rstrip unless chord.nil?}}#{text}"
            end
        end
        puts " \\\\"
    elsif line.is_a? ChordDown::ChordLine
    end
end

puts "\\end{song}"

puts "\\end{document}"
