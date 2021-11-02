version 1.0

task run_tuning {
	input {
		String experiment
		File input_json
		File training_input_json
		File bpnet_params_json
		File splits_json
		File reference_file
		File reference_file_index
		File chrom_sizes
		File chroms_txt
		Array [File] bigwigs
		File peaks


  	}	
	command {
		#create data directories and download scripts
		cd /; mkdir my_scripts
		cd /my_scripts
		git clone https://github.com/viramalingam/tf_atlas_analysis.git
		chmod -R 777 tf_atlas_analysis
		cd tf_atlas_analysis/kubernetes/tuning/


		##modelling

		echo "run /my_scripts/tf_atlas_analysis/hyperparameter_tuning.sh" ${experiment} ${input_json} ${training_input_json} ${bpnet_params_json} ${splits_json} ${reference_file} ${reference_file_index} ${chrom_sizes} ${chroms_txt} ${sep=',' bigwigs} ${peaks}
		/my_scripts/tf_atlas_analysis/hyperparameter_tuning.sh ${experiment} ${input_json} ${training_input_json} ${bpnet_params_json} ${splits_json} ${reference_file} ${reference_file_index} ${chrom_sizes} ${chroms_txt} ${sep=',' bigwigs} ${peaks}
		echo "copying all files to cromwell_root folder"
		
		cp /project/bpnet_params_modified.json /cromwell_root/bpnet_params_tuned.json
		cp /project/tuned_learning_rate.txt /cromwell_root/tuned_learning_rate.txt
		
	}
	
	output {
		File bpnet_params_tuned_json = "bpnet_params_tuned.json"

		Float tuned_learning_rate = read_float("tuned_learning_rate.txt")
	
	
	}

	runtime {
		docker: 'vivekramalingam/tf-atlas:gcp-tuning'
		memory: 30 + "GB"
		bootDiskSizeGb: 100
		disks: "local-disk 250 HDD"
		gpuType: "nvidia-tesla-k80"
		gpuCount: 1
		nvidiaDriverVersion: "418.87.00" 
	}
}

workflow modelling {
	input {
		String experiment
		File input_json
		File training_input_json
		File bpnet_params_json
		File splits_json
		File reference_file
		File reference_file_index
		File chrom_sizes
		File chroms_txt
		Array [File] bigwigs
		File peaks

	}

	call run_tuning {
		input:
			experiment = experiment,
			input_json = input_json,
			training_input_json = training_input_json,
			bpnet_params_json = bpnet_params_json,
			splits_json = splits_json,
			reference_file = reference_file,
			reference_file_index = reference_file_index,	
			chrom_sizes = chrom_sizes,
			chroms_txt = chroms_txt,
			bigwigs = bigwigs,
			peaks = peaks,
			peaks_for_testing = peaks_for_testing
 	}
	output {
		File bpnet_params_tuned_json = run_tuning.bpnet_params_tuned_json
		Float tuned_learning_rate = run_tuning.tuned_learning_rate
		
	}
}
