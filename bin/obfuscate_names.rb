#!/usr/bin/ruby

require 'securerandom'
require 'fileutils'

# rename given images to uuids and provide key

if ARGV.size != 2
  puts "Usage: obfuscate_names.rb src_dir dest_dir"
  exit 1
end

src_dir = ARGV[0]
dest_dir = ARGV[1]
image_dir = File.join(dest_dir, 'obfuscated_filenames')
FileUtils.mkdir_p(image_dir) rescue nil
key = {}

Dir.glob("#{src_dir}/*.jpg").each do |image_path|
  obfuscated_name = SecureRandom.uuid + ".jpg"
  FileUtils.copy(image_path, File.join(image_dir, obfuscated_name))
  key[obfuscated_name] = File.basename(image_path)
end

File.open(File.join(dest_dir, 'obfuscation_key.txt'), 'w') do |f|
  f.puts key.inspect
end
