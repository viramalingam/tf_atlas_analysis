version 1.0

task run_preprocess {
	input {
		String experiment
		String tuning
		Float learning_rate
		Int counts_loss_weight
		Int epochs
		String encode_access_key
		String encode_secret_key
		#gbsc-gcp-lab-kundaje-tf-atlas
		String gcp_bucket
		String pipeline_destination
		File metadata
		File reference_file
		File reference_file_index
  	}	
	command {
		#create data directories and download scripts
		cd /; mkdir my_data
		cd /scratch/
		git clone https://github.com/viramalingam/tf_atlas_analysis.git
		cd tf_atlas_analysis

		#run the params create script and preprocess script
		chmod 777 create_params.sh
		echo "run ./create_params.sh"
		./create_params.sh ${experiment} ${tuning} ${learning_rate} ${counts_loss_weight} ${epochs} ${encode_access_key} ${encode_secret_key} ${gcp_bucket} ${pipeline_destination} ${metadata}
		cp pipeline/params_file.json /cromwell_root/params_file.json	#copy the file to the root folder for cromwell to copy

		##preprocessing
		cd /scratch/tf_atlas_analysis/
		chmod 777 run_preprocessing.sh
		echo "run ./run_preprocessing.sh"
		./run_preprocessing.sh params_file.json ${encode_access_key} ${encode_secret_key} ${pipeline_destination} ${reference_file} ${reference_file_index}
		
	}
	
	output {
		File params_json = "params_file.json"
	}
	runtime {
		docker: 'vivekramalingam/tf-atlas'
		memory: 8 + "GB"
	}
}

workflow preprocess {
	input {
		String experiment
		String tuning
		Float learning_rate
		Int counts_loss_weight
		Int epochs
		String encode_access_key
		String encode_secret_key
		#gbsc-gcp-lab-kundaje-tf-atlas
		String gcp_bucket
		String pipeline_destination
		File metadata
		File reference_file
		File reference_file_index
	}

	call run_preprocess {
		input:
			experiment = experiment,
			tuning = tuning,
			learning_rate = learning_rate,
			counts_loss_weight = counts_loss_weight,
			epochs = epochs,
			encode_access_key = encode_access_key,
			encode_secret_key = encode_secret_key,
        		gcp_bucket = gcp_bucket,
			pipeline_destination = pipeline_destination,
			metadata = metadata,
			reference_file = reference_file,
			reference_file_index = reference_file_index	
 	}
	output {
		File params_json = run_preprocess.params_json

	}
}
