import "https://gitlab.com/intelliseq/workflows/-/raw/fq-organize@2.0.2/src/main/wdl/tasks/fq-organize/fq-organize.wdl" as fq_organize
import "https://gitlab.com/intelliseq/workflows/-/raw/rna-seq-custom-bwa@1.0.0/src/main/wdl/tasks/rna-seq-custom-bwa/rna-seq-custom-bwa.wdl" as rna_seq_custom_bwa_task
import "https://gitlab.com/intelliseq/workflows/-/raw/rna-seq-ensembl-bwa@1.0.3/src/main/wdl/tasks/rna-seq-ensembl-bwa/rna-seq-ensembl-bwa.wdl" as rna_seq_ensembl_bwa_task
import "https://gitlab.com/intelliseq/workflows/-/raw/rna-seq-bwa@1.0.3/src/main/wdl/tasks/rna-seq-bwa/rna-seq-bwa.wdl" as rna_seq_bwa_task
import "https://gitlab.com/intelliseq/workflows/-/raw/rna-seq-count@1.0.3/src/main/wdl/tasks/rna-seq-count/rna-seq-count.wdl" as rna_seq_count_task
import "https://gitlab.com/intelliseq/workflows/-/raw/rna-seq-count-concat@1.0.2/src/main/wdl/tasks/rna-seq-count-concat/rna-seq-count-concat.wdl" as rna_seq_count_concat_task
import "https://gitlab.com/intelliseq/workflows/-/raw/rna-seq-align-stats-bwa@1.0.0/src/main/wdl/tasks/rna-seq-align-stats-bwa/rna-seq-align-stats-bwa.wdl" as rna_seq_align_stats_bwa_task
import "https://gitlab.com/intelliseq/workflows/raw/bco@1.0.0/src/main/wdl/modules/bco/bco.wdl" as bco_module

