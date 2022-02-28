#!/usr/bin/env crystal

require "colorize"

require "./chorddown"

if ARGV[0]?.nil?
    STDERR.puts "No file given for reading"
    exit 1
end

if ARGV[0] == "--help"
    puts "cdv FILE"
    exit 0
end

begin
    file = ChordDown.load ARGV[0]
rescue ex : ChordDown::MissingOptionException | ChordDown::InvalidOptionException
    STDERR.puts ex.message.colorize(:red)
    exit 2
end

ARGV[1]?.try do |arg|
    puts "Transposing by #{arg.to_i}"
    file.transpose arg.to_i
end

puts "#{file.data["TITLE"].colorize.mode(:bold).mode(:underline)} by #{file.data["ARTIST"].colorize.mode(:bold)}"

file.data["TUNING"]?.try do |tuning|
    puts "tuning: #{tuning}"
end

file.data["CAPO"]?.try do |capo|
    puts "capo: #{capo}"
end

file.text.each do |line|
    if line.is_a? String
        puts line
    elsif line.is_a? ChordDown::ChordedLine
        puts line.chords.to_s.colorize(:blue).mode(:bold)
        puts line.text
    elsif line.is_a? ChordDown::ChordLine
        puts line.to_s.colorize(:blue).mode(:bold)
    end
end

exit 0

