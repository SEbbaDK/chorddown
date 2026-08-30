#!/usr/bin/env crystal

require "colorize"
require "option_parser"

require "./chorddown"
require "./chorddown-songbook-latex"
require "./chorddown-songbook-typst"

enum Format
  Latex
  Typst

  def self.from_s(str)
    if str =~ /l(atex)?/
      return Latex
    elsif str =~ /t(ypst)?/
      return Typst
    end
    raise Exception.new "No format that matches »#{str}«"
  end
end

format = Format::Latex

text_only = false

parser = OptionParser.new do |parser|
  parser.banner = "USAGE: chorddown-songbook [OPTIONS] FILE"

  parser.on "-f FORMAT", "--format=FORMAT", "Select format ( latex / typst )" do |_format|
    format = Format.from_s _format
  end

  parser.on "-t", "--text-only", "Only print the lyrics and no chords" do
    text_only = true
  end

  parser.on "-h", "--help", "Show help" do
    puts parser
    exit
  end
end

parser.parse

if ARGV[0]?.nil?
  STDERR.puts "Need to give input FILE argument".colorize(:red)
  puts parser
  exit 1
end

songbook_path = Path.new ARGV[0]

writer = LatexSongWriter.new text_only if format == Format::Latex
writer = TypstSongWriter.new text_only if format == Format::Typst

writer = writer.not_nil!

writer.write_header

File.read_lines(songbook_path).each do |line|
  if line[0]? == '@'
    begin
      file = ChordDown.load(songbook_path.parent / line[1..])
      writer.write_song file
    rescue ex : ChordDown::MissingOptionException | ChordDown::InvalidOptionException
      STDERR.puts ex.message.colorize(:red)
      exit 2
    end
  else
    puts line
  end
end
