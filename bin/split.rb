#!/usr/bin/ruby

# split given image into given number of rows/columns

require 'fileutils'

def get_dimensions(image_path)
  output = `identify "#{image_path}" 2> /dev/null`
  output =~ /(\d+x\d+)/
  $1.split('x').map(&:to_i)
end

def image_fragment_path(image_path, row, col, dest_dir)
  File.join(dest_dir, File.basename(image_path).split('.').insert(-2, row, col).join('.'))
end

if ARGV.size != 3
  puts "Usage: split.rb num_rows num_cols image_path"
  exit 1
end

num_rows = ARGV[0].to_i
num_cols = ARGV[1].to_i
image_path = ARGV[2]
image_name = File.basename(image_path).split('.')[0...-1].join('.')
dest_dir = File.join('output', image_name, 'original', "#{num_rows}x#{num_cols}")

if !File.exist?(image_path)
  puts "Can't find file \"#{image_path}\""
  exit 1
end

if !Dir.exist?(dest_dir)
  FileUtils.mkdir_p(dest_dir)
end

width,height = get_dimensions(image_path)

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

    fragment_file_path = image_fragment_path(image_path, row, col, dest_dir)
    puts "generating image fragment: row=#{row}, col=#{col}"
    `convert "#{image_path}" -crop #{fragment_width}x#{fragment_height}+#{fragment_x_offset}+#{fragment_y_offset} "#{fragment_file_path}" 2> /dev/null`
  end
end
