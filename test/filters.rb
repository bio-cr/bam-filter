def keep_record(chr, mapq, score)
  chr == "chr1" && mapq == 60 && passing_alignment_score?(score)
end
