#!/usr/bin/env ruby
require 'xmltv-utils'

# We want to include all channels:
xmltv = XmlTv::XmlTv.new({include_channels_file: ''})
puts xmltv.channels.map {|ch| ch.name}.sort.join("\n")

