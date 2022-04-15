# Author: kojix2 <2xijok@gmail.com>
# License: MIT
# https://github.com/bio-crystal/bam-filter

require "option_parser"
require "./ke"
require "hts/bam"

PROGRAM = "bam-filter"
VERSION = "0.0.5"

expr = ""
debug = false
nthreads = 0
input_file = ""
output_file = "-"
output_format = ""

OptionParser.parse do |parser|
  parser.banner=<<-EOS
  Program: #{PROGRAM}
  Version: #{VERSION}
  Source:  https://github.com/bio-crystal/bam-filter
  
  Usage: bam-filter [options] <bam_file>
  EOS
  parser.on("-t NUM", "--threads NUM") { |v| nthreads = v.to_i }
  parser.on("-o PATH", "--output PATH") { |v| output_file = v }
  parser.on("-S", "--sam", "Output SAM") { output_format = ".sam" }
  parser.on("-b", "--bam", "Output BAM") { output_format = ".bam" }
  # parser.on("-f", "--fasta PATH") { |v| p v }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
  parser.on("-v", "--version", "Show version number") do
    puts "#{PROGRAM}  #{VERSION}"
    exit(1)
  end
  parser.on("-e EXPR", "--expression EXPR", "code") { |v| expr = v }
  parser.separator <<-EOS

         name pos start stop mpos isize flag
         paired proper_pair unmapped mate_unmapped
         reverse mate_reverse read1 read2 secondary
         qcfail dup supplementary

  EOS
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
  if ARGV.empty?
    puts parser
    exit(1)
  end
end

input_file = ARGV[0]

if input_file == ""
  STDERR.puts "ERROR: bam file is not specified."
  exit(1)
end

unless File.exists?(input_file)
  STDERR.puts "ERROR: #{input_file} not found."
  exit(1)
end

if expr == ""
  STDERR.puts "ERROR: no expression specified for -e"
  exit(1)
end

if output_format == ""
  if File.extname(output_file) == ".sam"
    output_format = ".sam"
  elsif File.extname(output_file) == ".bam"
    output_format = ".bam"
  elsif output_file == "-"
    output_format = ".sam"
  else
    output_format = ".bam"
  end
end

e = KE.new(expr)
bam = HTS::Bam.open(input_file, threads: nthreads)
mode = (output_format == ".sam" ? "w" : "wb")
bam_out = HTS::Bam.open(output_file, mode)
bam_out.write_header(bam.header)

FLAG_NAMES = %w[paired proper_pair unmapped mate_unmapped
                reverse mate_reverse read1 read2
                secondary qcfail dup supplementary]

use : Hash(String, Bool)
{% begin %}
use = {
  "mapq"  => expr.includes?("mapq"),
  "start" => expr.includes?("start"),
  "pos"   => expr.includes?("pos"),
  "stop"  => expr.includes?("stop"),
  "name"  => expr.includes?("name"),
  "mpos"  => expr.includes?("mpos"),
  "isize" => expr.includes?("isize"),
  "flag"  => expr.includes?("flag"),
  {% for name in FLAG_NAMES %}
    "{{name.id}}" => expr.includes?("{{name.id}}"),
  {% end %}
}
{% end %}

bam.each do |r|
  e.clear
  e.set("mapq",  r.mapping_quality) if use["mapq"]
  e.set("start", r.start)           if use["start"]
  e.set("pos",   r.start + 1)       if use["pos"]
  e.set("stop",  r.stop)            if use["stop"]
  e.set("name",  r.qname)           if use["name"]
  e.set("mpos",  r.mate_pos)        if use["mpos"]
  e.set("isize", r.insert_size)     if use["isize"]
  e.set("flag",  r.flag.value)      if use["flag"]
  {% for name in FLAG_NAMES %}
    e.set("{{name.id}}", (r.flag.{{name.id}}? ? 1 : 0)) if use["{{name.id}}"]
  {% end %}

  bam_out.write(r) if e.bool
end

bam.close
bam_out.close

