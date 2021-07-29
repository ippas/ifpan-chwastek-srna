#!/usr/bin/env bash

OUT_DIR=data/cutadapt
mkdir -p $OUT_DIR

for FILE in $(find raw/X201SC21060946-Z01-F001/raw_data -type f -name "*.fq.gz" -exec echo /proj/{} \;)
do
	SAMPLE_ID=$(echo $FILE | cut -d / -f 6)
	docker container run --user=$UID:1002 --rm -v $PWD:/proj dceoy/cutadapt \
		-g GTGACTGGAGTTCAGACGTGTGCTCTTCCGATCT \
		--revcomp \
		-j 6 \
		--minimum-length 12 \
		-o "/proj/${OUT_DIR}/${SAMPLE_ID}.fq.gz" \
		$FILE
done;
