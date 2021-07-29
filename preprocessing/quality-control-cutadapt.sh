#!/usr/bin/env bash

OUT_DIR=results/fastqc/cutadapt2
mkdir -p $OUT_DIR

docker run --user=$UID:1002 --rm -v $PWD:/proj pegi3s/fastqc \
	-t 4 \
	-o /proj/$OUT_DIR \
	$(find data/cutadapt/ -type f -name "*.fq.gz" -exec echo /proj/{} \;)

docker run --user=$UID:1002 --rm -v $PWD:/proj ewels/multiqc:latest \
	/proj/$OUT_DIR -o /proj/$OUT_DIR
