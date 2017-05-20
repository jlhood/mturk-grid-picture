#!/usr/bin/ruby

if ARGV.size != 2
  puts "Usage: generate_result.rb num_rows num_cols"
  exit 1
end

num_rows = ARGV[0].to_i
num_cols = ARGV[1].to_i

def get_dimensions(image_path)
  output = `identify #{image_path} 2> /dev/null`
  output =~ /(\d+x\d+)/
  $1.split('x').map(&:to_i)
end

def create_empty_image(width,height)
  filename = "empty.#{width}.#{height}.png"
  `convert -size #{width}x#{height} xc:none #{filename}` unless File.exists?(filename)
  filename
end

row_image_files = []
(0...num_rows).each do |row|
  col_image_files = []
  (0...num_cols).each do |col|
    result_file_path = "results/result.#{row}.#{col}.png"
    if File.exists?(result_file_path)
      col_image_files << result_file_path
    else
      original_file_path = "originals/original.#{row}.#{col}.jpg"
      width,height = get_dimensions(original_file_path)
      col_image_files << create_empty_image(width,height)
    end
  end
  # create concatenated row image
  row_image_file = "results/result.#{row}.png"
  `convert #{col_image_files.join(' ')} +append #{row_image_file}`
  row_image_files << row_image_file
end

`convert #{row_image_files.join(' ')} -append results/result.png`
