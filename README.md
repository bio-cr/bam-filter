# bam-filter

[![CI](https://github.com/bio-cr/bam-filter/actions/workflows/ci.yml/badge.svg)](https://github.com/bio-cr/bam-filter/actions/workflows/ci.yml)
[![build](https://github.com/bio-cr/bam-filter/actions/workflows/build.yml/badge.svg)](https://github.com/bio-cr/bam-filter/actions/workflows/build.yml)
[![Lines of Code](https://img.shields.io/endpoint?url=https%3A%2F%2Ftokei.kojix2.net%2Fbadge%2Fgithub%2Fbio-cr%2Fbam-filter%2Flines)](https://tokei.kojix2.net/github/bio-cr/bam-filter)

Filter BAM, CRAM, and SAM records with Ruby expressions.

`bam-filter` is a Crystal command-line tool inspired by Brent Pedersen's Nim-based
[bam-filter](https://github.com/brentp/hts-nim-tools). Expressions are evaluated
with embedded [mruby](https://github.com/mruby/mruby) via
[Anyolite](https://github.com/Anyolite/anyolite).

## Installation

Download the binary from the [GitHub Release](https://github.com/bio-cr/bam-filter/releases).

From source:

```sh
git clone https://github.com/bio-cr/bam-filter
cd bam-filter
make
sudo make install
```

## Usage

```text
Usage: bam-filter [options] <bam_file>
    -e, --expression EXPR            eval code
    -r, --require PATH               Load Ruby script file before evaluating expression (repeatable)
    -o, --output PATH                Write output to FILE [standard output]
    -f, --fasta FASTA                Reference sequence FASTA FILE [null]
    -S, --sam                        Output SAM
    -b, --bam                        Output BAM
    -C, --cram                       Output CRAM (requires -f)
    -t, --threads NUM                Number of threads to use [0]
    --no-PG                          Do not add @PG line to the header
    -h, --help                       Show this help
    -v, --version                    Show version number
```

## Examples

Write SAM records on chromosome 1 after position 200 with an `AS` tag greater than
35:

```sh
bam-filter -S -e 'chr == "chr1" && pos > 200 && tag_AS && tag_AS > 35' input.bam
```

Write BAM output:

```sh
bam-filter -e 'mapq >= 30 && !duplicate' -o filtered.bam input.bam
```

Write CRAM output:

```sh
bam-filter -C -f reference.fa -e 'proper_pair && !unmapped' -o filtered.cram input.bam
```

Load Ruby helper scripts before expression evaluation:

```sh
bam-filter -r helpers.rb -r filters.rb -e 'keep_record(mapq, tag_AS)' -o filtered.bam input.bam
```

## Expressions

Expressions use Ruby syntax. A record is kept unless the final expression value is
`false`, `nil`, numeric `0`, or numeric `0.0`.

Available fields:

```text
name flag chr pos start stop mapq mchr mpos isize
```

Available flag booleans:

```text
paired proper_pair unmapped mate_unmapped reverse mate_reverse
read1 read2 secondary qcfail duplicate supplementary
```

Auxiliary tags are available as `tag_XX`, where `XX` is a two-character SAM tag.
Missing tags evaluate to `nil`, so guard comparisons explicitly:

```sh
bam-filter -e 'tag_AS && tag_AS > 35' input.bam
```

## Development

```sh
make
make test
```
