#!/usr/bin/env bash


#ftp://mirbase.org/pub/mirbase/CURRENT/genomes/hsa.gff3

docker container run --user=$UID:1002 --rm -v $PWD:/proj/ nanozoo/subread:2.0.2--53f5da6 \
	featureCounts -T 6 -g 'transcript_id' -O -a /proj/data/hsa.gtf \
	-o /proj/data/feature-counts/srna-counts-mirbase.txt \
	$(find data/rna-seq-small-output/ -maxdepth 1 -type f -name "*.bam" -exec echo /proj/{} \;)
