# bam-filter

[![.github/workflows/ci.yml](https://github.com/kojix2/bam-filter/actions/workflows/ci.yml/badge.svg)](https://github.com/kojix2/bam-filter/actions/workflows/ci.yml)

Crystal implementation of [hts-nim-tools/bam-filter](https://github.com/brentp/hts-nim-tools)

```
Usage: bam-filter.cr [options] <bam_file>
    -e EXPR, --expression EXPR       code
    -t, --help                       Show this help
```

* `mapq` `start` `pos` `stop` `name` `mpos` `isize` `flag`
* `paired` `proper_pair` `unmapped` `mate_unmapped` `reverse` `mate_reverse` `read1` `read2` `secondary` `qcfail` `dup` `supplementary`
