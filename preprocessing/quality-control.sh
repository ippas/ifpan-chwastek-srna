#!/usr/bin/env bash

OUT_DIR=results/fastqc/raw
mkdir -p $OUT_DIR

docker run --user=$UID:1002 --rm -v $PWD:/proj pegi3s/fastqc \
	-t 4 \
	-o /proj/$OUT_DIR \
	$(find raw/X201SC21060946-Z01-F001/raw_data -type f -name "*.fq.gz" -exec echo /proj/{} \;)

docker run --user=$UID:1002 --rm -v $PWD:/proj ewels/multiqc:latest \
	/proj/$OUT_DIR -o /proj/$OUT_DIR
