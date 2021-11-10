#!/bin/bash

function timestamp {
    # Function to get the current time with the new line character
    # removed 
    
    # current time
    date +"%Y-%m-%d_%H-%M-%S" | tr -d '\n'
}

experiment=$1
training_input_json=$2
bpnet_params_json=$3
splits_json=$4
reference_file=$5
reference_file_index=$6
chrom_sizes=$7
chroms_txt=${8}
bigwigs=${9}
peaks=${10}
tuning_algorithm=${11}

# create the log file
logfile=$project_dir/${1}_tuning.log
touch $logfile


mkdir /project
project_dir=/project

# create the log file
logfile=$project_dir/${1}_modeling.log
touch $logfile

# create the data directory
data_dir=$project_dir/data
echo $( timestamp ): "mkdir" $data_dir | tee -a $logfile
mkdir $data_dir

# create the reference directory
reference_dir=$project_dir/reference
echo $( timestamp ): "mkdir" $reference_dir | tee -a $logfile
mkdir $reference_dir

# create the model directory
tuning_dir=$project_dir/tuning
echo $( timestamp ): "mkdir" $tuning_dir | tee -a $logfile
mkdir $tuning_dir



echo $( timestamp ): "cp" $reference_file ${reference_dir}/hg38.genome.fa | \
tee -a $logfile 

echo $( timestamp ): "cp" $reference_file_index ${reference_dir}/hg38.genome.fa.fai |\
tee -a $logfile 

echo $( timestamp ): "cp" $chrom_sizes ${reference_dir}/chrom.sizes |\
tee -a $logfile 

echo $( timestamp ): "cp" $chroms_txt ${reference_dir}/hg38_chroms.txt |\
tee -a $logfile 


# copy down data and reference

cp $reference_file $reference_dir/hg38.genome.fa
cp $reference_file_index $reference_dir/hg38.genome.fa.fai
cp $chrom_sizes $reference_dir/chrom.sizes
cp $chroms_txt $reference_dir/hg38_chroms.txt


# Step 1: Copy the bigwig and peak files

echo $bigwigs | sed 's/,/ /g' | xargs cp -t $data_dir/

echo $( timestamp ): "cp" $bigwigs ${data_dir}/ |\
tee -a $logfile 



echo $( timestamp ): "cp" $peaks ${data_dir}/${experiment}_combined.bed.gz |\
tee -a $logfile 

cp $peaks ${data_dir}/${experiment}_combined.bed.gz

echo $( timestamp ): "gunzip" ${data_dir}/${experiment}_combined.bed.gz |\
tee -a $logfile 

gunzip ${data_dir}/${experiment}_combined.bed.gz

ls ${data_dir}/

echo number of peaks in $peaks `zcat ${data_dir}/${experiment}_combined.bed | wc -l`



# cp input json template

# First the input json for the train command (with loci from 
# the combined bed file, peaks + gc-matched negatives)

echo $( timestamp ): "cp" $training_input_json \
$project_dir/training_input.json | tee -a $logfile 
cp $training_input_json $project_dir/training_input.json

# modify the input json 
echo  $( timestamp ): "sed -i -e" "s/<>/$1/g" $project_dir/training_input.json 
sed -i -e "s/<>/$1/g" $project_dir/training_input.json | tee -a $logfile 




# cp bpnet params json template
echo $( timestamp ): "cp" $bpnet_params_json \
$project_dir/bpnet_params.json| tee -a $logfile 
cp $bpnet_params_json $project_dir/bpnet_params.json



# cp splits json template
echo $( timestamp ): "cp" $splits_json \
$project_dir/splits.json | tee -a $logfile 
cp $splits_json $project_dir/splits.json



#set threads based on number of peaks

if [ $(wc -l < ${data_dir}/${experiment}_combined.bed) -lt 3500 ];then
    threads=1
else
    threads=2
fi

echo $( timestamp ):"
python /my_scripts/tf_atlas_analysis/tuning.py \
    --input-data $project_dir/training_input.json \
    --output-dir $tuning_dir \
    --reference-genome $reference_dir/hg38.genome.fa \
    --chrom-sizes $reference_dir/chrom.sizes \
    --chroms $(paste -s -d ',' $reference_dir/hg38_chroms.txt) \
    --splits $project_dir/splits.json\
    --model-arch-name BPNet \
    --model-arch-params-json $project_dir/bpnet_params.json \
    --sequence-generator-name BPNet \
    --threads $threads
    --algorithm $tuning_algorithm" | tee -a $logfile 

python /my_scripts/tf_atlas_analysis/tuning.py \
    --input-data $project_dir/training_input.json \
    --output-dir $tuning_dir \
    --reference-genome $reference_dir/hg38.genome.fa \
    --chrom-sizes $reference_dir/chrom.sizes \
    --chroms $(paste -s -d ',' $reference_dir/hg38_chroms.txt) \
    --splits $project_dir/splits.json\
    --model-arch-name BPNet \
    --model-arch-params-json $project_dir/bpnet_params.json \
    --sequence-generator-name BPNet \
    --threads $threads
    --algorithm $tuning_algorithm
