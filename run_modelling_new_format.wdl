version 1.0

task run_modelling {
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
		cd tf_atlas_analysis/kubernetes/modeling/


		##modelling

		ls -al /my_scripts/tf_atlas_analysis/

		echo "run /my_scripts/tf_atlas_analysis/modelling_new_format.sh" ${experiment} ${input_json} ${training_input_json} ${bpnet_params_json} ${splits_json} ${reference_file} ${reference_file_index} ${chrom_sizes} ${chroms_txt} ${sep=',' bigwigs} ${peaks}
		/my_scripts/tf_atlas_analysis/modelling_new_format.sh ${experiment} ${input_json} ${training_input_json} ${bpnet_params_json} ${splits_json} ${reference_file} ${reference_file_index} ${chrom_sizes} ${chroms_txt} ${sep=',' bigwigs} ${peaks}

		echo "copying all files to cromwell_root folder"
		
		cp /project/bpnet_params.json /cromwell_root/bpnet_params.json
		cp -r /project/model /cromwell_root/
		cp -r /project/predictions_and_metrics /cromwell_root/
		cp -r /project/predictions_and_metrics/spearman.txt /cromwell_root/spearman.txt
		cp -r /project/predictions_and_metrics/pearson.txt /cromwell_root/pearson.txt
		
	}
	
	output {
		File bpnet_params_updated_json = "bpnet_params.json"
		Array[File] model = glob("model/*")
		Array[File] predictions_and_metrics = glob("predictions_and_metrics/*")
		Float spearman = read_float("spearman.txt")
		Float pearson = read_float("pearson.txt")
	
	
	}

	runtime {
		docker: 'kundajelab/tf-atlas:gcp-modeling'
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

	call run_modelling {
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
			peaks = peaks
 	}
	output {
		File bpnet_params_updated_json = run_modelling.bpnet_params_updated_json
		Array[File] model = run_modelling.model
		Array[File] predictions_and_metrics = run_modelling.predictions_and_metrics
		Float spearman = run_modelling.spearman
		Float pearson = run_modelling.pearson
		
	}
}
