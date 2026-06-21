# Author: kojix2 <2xijok@gmail.com>
# License: MIT
# https://github.com/bio-crystal/bam-filter

require "option_parser"
require "set"
require "./ke"
require "hts/bam"

PROGRAM     = "bam-filter"
VERSION     = {{ `shards version #{__DIR__}`.chomp.stringify }}
FIELD_NAMES = {
  "name"  => "record.qname",
  "flag"  => "record.flag.value",
  "chr"   => "record.chrom",
  "pos"   => "record.pos + 1",
  "start" => "record.pos",
  "stop"  => "record.endpos",
  "mapq"  => "record.mapq",
  "mchr"  => "record.mate_chrom",
  "mpos"  => "record.mpos + 1",
  "isize" => "record.isize",
}
FLAG_NAMES = \
   %w[paired proper_pair unmapped mate_unmapped
  reverse mate_reverse read1 read2
  secondary qcfail duplicate supplementary]

def parse_non_negative_int(value : String, option : String) : Int32
  num = value.to_i?
  if num.nil? || num < 0
    STDERR.puts "[bam-filter] ERROR: #{option} must be a non-negative integer."
    exit(1)
  end
  num
end

def set_aux_tag_value(e : KE, tag_name : String, value) : Nil
  case value
  when Int
    e.set("tag_#{tag_name}", value.to_i64)
  when Float
    e.set("tag_#{tag_name}", value.to_f64)
  when String
    e.set("tag_#{tag_name}", value)
  when Char
    e.set("tag_#{tag_name}", value)
  when Array(Int64), Array(Float64)
    e.set("tag_#{tag_name}", value)
  end
end

def set_aux_tags(e : KE, record : HTS::Bam::Record, tag_set : Set(String)) : Nil
  return if tag_set.empty?

  remaining = tag_set.size
  record.aux.each do |tag, value|
    next unless tag_set.includes?(tag)

    set_aux_tag_value(e, tag, value)
    remaining -= 1
    break if remaining == 0
  end
end

expr = ""
debug = false
nthreads = 0

input_file = ""
output_file = "-" # standard output
input_fasta = ""
require_files = [] of String
mode = ""

count = 0
tag_set = Set(String).new

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
  parser.summary_width = 22
  parser.on("-e", "--expression EXPR", "eval code") { |v| expr = v }
  parser.on("-r", "--require PATH", "Load Ruby script file before evaluating expression") { |v| require_files << v }
  parser.on("-o", "--output PATH", "Write output to FILE [standard output]") { |v| output_file = v }
  parser.on("-f", "--fasta FASTA", "Reference sequence FASTA FILE [null]") { |v| input_fasta = v }
  parser.on("-S", "--sam", "Output SAM") { mode = "w" }
  parser.on("-b", "--bam", "Output BAM") { mode = "wb" }
  parser.on("-C", "--cram", "Output CRAM (requires -f)") { mode = "wc" }
  parser.on("-t", "--threads NUM", "Number of threads to use [0]") { |v| nthreads = parse_non_negative_int(v, "--threads") }
  parser.on("--no-PG", "Do not add @PG line to the header") { use_pg = false }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
  parser.on("-v", "--version", "Show version number") do
    puts "#{PROGRAM}  #{VERSION}"
    exit
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
    STDERR.puts "[bam-filter] ERROR: Missing option: #{flag}"
    exit(1)
  end
end

# Check arguments

if ARGV.empty?
  STDERR.puts "[bam-filter] ERROR: input file is not specified."
  exit(1)
end

input_file = ARGV[0]

if ARGV.size > 1
  STDERR.puts "[bam-filter] ERROR: too many input files specified."
  exit(1)
end

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

require_files.each do |file|
  unless File.exists?(file)
    STDERR.puts "[bam-filter] ERROR: require file not found. #{file}"
    exit(1)
  end
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

if mode == "wc" && input_fasta.empty?
  STDERR.puts "[bam-filter] ERROR: CRAM output requires -f/--fasta."
  exit(1)
end

# Check the fields to be used before execution.

identifiers = Set(String).new
expr.scan(/[A-Za-z_][A-Za-z0-9_]*/) do |match|
  identifiers << match[0]
end

use : Hash(String, Bool)
{% begin %}
use = {
  {% for name in FIELD_NAMES.keys %}
    "{{ name.id }}" => identifiers.includes?("{{ name.id }}"),
  {% end %}
  {% for name in FLAG_NAMES %}
    "{{ name.id }}" => identifiers.includes?("{{ name.id }}"),
  {% end %}
}
{% end %}

# Check the tags to be used before execution.

identifiers.each do |identifier|
  next unless identifier.starts_with?("tag_")

  tag = identifier.lchop("tag_")
  if tag.size == 2 && tag.matches?(/^[A-Za-z0-9]{2}$/)
    tag_set.add(tag)
  else
    STDERR.puts "[bam-filter] ERROR: Incorrect tag name. #{identifier}"
    exit(1)
  end
end

# Main

begin
  e = KE.new(expr, require_files)
rescue ex : Exception
  STDERR.puts "[bam-filter] ERROR: failed to parse expression. #{ex.message}"
  exit(1)
end

bam = HTS::Bam.open(input_file, threads: nthreads, fai: input_fasta)
bam_out = HTS::Bam.open(output_file, mode, threads: nthreads, fai: input_fasta)
hdr = bam.header.clone
hdr.add_pg(PROGRAM, "VN", VERSION, "CL", CL) if use_pg
bam_out.write_header(hdr)

bam.each do |record|
  e.clear
  # Fields
  {% for key, value in FIELD_NAMES %}
    e.set("{{ key.id }}", {{ value.id }}) if use["{{ key.id }}"]
  {% end %}
  # Flags
  {% for name in FLAG_NAMES %}
    e.set("{{ name.id }}", record.flag.{{ name.id }}?) if use["{{ name.id }}"]
  {% end %}
  # Auxiliary data
  set_aux_tags(e, record, tag_set)

  # Write
  keep = e.bool
  if e.error_code != 0
    STDERR.puts "[bam-filter] #{e.eval_error}" if debug
    next
  end

  if keep
    bam_out.write(record)
    count += 1
  end
end

bam.close
bam_out.close

if count == 0
  STDERR.puts "[bam-filter] No records were written."
else
  STDERR.puts "[bam-filter] Wrote #{count} records."
end
