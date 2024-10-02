#!/usr/bin/env -S crystal run -p

require "../chorddown"
require "crysterm"


# ===============================================
# File Loading
# ===============================================

if ARGV.size > 0 && (ARGV[0] == "-h" || ARGV[0] == "--help")
    puts "chorddown-browser PATHTOBROWSE"
    exit 0
end

root_dir = ARGV.size > 0 ? ARGV[0] : "."

enum ChordFileError
	NotFile
	Empty
	NoTitle
	Unreadable
end

paths = Dir.glob(root_dir + "/**/**")
channel = Channel(NamedTuple(
	path: String,
	result: ChordDown::ChordFile | ChordFileError
)).new(paths.size)

def readfile(channel, path)
    if ! File.file? path
        return ChordFileError::NotFile
    end
    if File.empty? path
        return ChordFileError::Empty
    end
	File.open(path, "r") do |file|
    	s = Bytes.new 5
    	file.read s
		if s == "TITLE".to_slice
			begin
    			file.close
    			chord_file = ChordDown.load path
    			return chord_file
			rescue
    			return ChordFileError::Unreadable
			end
		else
    		return ChordFileError::NoTitle
		end
	end
end

paths.each do |path|
    spawn do
        channel.send({ path: path, result: readfile(channel, path) })
    end
end

files = Hash(String, ChordDown::ChordFile | ChordFileError).new
(1..paths.size).each do |_|
	result = channel.receive
	files[result[:path]] = result[:result]
end

# files.each do |p, r|
#     res = r.is_a?(ChordDown::ChordFile) ? "read" : r.to_s
# 	puts(p + " → " + res)
# end


# ===============================================
# Rendering
# ===============================================

def render_line(line : String)
    line
end

def render_line(line : ChordDown::ChordedLine)
    "{red-fg}#{line.chords.to_s}{/red-fg}\n#{line.text}"
end

def render_line(line : ChordDown::ChordLine)
    "{red-fg}#{line.to_s}{/red-fg}"
end

def render_section(section)
    sectext = [] of String
    sectext << "{bold}[#{section.name}]{/bold}" if section.name.presence
    section.data.each do |line|
        sectext << render_line line
    end
    return sectext.join("\n")
end

def render_sections(sections)
    sections.map{|s| render_section(s) }.join("\n")
end


# ===============================================
# Custom Widget Classes
# ===============================================

class ScrollList < Crysterm::Widget::List
    @heightcache : Nil | Int32 = nil

    def height : Int32
		if @heightcache.nil?
    		height = aheight - iheight
    		@heightcache = height
    		return height
		else
			return @heightcache.as Int32
		end
    end

	def check_scroll(offset = 1)
		if @selected < @child_base + 4
    		@child_base -= offset
		elsif @selected - @child_base >= height - 4
    		@child_base += offset
		end

		@child_base = @child_base.clamp(0, items.size - height)
	end

	@on_select_callback : (Int32 ->) | Nil = nil

	def on_select(&callback : Int32 ->)
    	@on_select_callback = callback
	end

	def on_select_call
    	@on_select_callback.try &.call(@selected)
	end

	def on_keypress(e)
    	#Here to disable super method
	end

	def select_relative(offset)
    	new = (selected + offset).clamp(0, items.size - 1)
    	actual_offset = new - selected
    	move actual_offset
    	check_scroll actual_offset.abs
    	on_select_call
	end

    def select_and_scroll(target)
    	offset = @selected - target
    	selekt target
    	check_scroll offset.abs
    	on_select_call
    end

    def select_top
		select_and_scroll 0
    end

    def select_bottom
		selekt items.size - 1
		@child_base = items.size - height
    end
end

class SongList < ScrollList
	property chord_files = [] of ChordDown::ChordFile
	def setup_items
    	@items.clear
		chord_files.each do |f|
        	append_item [
        		"{red-fg}",
        		f.artists.join(" & ")[0..20].ljust(24),
        		"{/red-fg}",
        		f.title[0..36]
    		].join
		end
	end

	def current_song
    	return chord_files[selected]
	end
end

class SectionViewer < Crysterm::Widget::Box
    @input = true

	@height_cache = -1
	def height
		if @height_cache == -1
			@height_cache = aheight - iheight
		end
		return @height_cache
	end

    @song : ChordDown::ChordFile | Nil = nil
    @sections = [] of String
    @current_section = 0
	getter song
	def song=(file : ChordDown::ChordFile)
		@song = file
		setup_sections file
		update_content
	end

	def setup_sections(song)
		@current_section = 0
		@sections.clear
		song.sections.each do |s|
    		t = [] of String
    		l = 0
    		s.name.try do |n|
        		if ! n.empty?
            		t << "{bold}[#{n}]{/bold}"
            		l += 1
        		end
    		end
    		s.data.each do |line|
        		r = render_line line
        		t << r
        		l += 1 + r.count('\n')
        		if l > height - 4
            		@sections << t.join("\n")
            		t = [] of String
            		l = 0
        		end
    		end
    		@sections << t.join("\n")
		end
	end

	def update_content
    	@song.try do |s|
    		c = [] of String
    		header = "{bold}#{s.title}{/bold} by #{s.artists.join(" & ")}"
    		if s.key_change != 0
        		header += "  [transposed by #{s.key_change}]"
    		end
    		header += "\n"
    		c << header
        	c << @sections[@current_section..].join("\n")
        	@content = c.join("\n")
    	end
	end

	def next_section
    	if @current_section < @sections.size - 1
        	@current_section += 1
    	end
    	update_content
	end

	def previous_section
    	if @current_section > 0
        	@current_section -= 1
    	end
    	update_content
	end

	def transpose(amount)
    	@song.try do |s|
        	s.transpose amount
        	setup_sections s
        	update_content
    	end
	end
