# bam-filter

[![.github/workflows/ci.yml](https://github.com/bio-cr/bam-filter/actions/workflows/ci.yml/badge.svg)](https://github.com/bio-cr/bam-filter/actions/workflows/ci.yml)
[![Slack](http://img.shields.io/badge/slack-bio--crystal-purple?labelColor=000000&logo=slack)](https://bio-crystal.slack.com/)
[![Get invite to BioCrystal](http://img.shields.io/badge/Get_invite_to_BioCrystal-purple?labelColor=000000&logo=slack)](https://join.slack.com/t/bio-crystal/shared_invite/zt-tas46pww-JSEloonmn3Ma5eD2~VeT_g)

[Crystal](https://github.com/crystal-lang/crystal) implementation of [bam-filter](https://github.com/brentp/hts-nim-tools) by Brent Pedersen. 

## Installation

```sh
git clone https://github.com/bio-cr/bam-filter
make
sudo make install
```

* Ubuntu: deb package is available from the [Github release page](https://github.com/bio-cr/bam-filter/releases).
* Currently only Linux is supported.

## Usage

```
Usage: bam-filter [options] <bam_file>
    -e EXPR, --expression EXPR       code
    -o PATH                          --output PATH
    -S, --sam                        Output SAM
    -b, --bam                        Output BAM
    -t NUM                           --threads NUM
    -h, --help                       Show this help
```

* `mapq` `start` `pos` `stop` `name` `mpos` `isize` `flag`
* `paired` `proper_pair` `unmapped` `mate_unmapped` `reverse` `mate_reverse` `read1` `read2` `secondary` `qcfail` `duplicate` `supplementary`
* `tag_XX`

## Contributing

Bug fixes and macOS support are welcome.

## Note

bam-filter was originally created to develop and test [hts.cr](https://github.com/bio-cr/hts.cr).
