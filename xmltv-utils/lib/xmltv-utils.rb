require 'nokogiri'
require 'date'
require 'tmpdir'

module XmlTv
  class Channel
    include Comparable
    @@id2channel = {}
    @@name2channel = {}
    attr_reader :name, :ids
    def initialize(name)
      @name = name
      @ids = []
    end
    def add_id(id)
      @ids << id
      self
    end
    def self.add_channel(name, id)
      ch = @@name2channel[name] || Channel.new(name)
      @@name2channel[name] = ch
      @@id2channel[id] = ch
      ch.add_id(id)
    end
    def self.names
      @@name2channel.keys
    end
    def self.all
      @@name2channel.values
    end
    def self.channel_by_id(id)
      @@id2channel[id] || raise("Channel id not found: #{id}")
    end
    def <=>(that)
      name <=> that.name
    end
  end

  class Schedule
    attr_reader :start, :stop, :channel
    def initialize(start, stop, channel_id)
      @start, @stop, @channel = start, stop, Channel.channel_by_id(channel_id)
    end
    def duration_mins
      # stop - start results in Rational number of days
      ((stop - start)*24*60).to_i
    end
    def to_s
      "#{start.iso8601} #{duration_mins} mins #{channel.name}"
    end
  end

  class Programme
    include Comparable
    @@title_desc_to_programme = {}
    @@to_schedule = Hash.new{|h, k| h[k] = []}
    attr_reader :title, :desc
    def initialize(title, desc)
      @title, @desc = title, desc
    end
    def <=>(that)
      ((title <=> that.title) == 0) && desc <=> that.desc
    end 
    def schedules
      @@to_schedule[self].map {|s| s.to_s}
    end
    def what_and_when
      "#{title} - #{desc}\n" + schedules.map {|s| "  #{s}"}.join("\n")
    end
    def self.add_programme(title, desc, schedule)
      prog = @@title_desc_to_programme[title + desc] || Programme.new(title, desc)
      @@title_desc_to_programme[title + desc] = prog
      @@to_schedule[prog] << schedule
      prog
    end
    def self.all
      @@title_desc_to_programme.values
    end
  end

  class XmlTv
    attr_reader :data_file, :include_channels
    def initialize(opts = {})
      opt = {
	data_dir: "#{Dir.tmpdir}/xmltv-utils-cache",
	xmltv_url: 'http://www.xmltv.co.uk/feed/6715',
	include_channels_file: 'include-channels.txt'
      }.merge(opts)
      Dir.mkdir(opt[:data_dir]) unless Dir.exist?(opt[:data_dir])
      @data_file = "#{opt[:data_dir]}/#{Date.today.iso8601}.xml"
      unless File.exist? @data_file
	cmd = "curl --silent #{opt[:xmltv_url]} >#{@data_file}"
	$stderr.puts "Fetching up-to-date information from  xmltv"
	$stderr.puts cmd
	res = `#{cmd}`
	exit $?.exitstatus unless $?.success?
      end
      @include_channels = 
	(File.exist? opt[:include_channels_file]) ?
	File.readlines(opt[:include_channels_file]).map {|chname|
	  chname.strip
	} : []
	@doc = File.open(@data_file) { |f| Nokogiri::XML(f) }
    end
    def channels
      unless @channels
	inc_hash = Hash[include_channels.map{|x| [x, true]}]
	@doc.css('channel').each {|ch|
	  name = ch.css('display-name')[0].text
	  if include_channels.size == 0 || inc_hash[name]
	    id = ch['id']
	    Channel.add_channel(name, id)
	  end
	}
      end
      @channels = Channel.all
    end
    def programmes
      unless @programmes
	# We need to endure channels have been parsed:
	channels
	@doc.css('programme').each {|p|
	  begin
	    channel_id = p['channel']
	    start = to_datetime(p['start'])
	    stop = to_datetime(p['stop'])
	    schedule = Schedule.new(start, stop, channel_id)
	    title = p.css('title')[0].text
	    desc = p.css('desc')[0].text
	    Programme.add_programme(title, desc, schedule)
	  rescue
	    # We get here if the channel_id corresponds
	    # to an exlcuded channel
	  end
	}
      end
      @programmes = Programme.all
    end
    def to_datetime(t)
      date = t[0..7]
      hhmmss = t[8..13]
      tz = t[15..19]
      DateTime.iso8601("#{date}T#{hhmmss}#{tz}")
    end
  end
end
