#!/usr/bin/ruby

# parses output CSV file, saves drawings to image files, stitches together final result image

require 'json'
require 'fileutils'
require 'csv'
require 'base64'

def get_dimensions(image_path)
  output = `identify #{image_path} 2> /dev/null`
  output =~ /(\d+x\d+)\+/
  $1.split('x').map(&:to_i)
end

def create_empty_image(width,height,output_dir)
  filename = "empty.#{width}.#{height}.png"
  filepath = File.join(output_dir, filename)
  `convert -size #{width}x#{height} xc:none #{filepath}` unless File.exists?(filepath)
  filepath
end

if ARGV.size != 5
  puts "Usage: process_results.rb num_rows num_cols result_csv obfuscation_key_path output_dir"
  exit 1
end

num_rows = ARGV[0].to_i
num_cols = ARGV[1].to_i
result_csv,obfuscation_key_path,output_dir = ARGV[2..-1]
base_results_dir = File.join(output_dir, 'results', "#{num_rows}x#{num_cols}")
FileUtils.mkdir_p(base_results_dir) unless File.exist?(base_results_dir)

obfuscation_key = JSON.parse(File.read(obfuscation_key_path))

# parse results CSV into image files
CSV.foreach(result_csv, :headers => true) do |row|
  obfuscated_filename = File.basename(row['Input.image_url'])
  original_filename = obfuscation_key[obfuscated_filename]
  raise "unexpected original filename format: #{original_filename.inspect}" unless original_filename =~ /(\.\d+\.\d+\.)\w+$/
  result_filename = 'result' + $1 + 'png'
  dest_path = File.join(base_results_dir, result_filename)
  next unless row['Answer.Drawing'] =~ /^data:image\/png;base64/
  image_base64 = row['Answer.Drawing'].sub(/^data:image\/png;base64,/,'')
  File.open(dest_path, 'wb') { |f| f.write(Base64.decode64(image_base64)) }
end

# generate result image from mturk results. Use originals to fill in where we don't yet have mturk results

original_output_dir = File.join(output_dir, 'original', "#{num_rows}x#{num_cols}")

row_image_files = []
(0...num_rows).each do |row|
  col_image_files = []
  (0...num_cols).each do |col|
    result_file_path = File.join(base_results_dir, "result.#{row}.#{col}.png")
    original_file_path = File.join(original_output_dir, "original.#{row}.#{col}.jpg")
    original_width,original_height = get_dimensions(original_file_path)

    use_result = false
    if File.exists?(result_file_path)
      result_width,result_height = get_dimensions(result_file_path)
      if original_width == result_width && original_height == result_height
        use_result = true
      else
        STDERR.puts "Warning: result file dimensions do not match original: #{result_file_path} expected: #{original_width}x#{original_height}, actual: #{result_width}x#{result_height}"
      end
    end

    if use_result
      col_image_files << result_file_path
    else
      col_image_files << create_empty_image(original_width,original_height,base_results_dir)
    end
  end

  # create concatenated row image
  row_image_file = File.join(base_results_dir, "result.#{row}.png")
  `convert #{col_image_files.join(' ')} +append #{row_image_file}`
  row_image_files << row_image_file
end

result_file = File.join(base_results_dir, "result.png")
`convert #{row_image_files.join(' ')} -append #{result_file}`
