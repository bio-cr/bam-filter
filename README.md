# bam-filter

[![.github/workflows/ci.yml](https://github.com/bio-cr/bam-filter/actions/workflows/ci.yml/badge.svg)](https://github.com/bio-cr/bam-filter/actions/workflows/ci.yml)
[![Slack](http://img.shields.io/badge/slack-bio--crystal-purple?labelColor=000000&logo=slack)](https://bio-crystal.slack.com/)
[![Get invite to BioCrystal](http://img.shields.io/badge/Get_invite_to_BioCrystal-purple?labelColor=000000&logo=slack)](https://join.slack.com/t/bio-crystal/shared_invite/zt-tas46pww-JSEloonmn3Ma5eD2~VeT_g)

Crystal implementation of [hts-nim-tools/bam-filter](https://github.com/brentp/hts-nim-tools)

## Installation

```sh
git clone https://github.com/bio-cr/bam-filter
make
sudo make install
```

If you are using Ubuntu, the deb package is available from the [Github release page](https://github.com/bio-cr/bam-filter/releases).

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

## Note

bam-filter was originally created to develop and test [hts.cr](https://github.com/bio-cr/hts.cr).
