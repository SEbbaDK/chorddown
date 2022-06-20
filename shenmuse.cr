module ShenMuse
    
    class NoteParseException < Exception
        def initialize(s)
            super("No note named »#{s}«")
        end
    end
    
    enum Note
        A
        As
        B
        C
        Cs
        D
        Ds
        E
        F
        Fs
        G
        Gs
        
        def self.from_s(s : String) : Note
            case s
            when "A"  ; A
            when "B"  ; B
            when "H"  ; B
            when "C"  ; C
            when "D"  ; D
            when "E"  ; E
            when "F"  ; F
            when "G"  ; G
            else
                s[1]?.try do |c|
                    root = Note.from_s s[0].to_s
                    if c == '#'
                        return root.transpose(1)
                    elsif c == 'b'
                        return root.transpose(-1)
                    end
                end
                raise NoteParseException.new s
            end
        end
        
        def to_s
            case self
            when A  ; "A"
            when As ; "A#"
            when B  ; "B"
            when C  ; "C"
            when Cs ; "C#"
            when D  ; "D"
            when Ds ; "D#"
            when E  ; "E"
            when F  ; "F"
            when Fs ; "F#"
            when G  ; "G"
            when Gs ; "G#"
            else
                raise "Somethings wrong"
            end
        end
        
        def transpose(val : Int)
            Note.from_value (self.value + val) % 12
        end
    end
    
    class Chord
        getter root : Note
        getter modifier : String
        getter combined : Note | Nil
        
        def initialize(root : Note, modifier = "", combined = nil)
            @root = root
            @modifier = modifier
            @combined = combined
        end
        
        def self.from_s(s) : Chord
            if s.includes? "/"
                root, bass = s
                    .split("/", limit = 2)
                    .map{ |cs| Chord.from_s cs }
                
                Chord.new root.root, root.modifier, bass.root
            else
                root_length = 1
                root_length = 2 if s[1]? == '#' || s[1]? == 'b'
                
                root = Note.from_s s[0, root_length]
                modifier = s.delete_at 0, root_length
                Chord.new root, modifier
            end
        end
        
        def to_s
            if combined.nil?
                "#{@root}#{modifier}"
            else
                "#{@root}#{modifier}/#{@combined}"
            end
        end
        
        def transpose(amount)
            c = @combined
            c = c.as(Note).transpose amount unless c.nil?
            Chord.new (@root.transpose amount), @modifier, c
        end
    end

end

