Gem::Specification.new do |s|
  s.name = %q{xmltv-utils}
  s.version = "0.0.0"
  s.date = %q{2019-02-12}
  s.summary = %q{Command line tools  and library for searching and presenting information from XMLTV feeds}
  s.authors = ["Matt Wallis"]
  s.files = [
    "lib/xmltv-utils.rb"
  ]
  s.require_paths = ["lib"]
  s.bindir = "bin"
  s.executables << "xmltv-search.rb"
  s.executables << "xmltv-list-channels.rb"
  s.metadata = { "source_code_uri" => "https://github.com/matt-wallis/xmltv-utils" }
end
