require "./shenmuse"

module ChordDown
    
    class InvalidOptionException < Exception
        def initialize(line_index : Int32, line_text : String)
           @line = line_index
           super("Malformed option at line #{line_index}: »#{line_text}«")
        end
    end
    
    class MissingOptionException < Exception
        def initialize(option)
            super("Missing required option #{option}")
        end
    end
    
    class LineParseException < Exception
        def initialize(reason, slice, line)
            super("#{reason}\nWhile parsing »#{slice}«\nIn line »#{line}«")
        end
    end
    
    class LengthedChord
        getter chord : ShenMuse::Chord
        getter length : Int32
        
        def initialize(chord, length)
            @chord = chord
            @length = length
        end
        
        def to_s
            c = @chord.to_s
            w = " " * Math.max(0, (@length - c.size))
            c + w
        end
        
        def transpose(amount)
            @chord = @chord.transpose(amount)
        end
    end
    
    class ChordLine
        getter initial : Int32
        getter data : Array(LengthedChord)
        
        def initialize(initial, data)
            @initial = initial
            @data = data
        end
        
        def self.from_s(s)
            untrimmed_length = s.size
            s = s.lstrip
            initial = untrimmed_length - s.size
            
            indices = s
                .chars
                .map_with_index{ |c, i| c.uppercase? ? i : -1 }
                .select{ |c| c != -1 }
             
            chords = (0...indices.size).map do |i|
                slice = s[
                    indices[i], 
                    if indices[i + 1]?.nil?
                        s.size
                    else
                        indices[i + 1]
                    end - indices[i]
                ]
                begin
                    chord = ShenMuse::Chord.from_s slice.strip
                rescue ex : ShenMuse::NoteParseException
                    raise LineParseException.new ex.message, slice.strip, s
                end
                LengthedChord.new chord, slice.size
            end

            ChordLine.new initial, chords
        end
        
        def to_s
            " " * @initial + @data.map(&.to_s).join
        end
        
        def transpose(amount)
            @data.each do |c|
                c.transpose amount
            end
        end
    end
    
    class ChordedLine
        getter length : Int32
        getter chords : ChordLine
        getter text : String
        
        def initialize(chords, text)
            @chords = chords
            @text = text
            @length = Math.max(chords.to_s.size, text.size)
        end
    end
    
    class ChordFile
        getter data : Hash(String, String | Int32)
        getter text : Array(String | ChordLine | ChordedLine)
        
        def initialize(data, text)
            @data = data
            @text = text
        end
        
        def transpose(amount)
            @text.each do |t|
                if t.is_a? ChordLine
                    t.transpose amount
                elsif t.is_a? ChordedLine
                    t.chords.transpose amount
                end
            end
        end
    end

    def self.load(file : Path | String)
        file = Path.new file if file.is_a? String
        
        data = Hash(String, String | Int32).new
        l = 0
        parsing_data = true
        chord_line = nil
        text = [] of String | ChordedLine | ChordLine
        # Go through file line by line
        File.each_line file do |line|
            l += 1
            
            # Build the data dictionary
            if parsing_data && /^[A-Z]+:/ =~ line
                begin
                    key, text_value = line.split(":", limit = 2).map{ |s| s.strip }
                    value = text_value.to_i { text_value } # Make it an int if possible
                    data[key] = value
                rescue
                    raise InvalidOptionException.new l, line
                end
            else
                [ "TITLE", "ARTIST" ].each do |required_option|
                    data.fetch required_option do 
                        raise MissingOptionException.new required_option
                    end
                end
                parsing_data = false
            end
            
            # Read the text lines
            if ! parsing_data && /^([| \/]|[ABCDEFGH][#a-z0-9]*)+$/ =~ line
                # We are looking at a chord line
                chord_line.try{ |cl| text << cl }
                chord_line = ChordLine.from_s line
            elsif ! parsing_data
                # We are looking at some other line
                if ! chord_line.nil?
                    text << ChordedLine.new chord_line, line
                    chord_line = nil
                else
                    text << line
                end
            end
        end
        
        if ! chord_line.nil?
            text << chord_line.to_s + "\n"
        end
        
        ChordFile.new data, text
    end

end

