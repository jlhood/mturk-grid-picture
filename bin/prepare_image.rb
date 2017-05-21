#!/usr/bin/ruby

# split given image into image fragments for given number of rows/columns,
# obfuscate filenames, generate CSV input for HIT template

require 'fileutils'
require 'securerandom'
require 'json'
require 'csv'

S3_IMAGE_FRAGMENTS_PATH = "https://s3-us-west-2.amazonaws.com/grid-picture/images/fragments/"

def get_dimensions(path)
  output = `identify "#{path}" 2> /dev/null`
  output =~ /(\d+x\d+)\+/
  $1.split('x').map(&:to_i)
end

def image_fragment_path(image_path, row, col, dest_dir)
  extension = File.basename(image_path).split('.').last
  File.join(dest_dir, "original.#{row}.#{col}.#{extension}")
end

abort("Usage: prepare_image.rb num_rows num_cols image_path output_dir") unless ARGV.size == 4

num_rows = ARGV[0].to_i
num_cols = ARGV[1].to_i
image_path = ARGV[2]
output_dir = ARGV[3]

abort("Can't find file \"#{image_path}\"") unless File.exist?(image_path)
FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)

image_name = File.basename(image_path).split('.')[0...-1].join('.')
base_dest_dir = File.join(output_dir, image_name)
split_dest_dir = File.join(base_dest_dir, 'original', "#{num_rows}x#{num_cols}")

# split image into grid

width,height = get_dimensions(image_path)

FileUtils.mkdir_p(split_dest_dir)

row_height = height / num_rows
row_height_remainder = height % num_rows
col_width = width / num_cols
col_width_remainder = width % num_cols

num_rows.times do |row|
  num_cols.times do |col|
    last_row = row == num_rows - 1
    last_col = col == num_cols - 1
    fragment_width = col_width + (last_col ? col_width_remainder : 0)
    fragment_height = row_height + (last_row ? row_height_remainder : 0)

    fragment_x_offset = col * col_width
    fragment_y_offset = row * row_height

    fragment_file_path = image_fragment_path(image_path, row, col, split_dest_dir)
    puts "generating image fragment: row=#{row}, col=#{col}"
    `convert "#{image_path}" -crop #{fragment_width}x#{fragment_height}+#{fragment_x_offset}+#{fragment_y_offset} "#{fragment_file_path}" 2> /dev/null`
  end
end

# obfuscate file names and save key.
# Also generate mturk input CSV and save that too

obfuscated_image_name_dest_dir = File.join(base_dest_dir, 'obfuscated', "#{num_rows}x#{num_cols}")

FileUtils.mkdir_p(obfuscated_image_name_dest_dir) unless File.exist?(obfuscated_image_name_dest_dir)
obfuscation_key = {}
mturk_input_csv = []

image_extension = File.basename(image_path).split('.').last
Dir.glob("#{split_dest_dir}/*.#{image_extension}").each do |image_path|
  obfuscated_name = SecureRandom.uuid + ".#{image_extension}"
  obfuscated_path = File.join(obfuscated_image_name_dest_dir, obfuscated_name)
  puts "obfuscating image name: #{File.basename(image_path)} -> #{obfuscated_name}"
  FileUtils.copy(image_path, obfuscated_path)
  obfuscation_key[obfuscated_name] = File.basename(image_path)

  fragment_width,fragment_height = get_dimensions(obfuscated_path)
  mturk_input_csv << [
    S3_IMAGE_FRAGMENTS_PATH + obfuscated_name,
    fragment_width.to_s,
    fragment_height.to_s
  ]
end

puts "writing obfuscation key"
File.open(File.join(base_dest_dir, 'obfuscation_key.txt'), 'w') { |f| f.puts obfuscation_key.to_json }

puts "writing mturk input csv"
CSV.open(File.join(base_dest_dir, 'mturk_input.csv'), 'w',
  :write_headers => true,
  :headers => ['image_url','image_width','image_height']) do |csv|
  mturk_input_csv.each { |row| csv << row }
end
