require "option_parser"
require "./ke"
require "htslib/hts/bam"

expr = ""
debug = false

OptionParser.parse do |parser|
  parser.banner = "Usage: bam-filter [options] <bam_file>"
  parser.on("-e EXPR", "--expression EXPR", "code") { |v| expr = v }
  # parser.on("-t", "--threads NUM") { |v| p v }
  # parser.on("-f", "--fasta PATH") { |v| p v }
  # parser.on("-d", "--debug", "print expression") { debug = true }
  parser.on("-t", "--help", "Show this help") do
    puts parser
    exit
  end
  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

if ARGV.size != 1
  STDERR.puts "ERROR: bam file is not specified."
  exit(1)
end

e = KE.new(expr)
bam = HTS::Bam.open(ARGV[0])

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

  puts r.to_s if e.bool
end

bam.close
