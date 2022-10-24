# Author: kojix2 <2xijok@gmail.com>
# License: MIT
# https://github.com/bio-crystal/bam-filter

require "option_parser"
require "./ke"
require "hts/bam"

PROGRAM    = "bam-filter"
VERSION    = "0.0.7"
FLAG_NAMES = \
   %w[paired proper_pair unmapped mate_unmapped
  reverse mate_reverse read1 read2
  secondary qcfail duplicate supplementary]

expr = ""
debug = false
nthreads = 0

input_file = ""
output_file = "-"
input_fasta = ""
output_format = ""

count = 0
tags = [] of String

# Option Parser

OptionParser.parse do |parser|
  parser.banner = <<-EOS
    Program: #{PROGRAM}
    Version: #{VERSION}
    Source:  https://github.com/bio-cr/bam-filter
  
    Usage: bam-filter [options] <bam_file>
    EOS
  parser.on("-e", "--expression EXPR", "eval code") { |v| expr = v }
  parser.on("-o", "--output PATH", "Write output to FILE [standard output]") { |v| output_file = v }
  parser.on("-f", "--fasta FASTA", "Reference sequence FASTA FILE [null]") { |v| input_fasta = v }
  parser.on("-S", "--sam", "Output SAM") { output_format = ".sam" }
  parser.on("-b", "--bam", "Output BAM") { output_format = ".bam" }
  # parser.on("-C", "--cram", "Output CRAM (requires -f)") { output_format = ".cram" }
  parser.on("-t", "--threads NUM", "Number of threads to use [0]") { |v| nthreads = v.to_i }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
  parser.on("-v", "--version", "Show version number") do
    puts "#{PROGRAM}  #{VERSION}"
    exit(1)
  end
  parser.on("--debug", "Debug mode") { debug = true }
  parser.separator <<-EOS

    Available values in expression
    Fields:
           name pos start stop mpos isize flag
    Flags:
           paired proper_pair unmapped mate_unmapped
           reverse mate_reverse read1 read2 secondary
           qcfail duplicate supplementary
    Tags:
           tag_XX (XX is aux tag)

    EOS
  # Show help text if no arguments passed
  if ARGV.empty?
    puts parser
    exit(1)
  end
  parser.invalid_option do |flag|
    STDERR.puts parser
    STDERR.puts "[bam-filter] ERROR: #{flag} is not a valid option."
    exit(1)
  end
  parser.missing_option do |flag|
    STDERR.puts parser
    STDERR.puts "[bam-filter] ERROR: #Missing option: #{flag}"
    exit(1)
  end
end

# Check arguments

if ARGV.empty?
  STDERR.puts "[bam-filter] ERROR: input file is not specified."
  exit(1)
end

input_file = ARGV[0]

unless File.exists?(input_file)
  STDERR.puts "[bam-filter] ERROR: #{input_file} not found."
  exit(1)
end

if expr == ""
  STDERR.puts "[bam-filter] ERROR: no expression specified for -e"
  exit(1)
end

if output_format == ""
  output_format = \
     case File.extname(output_file)
     when ".sam"
       ".sam"
     when ".bam"
       ".bam"
     when ".cram"
       ".cram"
     when "-"
       ".sam"
     else
       ".bam"
     end
end

# Check the fields to be used before execution.

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

# Check the tags to be used before execution.

expr.scan(/(?<=tag_)[A-Za-z0-9]+/).each do |md|
  t = md[0]
  if t.size == 2
    tags << t
  else
    STDERR.puts "[bam-filter] ERROR: Incorrect tag name. #{t}"
    exit(1)
  end
end

# Main

begin
  e = KE.new(expr)
rescue ex : Exception
  STDERR.puts "[bam-filter] ERROR: failed to parse expression. #{ex.message}"
  exit(1)
end

bam = HTS::Bam.open(input_file, threads: nthreads, fai: input_fasta)
mode = (output_format == ".sam" ? "w" : "wb")
bam_out = HTS::Bam.open(output_file, mode)
bam_out.write_header(bam.header)

bam.each do |r|
  e.clear
  # Fields
  e.set("mapq", r.mapq) if use["mapq"]
  e.set("start", r.pos) if use["start"]
  e.set("pos", r.pos + 1) if use["pos"]
  e.set("stop", r.endpos) if use["stop"]
  e.set("name", r.qname) if use["name"]
  e.set("mpos", r.mate_pos) if use["mpos"]
  e.set("isize", r.insert_size) if use["isize"]
  e.set("flag", r.flag.value) if use["flag"]
  # Flags
  {% for name in FLAG_NAMES %}
    e.set("{{name.id}}", (r.flag.{{name.id}}? ? 1 : 0)) if use["{{name.id}}"]
  {% end %}
  # Auxiliary data
  tags.each do |t|
    v = r.aux(t)
    e.set("tag_#{t}", v) unless v.nil?
  end

  # Write
  if e.bool
    if e.error_code == 0
      bam_out.write(r)
      count += 1
    else
      STDERR.puts "[bam-filter] #{e.eval_error}" if debug
    end
  end
end

bam.close
bam_out.close

if count == 0
  STDERR.puts "[bam-filter] No records were written."
else
  STDERR.puts "[bam-filter] Wrote #{count} records."
end
