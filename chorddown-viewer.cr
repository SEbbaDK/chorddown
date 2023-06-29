#!/usr/bin/env crystal

require "colorize"
require "math"

require "./chorddown"

def raw(s : String | Colorize::Object(String))
    s = s.@object if s.is_a? Colorize::Object(String)
    s
end

def pad(s, w, nw)
    s + (" " * Math.max(0, nw - w))
end

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

header = [] of String | Colorize::Object(String)

ARGV[1]?.try do |arg|
    header << "Transposing by #{arg.to_i}"
    file.transpose arg.to_i
end

t = file.title.colorize.mode(:bold).mode(:underline)
a = file.artists.join(" and ").colorize.mode(:bold)
header << "#{t} by #{a}"

file.data["TUNING"]?.try do |tuning|
    header << "tuning: #{tuning}"
end

file.data["CAPO"]?.try do |capo|
    header << "capo: #{capo}"
end

secs = [header]

file.sections.each do |section|
    sectext = [] of String | Colorize::Object(String)
    sectext << "[#{section.name}]".colorize().mode(:bold) if section.name.presence
    section.data.each do |line|
        if line.is_a? String
            sectext << line
        elsif line.is_a? ChordDown::ChordedLine
            sectext << line.chords.to_s.colorize(:blue).mode(:bold)
            sectext << line.text
        elsif line.is_a? ChordDown::ChordLine
            sectext << line.to_s.colorize(:blue).mode(:bold)
        end
    end
    secs << sectext
end

def len(s : String | Colorize::Object(String))
    s = s.@object if s.is_a? Colorize::Object(String)
    s.size
end

if ENV.has_key?("SCREENSIZE")
    width, height = ENV["SCREENSIZE"].split(",").map { |s| s.to_i }
    remaining = height
    base = 0
    max_width = 0
    current_line = 0
    lines = (1..height).map { |_| "" }
    lines_size = lines.map { |_| 0 }
    secs.each do |s|
        if s.size > remaining
            base = base + max_width
            max_width = 0
            lines.each_index do |i|
                lines[i] = pad(lines[i], lines_size[i], base)
            end
			current_line = 1
        end
    	s.each do |l|
        	w = raw(l).size
        	max_width = w if w > max_width
        	lines[current_line] += l.to_s
        	lines_size[current_line] += w
        	current_line += 1
        	remaining -= 1
    	end
    	current_line += 1
        remaining -= 1
    end
    lines.each { |l| puts l }
else
    secs.each do |s|
        s.each { |l| puts l }
    end
end

exit 0

