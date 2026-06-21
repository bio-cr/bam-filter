#!/bin/sh
set -eu

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

./bam-filter --version >/dev/null

./bam-filter -e 'true' -o "$tmpdir/true.bam" test/moo.bam >/dev/null
test -s "$tmpdir/true.bam"

./bam-filter -e 'false' -o "$tmpdir/false.bam" test/moo.bam >/dev/null

./bam-filter -e '1' -o "$tmpdir/one.bam" test/moo.bam >/dev/null
test -s "$tmpdir/one.bam"

./bam-filter -e '0' -o "$tmpdir/zero.bam" test/moo.bam >/dev/null

./bam-filter -e1 -o "$tmpdir/from-sam.bam" test/moo.sam >/dev/null
test -s "$tmpdir/from-sam.bam"

./bam-filter -e1 -o "$tmpdir/from-bam.bam" test/moo.bam >/dev/null
test -s "$tmpdir/from-bam.bam"

./bam-filter -S -e "chr == 'chr1' && pos > 0" -o "$tmpdir/filtered.sam" test/moo.bam >/dev/null
test -s "$tmpdir/filtered.sam"
grep -q '^@HD' "$tmpdir/filtered.sam"

./bam-filter -S -e 'chr == "chr1" && pos > 0' -o "$tmpdir/double-quoted.sam" test/moo.bam >/dev/null
test -s "$tmpdir/double-quoted.sam"

./bam-filter -S -e 'paired || unmapped' -o "$tmpdir/flags.sam" test/moo.bam >/dev/null
test -s "$tmpdir/flags.sam"

./bam-filter -S -e 'tag_AS && tag_AS > 35' -o "$tmpdir/tag.sam" test/moo.bam >/dev/null
test -s "$tmpdir/tag.sam"

./bam-filter -S -e 'tag_XB && tag_XB[0] == 1 && tag_XB.include?(3) && tag_XF && tag_XF[1] > 2.0' -o "$tmpdir/array-tags-filtered.sam" test/array-tags.sam >/dev/null
test "$(grep -vc '^@' "$tmpdir/array-tags-filtered.sam")" -eq 1
grep -q '^array_pass[[:space:]]' "$tmpdir/array-tags-filtered.sam"

./bam-filter -S -e 'name.start_with?("read")' -o "$tmpdir/name-method.sam" test/moo.bam >/dev/null

./bam-filter -S -r test/thresholds.rb -r test/filters.rb -e 'keep_record(chr, mapq, tag_AS)' -o "$tmpdir/required-helper.sam" test/moo.bam >/dev/null
test "$(grep -vc '^@' "$tmpdir/required-helper.sam")" -eq 2
grep -q '^chr1_179_692_1:0:0_1:1:1_0[[:space:]]73[[:space:]]chr1[[:space:]]179[[:space:]]60[[:space:]]40M' "$tmpdir/required-helper.sam"
grep -q '^chr1_475_941_0:0:0_0:3:0_1[[:space:]]97[[:space:]]chr1[[:space:]]475[[:space:]]60[[:space:]]40M' "$tmpdir/required-helper.sam"

if ./bam-filter -e 'chr ==' -o "$tmpdir/parse-error.bam" test/moo.bam >/dev/null 2>"$tmpdir/parse-error.err"; then
  echo "expected parse error to fail" >&2
  exit 1
fi
grep -q 'failed to parse expression' "$tmpdir/parse-error.err"

./bam-filter --debug -e 'unknown_value > 0' -o "$tmpdir/runtime-error.bam" test/moo.bam >/dev/null 2>"$tmpdir/runtime-error.err"
grep -q 'NoMethodError' "$tmpdir/runtime-error.err"

./bam-filter -C -f test/moo.fa -e1 -o "$tmpdir/from-bam.cram" test/moo.bam >/dev/null
test -s "$tmpdir/from-bam.cram"
