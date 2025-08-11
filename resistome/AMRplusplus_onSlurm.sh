#!/bin/bash

# -------------------------------
# SLURM Job Configuration
# -------------------------------

#SBATCH --job-name=AMR++_kraken                # Job name
#SBATCH --account=def-<your-account>           # Replace with your allocation account
#SBATCH --nodes=1                              # Number of nodes
##SBATCH --ntasks=20                           # Alternative: number of tasks for single node (commented)
#SBATCH --ntasks-per-node=1                    # Tasks per node (for multiple nodes)
#SBATCH --cpus-per-task=64                     # Number of CPUs per task
#SBATCH --mem-per-cpu=15000M                   # Memory per CPU (15 GB)
#SBATCH --output=../logsAMR/%x_%A_%a.out       # Standard output log file
#SBATCH --error=../logsAMR/%x_%A_%a.err        # Standard error log file
#SBATCH --time=70:00:00                        # Walltime (70 hours)
#SBATCH --mail-user=xxx@xx.com                 # Email for job notifications
#SBATCH --mail-type=ALL                        # Email on job BEGIN, END, FAIL, etc.

# -------------------------------
# Load Required Modules
# -------------------------------

module load nextflow/22.10.8
module load java/13.0.2
module load fastqc/0.11.9
module load trimmomatic/0.39
module load python/3.9.6
module load scipy-stack/2022a
module load mugqic/MultiQC/1.12
module load bedtools/2.29.2
module load bwa/0.7.17
module load kraken2/2.1.2
module load samtools/1.17
module load bracken/2.7
module load kronatools/2.8

# -------------------------------
# Set Paths to Databases and Resources
# -------------------------------

amrDB="../data/amr/megares_database_v3.00.fasta"                # MEGARes AMR gene database
annotDB="../data/amr/megares_annotations_v3.00.csv"             # Annotations for MEGARes database
adapterFile="../data/adapters/sequencing-adapters.fa"           # Adapter sequences for trimming
krakenDatabase="../data/bacteria_AMR/"                          # Kraken2 database path
outPath="../resistome/results/amrPPresults"                     # Output directory

# -------------------------------
# Run AMR++ Pipeline with Nextflow
# -------------------------------

nextflow run main_AMR++.nf \
  -profile local \
  --pipeline standard_AMR_wKraken \
  --reads "../data/raw/*_R{1,2}.fastq.gz" \                      # Input paired-end FASTQ files
  --host "../data/host/GCF_016699485.2_bGalGal1.mat.broiler.GRCg7b_genomic.fna.gz" \  # Host genome for filtering
  --host_index "../data/host/GCF_016699485.2_bGalGal1.mat.broiler.GRCg7b_genomic.fna.gz*" \  # Host BWA index
  --amr ${amrDB} \                                               # AMR gene database (FASTA)
  --annotation ${annotDB} \                                      # AMR annotations (CSV)
  --adapters ${adapterFile} \                                    # Adapter file for Trimmomatic
  --kraken_db ${krakenDatabase} \                                # Kraken2 database path
  --leading 3 --trailing 3 --minlen 15 --slidingwindow 5:20 \    # Trimmomatic quality settings
  --kraken_confidence 0.5 \                                      # Kraken2 confidence threshold
  --threshold 80 --min 1 --max 100 --skip 5 --samples 5 \        # Parameters for SNP and alignment filtering
  --threads 64 \                                                 # Number of threads to use
  --prefix "xxx" \                                               # Sample output prefix
  --deduped Y --snp Y \                                          # Enable deduplication and SNP calling
  --output ${outPath} \                                          # Output directory
  -w ../resistome/AMRplusplus/work                               # Nextflow work directory

