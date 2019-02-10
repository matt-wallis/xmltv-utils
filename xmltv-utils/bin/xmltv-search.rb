#!/usr/bin/env ruby
require 'xmltv-utils'
xmltv = XmlTv::XmlTv.new()

search = ARGV[0].upcase
puts search
puts xmltv.programmes.find_all {|p| 
  #p.title.include? search
  (p.title.upcase.include? search) || (p.desc.upcase.include? search)
}.map {|p| p.what_and_when}.join("\n")
#}.map {|p| p.title}.join("\n")
#}.map {|p| "#{p.title} - #{p.desc}"}.join("\n")
#puts "#{xmltv.channels.size} channels"
#puts "#{xmltv.programmes.find_all {|p| true}.map {|p| p.title}}"
