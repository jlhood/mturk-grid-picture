#!/usr/bin/ruby

if ARGV.size != 1
  puts "Usage: complete.rb <obfuscation_key_path>"
  exit 1
end

eval 'obfuscation_key = ' + File.read(ARGV[0]).chomp + '.invert'

Dir.glob('results/*.png') do |result|
  next unless result =~ /result\.\d+\.\d+\.png/
  original_file = File.basename(result).sub('result','original').sub('png','jpg')
  puts obfuscation_key[original_file]
end
