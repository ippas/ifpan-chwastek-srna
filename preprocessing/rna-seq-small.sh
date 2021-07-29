#!/usr/bin/env bash

set -ex

cromwell run preprocessing/rna-seq-small.wdl \
	--inputs preprocessing/rna-seq-small-inputs.json \
	--options preprocessing/rna-seq-small-cromwell.conf

find data/rna-seq-small-output/rna_seq_small -type f -exec cp -i {} data/rna-seq-small-output \;
