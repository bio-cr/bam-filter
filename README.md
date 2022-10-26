# bam-filter

[![.github/workflows/ci.yml](https://github.com/bio-cr/bam-filter/actions/workflows/ci.yml/badge.svg)](https://github.com/bio-cr/bam-filter/actions/workflows/ci.yml)
[![Slack](http://img.shields.io/badge/slack-bio--crystal-purple?labelColor=000000&logo=slack)](https://bio-crystal.slack.com/)
[![Get invite to BioCrystal](http://img.shields.io/badge/Get_invite_to_BioCrystal-purple?labelColor=000000&logo=slack)](https://join.slack.com/t/bio-crystal/shared_invite/zt-tas46pww-JSEloonmn3Ma5eD2~VeT_g)

[Crystal](https://github.com/crystal-lang/crystal) implementation of [bam-filter](https://github.com/brentp/hts-nim-tools) by Brent Pedersen. 

Filter BAM / CRAM / SAM files with a simple expression language. 

## Installation

```sh
git clone https://github.com/bio-cr/bam-filter
make
sudo make install
```

* Ubuntu 20.04 and 22.04: deb packages are available from the [Github release page](https://github.com/bio-cr/bam-filter/releases).
  * Please note that installing the bam-filter deb package may uninstall packages that depend on `libcurl4-openssl-dev`, since `libhts-dev` depends on `libcurl4-gnutls-dev`.
* Currently only Linux is supported.

## Usage

```
Usage: bam-filter [options] <bam_file>
    -e, --expression EXPR            eval code
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

```
bam-filter -S -e "chr=='chr1' && pos > 200 && tag_AS > 35" test/moo.bam
```

### Available values in expression

Fields: `name` `flag` `chr` `pos` `start` `stop` `mapq` `mchr` `mpos` `isize`

Flags: `paired` `proper_pair` `unmapped` `mate_unmapped`
       `reverse` `mate_reverse` `read1` `read2` `secondary`
       `qcfail` `duplicate` `supplementary`

Tags:  `tag_XX` (XX is aux tag)

## Development

The easiest way to start development is to use [Gitpod](https://www.gitpod.io/). All you need is a browser.

## Contributing

Bug fixes and macOS support are welcome.

## Note

bam-filter was originally created to develop and test [HTS.cr](https://github.com/bio-cr/hts.cr).
