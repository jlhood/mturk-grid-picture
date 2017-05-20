#!/usr/bin/ruby

require 'csv'
require 'base64'

if ARGV.size != 2
  puts "Usage: parse_results.rb <obfuscation_key_path> <result_csv>"
  exit 1
end

obfuscation_key_path = ARGV[0]
result_csv = ARGV[1]

eval 'obfuscation_key = ' + File.read(obfuscation_key_path).chomp

title = true
image_url_index = nil
image_data_url_index = nil
image_width_index = nil
image_height_index = nil
CSV.foreach(result_csv) do |row|
  if title
    image_url_index = row.index('Input.image_url')
    image_data_url_index = row.index('Answer.Drawing')
    image_width_index = row.index('Input.image_width')
    image_height_index = row.index('Input.image_height')
    title = false
  else
    obfuscated_filename = File.basename(row[image_url_index])
    dest_filename = obfuscation_key[obfuscated_filename].sub('original','result').sub('jpg','png')
    dest_path = File.join('results',dest_filename)
    image_base64 = row[image_data_url_index].sub(/^data:image\/png;base64,/,'')
    File.open(dest_path, 'wb') { |f| f.write(Base64.decode64(image_base64)) }
  end
end
