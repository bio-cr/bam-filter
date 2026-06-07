#!/bin/sh
set -eu

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

./bam-filter --version >/dev/null

./bam-filter -e1 -o "$tmpdir/from-sam.bam" test/moo.sam >/dev/null
test -s "$tmpdir/from-sam.bam"

./bam-filter -e1 -o "$tmpdir/from-bam.bam" test/moo.bam >/dev/null
test -s "$tmpdir/from-bam.bam"

./bam-filter -S -e "chr == 'chr1' && pos > 0" -o "$tmpdir/filtered.sam" test/moo.bam >/dev/null
test -s "$tmpdir/filtered.sam"
grep -q '^@HD' "$tmpdir/filtered.sam"

./bam-filter -C -f test/moo.fa -e1 -o "$tmpdir/from-bam.cram" test/moo.bam >/dev/null
test -s "$tmpdir/from-bam.cram"
