#!/bin/bash

function timestamp {
    # Function to get the current time with the new line character
    # removed 
    
    # current time
    date +"%Y-%m-%d_%H-%M-%S" | tr -d '\n'
}

experiment=$1
input_json=$2
training_input_json=$3
bpnet_params_json=$4
splits_json=$5
reference_file=$6
reference_file_index=$7
chrom_sizes=$8
chroms_txt=${9}
bigwigs=${10}
peaks=${11}
learning_rate=${12}


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
model_dir=$project_dir/model
echo $( timestamp ): "mkdir" $model_dir | tee -a $logfile
mkdir $model_dir

# create the predictions directory
predictions_dir=$project_dir/predictions_and_metrics
echo $( timestamp ): "mkdir" $predictions_dir | tee -a $logfile
mkdir $predictions_dir


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


# cp input json template

# First the input json for the train command (with loci from 
# the combined bed file, peaks + gc-matched negatives)

echo $( timestamp ): "cp" $training_input_json \
$project_dir/training_input.json | tee -a $logfile 
cp $training_input_json $project_dir/training_input.json

# modify the input json 
echo  $( timestamp ): "sed -i -e" "s/<>/$1/g" $project_dir/training_input.json 
sed -i -e "s/<>/$1/g" $project_dir/training_input.json | tee -a $logfile 

# Finally, the input json for the rest of the commands (without
# gc-matched negatives)
echo $( timestamp ): "cp" $input_json \
$project_dir/input.json | tee -a $logfile 
cp $input_json $project_dir/input.json



# modify the input json for 
echo  $( timestamp ): "sed -i -e" "s/<>/$1/g" $project_dir/input.json 
sed -i -e "s/<>/$1/g" $project_dir/input.json | tee -a $logfile 

# cp bpnet params json template
echo $( timestamp ): "cp" $bpnet_params_json \
$project_dir/bpnet_params.json| tee -a $logfile 
cp $bpnet_params_json $project_dir/bpnet_params.json



# cp splits json template
echo $( timestamp ): "cp" $splits_json \
$project_dir/splits.json | tee -a $logfile 
cp $splits_json $project_dir/splits.json



# compute the counts loss weight to be used for this experiment
echo $( timestamp ): "counts_loss_weight=\`counts_loss_weight --input-data \
$project_dir/input.json\`" | tee -a $logfile
counts_loss_weight=`counts_loss_weight --input-data $project_dir/input.json`

# print the counts loss weight
echo $( timestamp ): "counts_loss_weight:" $counts_loss_weight | tee -a $logfile 

# modify the bpnet params json to reflect the counts loss weight
echo  $( timestamp ): "sed -i -e" "s/<>/$counts_loss_weight/g" \
$project_dir/bpnet_params.json | tee -a $logfile 
sed -i -e "s/<>/$counts_loss_weight/g" $project_dir/bpnet_params.json

#set threads based on number of peaks

if [ $(wc -l < ${data_dir}/${experiment}_combined.bed) -lt 3500 ];then
    threads=1
else
    threads=2
fi



echo $( timestamp ): "
train \\
    --input-data $project_dir/training_input.json \\
    --output-dir $model_dir \\
    --reference-genome $reference_dir/hg38.genome.fa \\
    --chrom-sizes $reference_dir/chrom.sizes \\
    --chroms $(paste -s -d ' ' $reference_dir/hg38_chroms.txt)  \\
    --shuffle \\
    --epochs 100 \\
    --splits $project_dir/splits.json \\
    --model-arch-name BPNet \\
    --model-arch-params-json $project_dir/bpnet_params.json \\
    --sequence-generator-name BPNet \\
    --model-output-filename $1 \\
    --input-seq-len 2114 \\
    --output-len 1000 \\
    --threads $threads \\
    --learning-rate $learning_rate" | tee -a $logfile 

train \
    --input-data $project_dir/training_input.json \
    --output-dir $model_dir \
    --reference-genome $reference_dir/hg38.genome.fa \
    --chrom-sizes $reference_dir/chrom.sizes \
    --chroms $(paste -s -d ' ' $reference_dir/hg38_chroms.txt)  \
    --shuffle \
    --epochs 100 \
    --splits $project_dir/splits.json \
    --model-arch-name BPNet \
    --model-arch-params-json $project_dir/bpnet_params.json \
    --sequence-generator-name BPNet \
    --model-output-filename $1 \
    --input-seq-len 2114 \
    --output-len 1000 \
    --threads $threads \
    --learning-rate $learning_rate

echo $( timestamp ): "
fastpredict \\
    --model $model_dir/${1}_split000.h5 \\
    --chrom-sizes $reference_dir/chrom.sizes \\
    --chroms chr1 \\
    --reference-genome $reference_dir/hg38.genome.fa \\
    --output-dir $predictions_dir \\
    --input-data $project_dir/input.json \\
    --sequence-generator-name BPNet \\
    --input-seq-len 2114 \\
    --output-len 1000 \\
    --output-window-size 1000 \\
    --batch-size 64 \\
    --threads 2" | tee -a $logfile 

fastpredict \
    --model $model_dir/${1}_split000.h5 \
    --chrom-sizes $reference_dir/chrom.sizes \
    --chroms chr1 \
    --reference-genome $reference_dir/hg38.genome.fa \
    --output-dir $predictions_dir \
    --input-data $project_dir/input.json \
    --sequence-generator-name BPNet \
    --input-seq-len 2114 \
    --output-len 1000 \
    --output-window-size 1000 \
    --batch-size 64 \
    --threads 2

# create necessary files to copy the predictions results to cromwell folder

tail -n 1 $predictions_dir/predict.log | awk '{print $NF}' > $predictions_dir/spearman.txt
tail -n 2 $predictions_dir/predict.log | head -n 1 | awk '{print $NF}' > $predictions_dir/pearson.txt
tail -n 7 $predictions_dir/predict.log | head -n 1 | awk '{print $NF}' > $predictions_dir/jsd.txt

