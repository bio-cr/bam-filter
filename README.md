# bam-filter

[![.github/workflows/ci.yml](https://github.com/kojix2/bam-filter/actions/workflows/ci.yml/badge.svg)](https://github.com/kojix2/bam-filter/actions/workflows/ci.yml)
[![Slack](http://img.shields.io/badge/slack-bio--crystal-purple?labelColor=000000&logo=slack)](https://bio-crystal.slack.com/)
[![Get invite to BioCrystal Slack](http://img.shields.io/badge/Get_invite_to_BioCrystal_Slack-purple?labelColor=000000&logo=slack)](https://join.slack.com/t/bio-crystal/shared_invite/zt-tas46pww-JSEloonmn3Ma5eD2~VeT_g)

Crystal implementation of [hts-nim-tools/bam-filter](https://github.com/brentp/hts-nim-tools)

build:

```
make
```

usage:

```
Usage: bam-filter [options] <bam_file>
    -e EXPR, --expression EXPR       code
    -i PATH                          --input PATH
    -o PATH                          --output PATH
    -S, --sam                        Output SAM
    -b, --bam                        Output BAM
    -t NUM                           --threads NUM
    -h, --help                       Show this help
```

* `mapq` `start` `pos` `stop` `name` `mpos` `isize` `flag`
* `paired` `proper_pair` `unmapped` `mate_unmapped` `reverse` `mate_reverse` `read1` `read2` `secondary` `qcfail` `dup` `supplementary`
