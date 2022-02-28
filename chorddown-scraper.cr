#!/usr/bin/env crystal

require "http/client"
require "xml"
require "json"

def flagprint(flag, value)
    ARGV[1]?.try do |arg|
        if arg == flag
            puts value
            exit 0
        end
    end
end

if ARGV[0]?.nil?
    STDERR.puts "Give Ultimate-Guitar url as input"
    exit 1
end

res = HTTP::Client.get ARGV[0]
flagprint "--response", res.body

xml_text = res.body.lines.find do |line|
    line.includes? "js-store"
end

if xml_text.nil?
    STDERR.puts "Ultimate-Guitar might have changed their design"
    exit 2
end
flagprint "--raw-xml", xml_text

xml = XML.parse_html xml_text, XML::HTMLParserOptions::NONET
flagprint "--parsed-xml", xml
json_text = xml.xpath_nodes("//@data-content").first.content
flagprint "--raw-json", json_text

json = JSON.parse json_text
flagprint "--all-json", json

data = json["store"]["page"]["data"]
flagprint "--data", data.to_json

tab = data["tab_view"]["wiki_tab"]["content"]
flagprint "--raw-tab", tab

puts "TITLE: " + data.dig("tab", "song_name").as_s
puts "ARTIST: " + data.dig("tab", "artist_name").as_s
begin
    puts "TUNING: " + data.dig("tab_view", "meta", "tuning", "value").as_s
rescue
end
begin
    puts "CAPO: " + data.dig("tab_view", "meta", "capo").as_i.to_s
rescue
end
puts "SOURCE: " + data.dig("tab", "tab_url").as_s
puts ""
puts tab.as_s
        .gsub("[ch]","")
        .gsub("[/ch]","")
        .gsub("[tab]","")
        .gsub("[/tab]","")
        .gsub("\r","")

