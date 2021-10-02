version 1.0

task run_modelling {
	input {
		String experiment
		String encode_access_key
		String encode_secret_key
		File reference_file
		File reference_file_index
		File chrom_sizes
		File chroms_txt
		File params_file
		Array [File] bigwigs
		File peaks
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
		../run_modelling.sh ${params_file} ${encode_access_key} ${encode_secret_key} ${reference_file} ${reference_file_index} ${chrom_sizes} ${chroms_txt} ${bigwigs} ${peaks}
		
		cp *.json /cromwell_root/inputs.json
		cp model /cromwell_root/
		cp predictions /cromwell_root/
		cp embeddings /cromwell_root/
		
	}
	
	output {
		File inputs_json = "inputs.json"
		Array[File] model = glob("model/*")
		Array[File] predictions = glob("predictions/*")
		Array[File] embeddings = glob("embeddings/*")

	
	}

	runtime {
		docker: 'vivekramalingam/tf-atlas'
		memory: 30 + "GB"
		bootDiskSizeGb: 100
		disks: "local-disk 1000 HDD"
		gpuType: "nvidia-tesla-k80"
		gpuCount: 1
		nvidiaDriverVersion: "418.87.00" 
	}
}

workflow modelling {
	input {
		String experiment
		String encode_access_key
		String encode_secret_key
		#gbsc-gcp-lab-kundaje-tf-atlas
		File reference_file
		File reference_file_index
		File chrom_sizes
		File chroms_txt
		File params_file
		Array [File] bigwigs
		File peaks
	}

	call run_modelling {
		input:
			experiment = experiment,
			encode_access_key = encode_access_key,
			encode_secret_key = encode_secret_key,
			reference_file = reference_file,
			reference_file_index = reference_file_index,	
			chrom_sizes = chrom_sizes,
			chroms_txt = chroms_txt,
			params_file = params_file,
			bigwigs = bigwigs,
			peaks = peaks
 	}
	output {
		File inputs_json = run_modelling.inputs_json
		Array[File] model = run_modelling.model
		Array[File] predictions = run_modelling.predictions
		Array[File] embeddings = run_modelling.embeddings

	}
}
