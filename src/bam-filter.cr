# Author: kojix2 <2xijok@gmail.com>
# License: MIT
# https://github.com/bio-crystal/bam-filter

require "option_parser"
# require "./ke"
require "hts/bam"
require "anyolite"

PROGRAM     = "bam-filter"
VERSION     = "0.1.3"
FIELD_NAMES = {
  "name"  => "r.qname",
  "flag"  => "r.flag.value",
  "chr"   => "r.chrom",
  "pos"   => "r.pos + 1",
  "start" => "r.pos",
  "stop"  => "r.endpos",
  "mapq"  => "r.mapq",
  "mchr"  => "r.mate_chrom",
  "mpos"  => "r.mpos + 1",
  "isize" => "r.isize",
}
FLAG_NAMES = \
   %w[paired proper_pair unmapped mate_unmapped
  reverse mate_reverse read1 read2
  secondary qcfail duplicate supplementary]

expr = ""
debug = false
nthreads = 0

input_file = ""
output_file = "-" # standard output
input_fasta = ""
mode = ""

count = 0
tags = [] of String

# @PG line in the output BAM header
CL = [Process.executable_path || PROGRAM_NAME].concat(ARGV).join(" ")
use_pg = true

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
  parser.on("-S", "--sam", "Output SAM") { mode = "w" }
  parser.on("-b", "--bam", "Output BAM") { mode = "wb" }
  parser.on("-C", "--cram", "Output CRAM (requires -f)") { mode = "wc" }
  parser.on("-t", "--threads NUM", "Number of threads to use [0]") { |v| nthreads = v.to_i }
  parser.on("--no-PG", "Do not add @PG line to the header") { use_pg = false }
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
    Fields: #{FIELD_NAMES.keys.join(" ")}
    Flags:  paired proper_pair unmapped mate_unmapped reverse mate_reverse
            read1 read2 secondary qcfail duplicate supplementary
    Tags:   tag_XX (XX is aux tag)

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

if input_file == "-"
  STDERR.puts "[bam-filter] Accepts strings from standard input"
elsif !File.exists?(input_file)
  STDERR.puts "[bam-filter] ERROR: #{input_file} not found."
  exit(1)
end

if expr.empty?
  STDERR.puts "[bam-filter] ERROR: no expression specified for -e"
  exit(1)
end

if mode.empty?
  mode = case File.extname(output_file)
         when ".sam"
           "w"
         when ".bam"
           "wb"
         when ".cram"
           "wc"
         else
           "wb"
         end
end

# Check the fields to be used before execution.

use : Hash(String, Bool)
{% begin %}
use = {
  {% for name in FIELD_NAMES.keys %}
    "{{name.id}}" => expr.includes?("{{name.id}}"),
  {% end %}
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

bam = HTS::Bam.open(input_file, threads: nthreads, fai: input_fasta)
bam_out = HTS::Bam.open(output_file, mode)
hdr = bam.header.clone
hdr.add_pg(PROGRAM, "VN", VERSION, "CL", CL) if use_pg
bam_out.write_header(hdr)

Anyolite::RbInterpreter.create do |rb|
  bam.each do |r|
    # Fields
    {% for key, value in FIELD_NAMES %}
      if use["{{key.id}}"]
        v = {{value.id}}
        v = v.is_a?(String) ? "\"#{v}\"" : v # OK?
        s = "{{key.id}}=#{v}"
        rb.execute_script_line(s)
      end
    {% end %}
    # Flags
    {% for name in FLAG_NAMES %}
      if use["{{name.id}}"]
        v = r.flag.{{name.id}}?
        s = "{{name.id}} = #{v}"
        rb.execute_script_line(s)
      end
    {% end %}
    # Auxiliary data
    tags.each do |t|
      v = r.aux(t)
      rb.execute_script_line("tag_i#{t}=#{v}") if v.nil?
    end

    # Write
    rb.execute_script_line(expr)
    if false
      bam_out.write(r)
      count += 1
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
