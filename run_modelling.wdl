version 1.0

task run_modelling {
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
		File chrom_sizes
  	}	
	command {
		#create data directories and download scripts
		cd /; mkdir my_data
		cd /my_data
		git clone https://github.com/viramalingam/tf_atlas_analysis.git
		chmod -R 777 tf_atlas_analysis
		cd tf_atlas_analysis/pipeline

		nvidia-smi


		##modelling
		echo "run ../run_modelling.sh"
		../run_modelling.sh params_file.json ${encode_access_key} ${encode_secret_key} ${pipeline_destination} ${reference_file} ${reference_file_index} ${chrom_sizes}
		
		cp *.json /cromwell_root/inputs.json
		cp model /cromwell_root/
		cp predictions /cromwell_root/
		cp embeddings /cromwell_root/
		
	}
	
	output {
		File inputs_json = "inputs.json"
		Array[File] model = glob("model/*")
		Array[File] predictions = glob("model/*")
		Array[File] embeddings = glob("model/*")

	
	}

	runtime {
		docker: 'vivekramalingam/tf-atlas'
		memory: 60 + "GB"
		bootDiskSizeGb: 100
		disks: "local-disk 1000 HDD"
		gpuType: "nvidia-tesla-k80"
		gpuCount: 2
		nvidiaDriverVersion: "418.87.00" 
	}
}

workflow modelling {
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
		File chrom_sizes
		File chroms_txt
	}

	call run_modelling {
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
			reference_file_index = reference_file_index,	
			chrom_sizes = chrom_sizes

 	}
	output {
		File inputs_json = run_modelling.inputs_json
		Array[File] model = run_modelling.model
		Array[File] predictions = run_modelling.predictions
		Array[File] embeddings = run_modelling.embeddings

	}
}
