require 'multi_json'
require 'nokogiri'
require 'open-uri'

def get(url, headers={}, silent: false)
  puts "getting #{url}" unless silent
  Nokogiri::HTML( open(URI.escape(url), headers) )
rescue => e
  puts "#{e}. Retrying in 500ms ..."; sleep 0.5
  Nokogiri::HTML( open(URI.escape(url), headers) )
end

def read(path, parser: MultiJson, silent: false)
  puts "reading #{path}" unless silent
  File.open(path, 'r') do |file|
    return parser.load(file.read)
  end
rescue => e
  puts "#{e}. Failed to read #{path}"
  []
end

def write(path, data, silent: false)
  puts "writing #{path}" unless silent
  File.open(path, 'w') do |file|
    file.puts MultiJson.dump(data, pretty: true).gsub(/\[\s+\]/, '[]')
  end
end
