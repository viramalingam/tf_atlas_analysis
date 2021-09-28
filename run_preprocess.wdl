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
  	}	
	command {
		cd /; mkdir my_data
		cd /scratch/
		git clone https://github.com/viramalingam/tf_atlas_analysis.git
		cd tf_atlas_analysis
		chmod 777 run_preprocess.sh
		echo "run ./run_preprocess.sh"
		ls
		echo "metadata path: ${metadata}" 
		./run_preprocess.sh ${experiment} ${tuning} ${learning_rate} ${counts_loss_weight} ${epochs} ${encode_access_key} ${encode_secret_key} ${gcp_bucket} ${pipeline_destination} ${metadata}
		cp params_file.json /cromwell_root/params_file.json	
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
			metadata = metadata	
 	}

}