end


# ===============================================
# TUI Behaviour Setup
# ===============================================

help_browser = "up/down: {bold}j/k{/bold}    top/bottom: {bold}g/G{/bold}    jump {bold}u{/bold}p/{bold}d{/bold}own    {bold}r{/bold}andom    sort by {bold}a{/bold}rtist/{bold}t{/bold}itle    {bold}q{/bold}uit"
help_viewer = "up/down: {bold}j/k{/bold}    transpose up/down: {bold}+/-{/bold}    back: {bold}h/esc{/bold}    {bold}q{/bold}uit"

class ChorddownBrowser
    include Crysterm

    s = Screen.new(
    	show_fps: nil,
    	optimization: OptimizationFlag::All
	)

    songlist = SongList.new \
    	name: "Songlist",
    	parent: s,
    	screen: s,
    	top: 2,
    	left: 4,
    	width: 60,
    	height: "100%-5",
    	styles: Styles.new(selected: Style.new(bold: true, fg: "red", bg: "black"))

    preview = Widget::Box.new \
    	name: "Preview",
    	parent: s,
    	screen: s,
    	top: 2,
    	left: 68,
    	width: "100%-72",
    	height: "100%-5",
    	style: Style.new(border: 1),
    	content: "hey"

	help = Widget::Box.new \
    	name: "Help",
    	parent: s,
    	screen: s,
    	top: "100%-2",
    	left: 4,
    	width: "100%-8",
    	height: 1,
    	content: help_browser

    viewer = SectionViewer.new \
    	name: "Preview",
    	parent: s,
    	screen: s,
    	top: 2,
    	left: 4,
    	width: "100%-8",
    	height: "100%-5",
    	visible: false

	files.each_value do |v|
    	if v.is_a? ChordDown::ChordFile
        	songlist.chord_files.push v
        end
	end
	songlist.chord_files.sort! do |a,b|
    	a.title <=> b.title
	end
	songlist.setup_items
	songlist.focus

	s.on(Event::KeyPress) do |e|
    	if e.char == 'q'
        	s.destroy
        	exit
    	end
	end

    songlist.on(Event::KeyPress) do |e|
    	if e.char == 'j' || e.key == Tput::Key::Down
        	songlist.select_relative 1
        	e.accept
        	s.render
    	elsif e.char == 'k' || e.key == Tput::Key::Up
        	songlist.select_relative -1
        	e.accept
        	s.render
    	elsif e.char == 'l' || e.key == Tput::Key::Right || e.key == Tput::Key::Enter
        	songlist.enter_selected
    	elsif e.char == 'd'
        	songlist.select_relative (songlist.height // 2)
        	s.render
    	elsif e.char == 'u'
        	songlist.select_relative -(songlist.height // 2)
        	s.render
    	elsif e.char == 'g'
        	songlist.select_top
        	s.render
    	elsif e.char == 'G'
        	songlist.select_bottom
        	s.render
    	elsif e.char == 'r'
        	songlist.select_and_scroll Random.rand(songlist.items.size)
        	s.render
    	elsif e.char == 'a'
        	songlist.chord_files.sort! do |a,b|
            	a.artists.join <=> b.artists.join
        	end
        	songlist.setup_items
        	s.render
    	elsif e.char == 't'
        	songlist.chord_files.sort! do |a,b|
            	a.title <=> b.title
        	end
        	songlist.setup_items
        	s.render
    	end
	end

	viewer.on(Event::KeyPress) do |e|
    	if e.char == 'h' || e.key == Tput::Key::Left || e.key == Tput::Key::Escape
        	preview.show
        	songlist.show
        	viewer.hide
        	songlist.focus
        	help.content = help_browser
        	s.render
        elsif e.char == 'j' || e.key == Tput::Key::Down
            viewer.next_section
            s.render
        elsif e.char == 'k' || e.key == Tput::Key::Up
            viewer.previous_section
            s.render
        elsif e.char == '+'
            viewer.transpose 1
            s.render
        elsif e.char == '-'
            viewer.transpose -1
            s.render
    	end
	end

	songlist.on(Event::SelectItem) do |e|
    	preview.hide
    	songlist.hide
    	viewer.show

		help.content = help_viewer
    	viewer.song = songlist.current_song
    	s.render
    	s.focus viewer
	end

	songlist.on_select do |i|
    	f = songlist.chord_files[i]
    	c = [] of String
    	preview.content = if f.is_a? ChordDown::ChordFile
    		render_sections f.sections
    	else
        	f.to_s
    	end
    	s.render
	end
	songlist.on_select_call

    s.exec
end


