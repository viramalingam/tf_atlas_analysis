#!/bin/bash

# TF-Atlas pipeline
# Step 1. Copy reference files from gcp
# Step 2. Download bams and peaks file for the experiment
# Step 3. Process bam files to generate bigWigs
# Step 4. Modeling, predictions, metrics, shap, modisco, embeddings
# Step 5. Generate reports

# import the utils script
. utils.sh



# path to json file with pipeline params
pipeline_json=$1

# get params from the pipleine json
experiment=`jq .experiment $pipeline_json | sed 's/"//g'` 

echo "experiment in pipeline_json is "$experiment

peaks=`jq .peaks $pipeline_json | sed 's/"//g'`

has_control=`jq .has_control $pipeline_json | sed 's/"//g'`

stranded=`jq .stranded $pipeline_json | sed 's/"//g'`

model_arch_name=`jq .model_arch_name $pipeline_json | sed 's/"//g'`

sequence_generator_name=\
`jq .sequence_generator_name $pipeline_json | sed 's/"//g'`

splits_json_path=`jq .splits_json_path $pipeline_json | sed 's/"//g'`

test_chroms=`jq .test_chroms $pipeline_json | sed 's/"//g'`

tuning=`jq .tuning $pipeline_json | sed 's/"//g'`

learning_rate=`jq .learning_rate $pipeline_json | sed 's/"//g'`

counts_loss_weight=`jq .counts_loss_weight $pipeline_json | sed 's/"//g'`

epochs=`jq .epochs $pipeline_json | sed 's/"//g'`

gcp_bucket=`jq .gcp_bucket $pipeline_json | sed 's/"//g'`

encode_access_key=$2

encode_secret_key=$3

reference_file=${4}
reference_file_index=${5}
chrom_sizes=${6}
chroms_txt=${7}

# create log file
logfile=$experiment.log
touch $logfile


# Step 0. Create all required directories

dst_dir=$PWD/



# local reference files directory
reference_dir=${dst_dir}reference
echo $( timestamp ): "mkdir" $reference_dir | tee -a $logfile
mkdir $reference_dir

# directory to store downloaded files
downloads_dir=${dst_dir}downloads
echo $( timestamp ): "mkdir" $downloads_dir | tee -a $logfile
mkdir $downloads_dir

# directory to store bigWigs
bigWigs_dir=${dst_dir}bigWigs
echo $( timestamp ): "mkdir" $bigWigs_dir | tee -a $logfile
mkdir $bigWigs_dir

# create new directory to store model file
model_dir=${dst_dir}model
echo $( timestamp ): "mkdir" $model_dir | tee -a $logfile
mkdir $model_dir

# create new directory to store hyperparameter tuning files
tuning_dir=${dst_dir}tuning
echo $( timestamp ): "mkdir" $tuning_dir | tee -a $logfile
mkdir $tuning_dir

# dreictory to store predictions
predictions_dir=${dst_dir}predictions
echo $( timestamp ): "mkdir" $predictions_dir | tee -a $logfile
mkdir $predictions_dir

# directory to store computed embeddings
embeddings_dir=${dst_dir}embeddings
echo $( timestamp ): "mkdir" $embeddings_dir | tee -a $logfile
mkdir $embeddings_dir


# Step 1: Copy the reference files

echo $( timestamp ): "cp" $reference_file $reference_dir/ | \
tee -a $logfile 
echo $( timestamp ): "cp" $reference_file_index $reference_dir/ |\
tee -a $logfile 
echo $( timestamp ): "cp" $chroms_txt $reference_dir/ |\
tee -a $logfile 
echo $( timestamp ): "cp" $chroms_txt $reference_dir/ |\
tee -a $logfile 


cp $reference_file $reference_dir/
cp $reference_file_index $reference_dir/
cp $chrom_sizes $reference_dir/chrom.sizes
cp $chroms_txt $reference_dir/chroms.txt



# Step pre_4: Create the input json for the experiment that will
# be used in training
echo $( timestamp ): "python create_input_json.py" $experiment $peaks True \
True $bigWigs_dir $downloads_dir . | tee -a $logfile

python create_input_json.py $experiment $peaks True True $bigWigs_dir \
$downloads_dir .
    
# Step 4. Run the first M (Modeling, Metrics, Modisco)

# if [ "$tuning" = "True" ]
# then
#     # Step 4.1.0 Tuning
    
#     # We will train models with different hyperparameters and 
#     # pick the learning rate and counts_loss_weight based on the model
#     # with the lowest loss. This can be any script it just to output
#     # tuning_output.json with learning_rate and counts_loss_weight values.

#     echo $( timestamp ): "./tuning.sh" $experiment $model_arch_name \
#     $sequence_generator_name $splits_json_path $peaks $learning_rate \
#     $counts_loss_weight $epochs $reference_dir $downloads_dir $model_dir \
#     $predictions_dir $embeddings_dir $logfile $tuning_dir | tee -a $logfile

#     ./tuning.sh $experiment $model_arch_name $sequence_generator_name \
#     $splits_json_path $peaks $learning_rate $counts_loss_weight $epochs \
#     $reference_dir $downloads_dir $model_dir $predictions_dir $embeddings_dir \
#     $logfile $tuning_dir | tee -a $logfile


#     learning_rate=`jq .learning_rate tuning_output.json | sed 's/"//g'`

#     counts_loss_weight=`jq .counts_loss_weight tuning_output.json | sed 's/"//g'`
    
#     echo "learning_rate="$learning_rate
#     echo "counts_loss_weight="$counts_loss_weight

# fi

# Step 4.1.1 Modeling

echo $( timestamp ): "./modeling.sh" $experiment $model_arch_name \
$sequence_generator_name $splits_json_path $peaks $learning_rate \
$counts_loss_weight $epochs $reference_dir $downloads_dir $model_dir \
$predictions_dir $embeddings_dir $logfile | tee -a $logfile

./modeling.sh $experiment $model_arch_name $sequence_generator_name \
$splits_json_path $peaks $learning_rate $counts_loss_weight $epochs \
$reference_dir $downloads_dir $model_dir $predictions_dir $embeddings_dir \
$logfile