workflow rna_seq_small {

  meta {
    name: 'small RNA-seq'
    price: '50'
    author: 'https://gitlab.com/MateuszMarynowski'
    copyright: 'Copyright 2020 Intelliseq'
    description: 'Data analysis workflow for small RNA-seq research.'
    changes: '{"1.10.7": "new version of fq-organize task: fixed improper processing of .fastq.gz files", "1.10.6": "new version of fq-organize task", "1.10.4": "add price to meta", "1.10.1": "deleted default id in meta"}'
    tag: 'Research'

    input_analysis_id: '{"index": 1, "name": "Analysis id", "type": "String", "description": "Enter a analysis name (or identifier)"}'
    input_fastqs: '{"index": 2, "name": "Fastq files", "type": "Array[File]", "extension": [".fq.gz",".fastq.gz"], "description": "Select gzipped fastq file [.fq.gz or .fastq.gz] for each sample."}'
    input_fastqs_left: '{"hidden":"true", "name": "Left fastq files", "type": "Array[File]", "extension": [".fq.gz"], "description": "Select gzipped fastq file [.fq.gz] for each sample."}'
    input_samples_names: '{"hidden":"true", "name": "Samples names", "type": "Array[String]", "description": "Enter samples names (or identifiers)"}'
    input_organism_name: '{"index": 3, "name": "Organism name ", "type": "String", "default": "Homo sapiens", "description": "Enter name of the organism in Latin, for example Homo sapiens, Mus musculus, Rattus norvegicus. List of available organism you can find on www.ensembl.org"}'
    input_release_version: '{"index": 4, "name": "Ensembl version", "type": "String", "default": "100", "description": "Enter ensembl database release version"}'

    output_bam_file: '{"name": "Bam", "type": "Array[File]", "copy": "True", "description": "Alignment results"}'
    output_bam_bai_file: '{"name": "Bai", "type": "Array[File]", "copy": "True", "description": "Alignment results index"}'
    output_stats_concat_excel_file: '{"name": "Stats xlsx", "type": "File", "copy": "True", "description": "Number of alignments for each FLAG type in .xlsx format"}'
    output_stats_concat_tsv_file: '{"name": "Stats tsv", "type": "File", "copy": "True", "description": "Number of alignments for each FLAG type in .tsv format"}'
    output_count_concat_excel_file: '{"name": "Counts xlsx", "type": "File", "copy": "True", "description": "Number of mapped reads in .xlsx format"}'
    output_count_concat_tsv_file: '{"name": "Counts tsv", "type": "File", "copy": "True", "description": "Number of mapped reads in .tsv format"}'
  }

  Array[File]? fastqs
  Boolean is_fastqs_defined = defined(fastqs)
  Array[File]? fastqs_left
  Array[String]? samples_names
  File? ref_genome
  File? gtf
  Boolean is_ref_genome_defined = defined(ref_genome)
  String organism_name = "Homo sapiens"
  String release_version = "100"
  String analysis_id = "no_id_provided"
  String genome_basename = sub(organism_name, " ", "_") + "_genome"
  String chromosome_name = "primary_assembly"
  String pipeline_name = "rna_seq_small"
  String pipeline_version = "1.10.7"

  if(is_fastqs_defined) {
    call fq_organize.fq_organize {
      input:
        fastqs = fastqs,
        paired = false,
        split_files = false
    }
  }
  Array[File] fastqs_1 = select_first([fq_organize.fastqs_1, fastqs_left])
  Array[String] samples_ids = select_first([fq_organize.samples_ids, samples_names])

  if(is_ref_genome_defined) {
    call rna_seq_custom_bwa_task.rna_seq_custom_bwa {
      input:
        ref_genome = ref_genome,
        genome_basename = genome_basename
    }
  }

  if(!is_ref_genome_defined) {
    call rna_seq_ensembl_bwa_task.rna_seq_ensembl_bwa {
      input:
        release_version = release_version,
        chromosome_name = chromosome_name,
        organism_name = organism_name,
        genome_basename = genome_basename
    }
  }

  Array[File] ref_genome_index = select_first([rna_seq_custom_bwa.ref_genome_index, rna_seq_ensembl_bwa.ref_genome_index])
  File gtf_file = select_first([gtf, rna_seq_ensembl_bwa.gtf_file])

  scatter (index in range(length(fastqs_1))) {
    call rna_seq_bwa_task.rna_seq_bwa {
        input:
            fastq_1 = fastqs_1[index],
            sample_id = samples_ids[index],
            ref_genome_index = ref_genome_index,
            genome_basename = genome_basename,
            index = index
    }
  }

  call rna_seq_align_stats_bwa_task.rna_seq_align_stats_bwa {
    input:
      bwa_align_stats = rna_seq_bwa.stats,
      analysis_id = analysis_id
  }

  scatter (index in range(length(fastqs_1))) {
    call rna_seq_count_task.rna_seq_count {
        input:
            gtf_file = gtf_file,
            bam_file = rna_seq_bwa.bam_file[index],
            bam_bai_file = rna_seq_bwa.bam_bai_file[index],
            sample_id = samples_ids[index],
            index = index
    }
  }

  call rna_seq_count_concat_task.rna_seq_count_concat {
    input:
      count_reads = rna_seq_count.count_reads,
      analysis_id = analysis_id
  }

# Merge bco, stdout, stderr files
  File indexing_genome_bco = select_first([rna_seq_ensembl_bwa.bco, rna_seq_custom_bwa.bco])
  File indexing_genome_stdout = select_first([rna_seq_ensembl_bwa.stdout_log, rna_seq_custom_bwa.stdout_log])
  File indexing_genome_stderr = select_first([rna_seq_ensembl_bwa.stderr_log, rna_seq_custom_bwa.stderr_log])

  Array[File] bco_tasks = select_all([fq_organize.bco, indexing_genome_bco, rna_seq_align_stats_bwa.bco, rna_seq_count_concat.bco])
  Array[File] stdout_tasks = select_all([fq_organize.stdout_log, indexing_genome_stdout, rna_seq_align_stats_bwa.stdout_log,  rna_seq_count_concat.stdout_log])
  Array[File] stderr_tasks = select_all([fq_organize.stderr_log, indexing_genome_stderr, rna_seq_align_stats_bwa.stderr_log, rna_seq_count_concat.stderr_log])

  Array[Array[File]] bco_scatters = [bco_tasks, rna_seq_bwa.bco, rna_seq_count.bco]
  Array[Array[File]] stdout_scatters = [stdout_tasks, rna_seq_bwa.stdout_log, rna_seq_count.stdout_log]
  Array[Array[File]] stderr_scatters = [stderr_tasks, rna_seq_bwa.stderr_log, rna_seq_count.stderr_log]

  Array[File] bco_array = flatten(bco_scatters)
  Array[File] stdout_array = flatten(stdout_scatters)
  Array[File] stderr_array = flatten(stderr_scatters)

  call bco_module.bco {
    input:
      bco_array = bco_array,
      stdout_array = stdout_array,
      stderr_array = stderr_array,
      module_name = pipeline_name,
      module_version = pipeline_version,
      sample_id = analysis_id
  }

  output {
    Array[File] bam_file = rna_seq_bwa.bam_file
    Array[File] bam_bai_file = rna_seq_bwa.bam_bai_file
    File stats_concat_excel_file = rna_seq_align_stats_bwa.stats_concat_excel_file
    File stats_concat_tsv_file = rna_seq_align_stats_bwa.stats_concat_tsv_file
    File count_concat_excel_file = rna_seq_count_concat.count_concat_excel_file
    File count_concat_tsv_file = rna_seq_count_concat.count_concat_tsv_file

    #bco, stdout, stderr
    File bco_merged = bco.bco_merged
    File stdout_log = bco.stdout_log
    File stderr_log = bco.stderr_log

    #bco report (pdf, odt, docx, html)
    File bco_report_pdf = bco.bco_report_pdf
    File bco_report_odt = bco.bco_report_odt
    File bco_report_docx = bco.bco_report_docx
    File bco_report_html = bco.bco_report_html

    #bco table (csv)
    File bco_table_csv = bco.bco_table_csv
  }
}
