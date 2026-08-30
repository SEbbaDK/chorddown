abstract class BaseSongWriter
  abstract def write_header
  abstract def write_song(file : ChordDown::ChordFile)
end
