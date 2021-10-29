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
reference_gc_hg38_nosmooth=$6
peaks=$7
ratio=$8

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

echo $( timestamp ): "cp" $reference_gc_hg38_nosmooth ${reference_dir}/gc_hg38_nosmooth.tsv |\
tee -a $logfile 

# copy down data and reference

cp $reference_file ${reference_dir}/hg38.genome.fa
cp $reference_file_index ${reference_dir}/hg38.genome.fa.fai
cp $chrom_sizes $reference_dir/chrom.sizes
cp $chroms_txt $reference_dir/hg38_chroms.txt
cp $reference_gc_hg38_nosmooth ${reference_dir}/gc_hg38_nosmooth.tsv



echo $( timestamp ): "
python /tfatlas/SVM_pipelines/make_inputs/get_gc_content.py \\
       --input_bed $data_dir/${1}_inliers.bed \\
       --ref_fasta $reference_dir/hg38.genome.fa \\
       --out_prefix $data_dir/$experiment.gc \\
       --center_summit \\
       --flank_size 1057 \\
       --store_seq" | tee -a $logfile 

python get_gc_content.py \
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
python /tfatlas/SVM_pipelines/make_inputs/get_chrom_gc_region_dict.py \\
    --input_bed $data_dir/${experiment}.tsv \\
    --outf $data_dir/${experiment}.gc.p" | tee -a $logfile 

python get_chrom_gc_region_dict.py \
    --input_bed $data_dir/$experiment.tsv \
    --outf $data_dir/${experiment}.gc.p

echo $( timestamp ): "
python /tfatlas/SVM_pipelines/make_inputs/create_negatives_bed.py \\
    --out-bed $data_dir/${experiment}_negatives.bed \\
    --neg-pickle $data_dir/$experiment.gc.p \\
    --ref-fasta $reference_dir/hg38.genome.fa \\
    --peaks $data_dir/${experiment}.gc" | tee -a $logfile 

python create_negatives_bed.py \
    --out-bed $data_dir/${experiment}_negatives.bed \
    --neg-pickle $data_dir/${experiment}.gc.p \
    --ref-fasta $reference_dir/hg38.genome.fa \
    --peaks $data_dir/${experiment}.gc

# select negatives based on specified ratio

# count the number of lines in the bed file
echo $( timestamp ): "num_negatives=`cat $data_dir/${experiment}_negatives.bed | wc -l`" | tee -a $logfile 
num_negatives=`cat $data_dir/${experiment}_negatives.bed | wc -l`

# number of lines to select
echo $( timestamp ): "num_select=($num_negatives / $ratio)" | tee -a $logfile 
num_select=$(( num_negatives / ratio ))

# select random rows
echo $( timestamp ): "shuf -n" $num_select $data_dir/${experiment}_negatives.bed \
">" $data_dir/${experiment}_negatives_select.bed | tee -a $logfile 
shuf -n $num_select $data_dir/${experiment}_negatives.bed > \
    $data_dir/${experiment}_negatives_select.bed

# combine the gc matched negatives and the original peaks file into 
# a single file
echo $( timestamp ): "cat" $data_dir/${1}_inliers.bed $data_dir/${experiment}_negatives_select.bed ">" \
    $data_dir/peaks_gc_neg_combined.bed  | tee -a $logfile 

cat $data_dir/${1}_inliers.bed $data_dir/${experiment}_negatives_select.bed > \
    $data_dir/peaks_gc_neg_combined.bed

    
