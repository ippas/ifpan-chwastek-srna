#!/usr/bin/env bash

docker container run --user=$UID:1002 --rm -v $PWD:/proj/ nanozoo/subread:2.0.2--53f5da6 \
	featureCounts -T 6 -O -a /proj/data/Homo_sapiens_gtf.gtf \
	-o /proj/data/feature-counts/srna-counts.txt \
	$(find data/rna-seq-small-output/ -maxdepth 1 -type f -name "*.bam" -exec echo /proj/{} \;)
