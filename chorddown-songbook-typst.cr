require "./chorddown-songbook-base"

class TypstSongWriter < BaseSongWriter
  def initialize(text_only : Bool)
    @text_only = text_only
  end

  def typst_escape(string)
    string
      .gsub("-", "\\-")
      .gsub("`", "\\`")
    # .gsub("#", "\\#")
  end

  def write_header
    if @text_only
      puts "#let iftextmode(body) = [#body]"
      puts "#let unlesstextmode(body) = []"
    else
      puts "#let iftextmode(body) = []"
      puts "#let unlesstextmode(body) = [#body]"
    end
    puts <<-TYPST
        #import "@preview/conchord:0.4.0" : overchord
       
        TYPST
  end

  def write_song(file : ChordDown::ChordFile)
    artists = file.artists.map { |a| '"' + a + '"' }.join(",")

    puts <<-TYPST
        #song(
            title: [#{file.title}],
            artists: (#{artists},),
        )[
        TYPST

    file.sections.each do |section|
      if !@text_only && section.name.try &.downcase.in? ["intro", "outro", "mellemspil", "break"]
        next
      end
      puts "#block(breakable: false)["
      chorus = false
      if section.name.try &.downcase.in? ["omkvæd", "chorus"] # , "bro", "bridge"]
        chorus = true
        print "#emph["
      end
      section.data.each do |line|
        if line.is_a? String
          puts typst_escape(line) + "\\ "
        elsif line.is_a? ChordDown::ChordedLine
          line.each_segment do |chord, text|
            unless chord.nil? || @text_only
              c = chord.chord.to_s.gsub("#", "\\#")
              print "#overchord[#{c}] "
            end
            print typst_escape(text)
          end
          puts "\\ "
        elsif line.is_a? ChordDown::ChordLine
          unless @text_only
            line.data.each do |lchord|
              c = lchord.chord.to_s.gsub("#", "\\#")
              print "#{c} "
            end
            puts "\\ "
          end
        else
          puts "Unhandled type: #{line.class}"
        end
      end
      if chorus
        print "]"
      end
      puts "]"

      # Separate verses (sections)
      puts
    end

    puts "]"
  end
end
