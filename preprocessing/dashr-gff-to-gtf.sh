#!/usr/bin/env bash

cat data/dashr.v2.sncRNA.annotation.hg38.gff | grep ID= | cut -d ';' -f 1 | sed 's/ID=/gene_id "/' | sed 's/$/"/' | awk -v OFS='\t' -v FS='\t' '{t=$9; sub(/gene_id/, "transcript_id", t); print $1,$2,"gene",$4,$5,$6,$7,$8,$9; print $1,$2,"trancript",$4,$5,$6,$7,$8,$9"; "t; print $1,$2,"exon",$4,$5,$6,$7,$8,$9"; "t;}' > data/dashr.v2.sncRNA.annotation.hg38.gtf
