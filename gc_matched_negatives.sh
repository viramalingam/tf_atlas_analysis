#!/bin/bash

function timestamp {
    # Function to get the current time with the new line character
    # removed 
    
    # current time
    date +"%Y-%m-%d_%H-%M-%S" | tr -d '\n'
}


experiment=$1
reference_file=$2
reference_file_index=$3
chrom_sizes=$4
chroms_txt=$5
peaks=$6

mkdir /project
project_dir=/project

# create the log file
logfile=$project_dir/${1}_gc_matched_negatives.log
touch $logfile

# create the data directory
data_dir=$project_dir/data
echo $( timestamp ): "mkdir" $data_dir | tee -a $logfile
mkdir $data_dir

# create the reference directory
reference_dir=$project_dir/reference
echo $( timestamp ): "mkdir" $reference_dir | tee -a $logfile
mkdir $reference_dir

# copy down inliers bed file and reference files


echo $( timestamp ): "cp" $peaks ${data_dir}/${1}_inliers.bed.gz |\
tee -a $logfile 

cp $peaks ${data_dir}/${1}_inliers.bed.gz

echo $( timestamp ): "gunzip" ${data_dir}/${1}_inliers.bed.gz |\
tee -a $logfile 

gunzip ${data_dir}/${1}_inliers.bed.gz


# copy down data and reference
echo $( timestamp ): "cp" $reference_file ${reference_dir}/hg38.genome.fa | \
tee -a $logfile 

echo $( timestamp ): "cp" $reference_file_index ${reference_dir}/hg38.genome.fa.fai |\
tee -a $logfile 

echo $( timestamp ): "cp" $chrom_sizes ${reference_dir}/chrom.sizes |\
tee -a $logfile 

echo $( timestamp ): "cp" $chroms_txt ${reference_dir}/hg38_chroms.txt |\
tee -a $logfile 


# copy down data and reference

cp $reference_file ${reference_dir}/hg38.genome.fa
cp $reference_file_index ${reference_dir}/hg38.genome.fa.fai
cp $chrom_sizes $reference_dir/chrom.sizes
cp $chroms_txt $reference_dir/hg38_chroms.txt




echo $( timestamp ): "
python /tfatlas/SVM_pipelines/make_inputs/get_gc_content.py \\
       --input_bed $data_dir/${1}_inliers.bed \\
       --ref_fasta $reference_dir/hg38.genome.fa \\
       --out_prefix $data_dir/$experiment.gc \\
       --center_summit \\
       --flank_size 1057 \\
       --store_seq" | tee -a $logfile 

python /tfatlas/SVM_pipelines/make_inputs/get_gc_content.py \
       --input_bed $data_dir/${1}_inliers.bed \
       --ref_fasta $reference_dir/hg38.genome.fa \
       --out_prefix $data_dir/$experiment.gc \
       --center_summit \
       --flank_size 1057 \
       --store_seq

echo $( timestamp ): "bedtools intersect -v -a" $reference_dir/gc_hg38_nosmooth.tsv \
"-b" $data_dir/${1}_inliers.bed > $data_dir/${experiment}.tsv  | tee -a $logfile 

bedtools intersect -v -a $reference_dir/gc_hg38_nosmooth.tsv \
-b $data_dir/${1}_inliers.bed > $data_dir/${experiment}.tsv

echo $( timestamp ): "
python /tfatlas/SVM_pipelines/SVM_pipelines/make_inputs/get_chrom_gc_region_dict.py \\
    --input_bed $data_dir/${experiment}.tsv \\
    --outf $data_dir/${experiment}.gc.p" | tee -a $logfile 

python /tfatlas/SVM_pipelines/SVM_pipelines/make_inputs/get_chrom_gc_region_dict.py \
    --input_bed $data_dir/$experiment.tsv \
    --outf $data_dir/${experiment}.gc.p

echo $( timestamp ): "
python /my_scripts/tf_atlas_analysis/create_negatives_bed.py \\
    --out-bed $data_dir/peaks_gc_neg_combined.bed \\
    --neg-pickle $data_dir/$experiment.gc.p \\
    --ref-fasta $reference_dir/hg38.genome.fa \\
    --peaks $data_dir/${experiment}.gc" | tee -a $logfile 

python /my_scripts/tf_atlas_analysis/create_negatives_bed.py \
    --out-bed $data_dir/peaks_gc_neg_combined.bed \
    --neg-pickle $data_dir/${experiment}.gc.p \
    --ref-fasta $reference_dir/hg38.genome.fa1 \
    --peaks $data_dir/${experiment}.gc

    
