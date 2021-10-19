version 1.0

task run_outlier_detection {
	input {
		String experiment
		File input_outlier_json
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
		cd tf_atlas_analysis/kubernetes/outlier_detection/


		##outlier_detection

		echo "run /my_scripts/tf_atlas_analysis/outlier_detection.sh" ${experiment} ${input_outlier_json} ${reference_file} ${reference_file_index} ${chrom_sizes} ${chroms_txt} ${sep=',' bigwigs} ${peaks}
		/my_scripts/tf_atlas_analysis/outlier_detection.sh ${experiment} ${input_outlier_json} ${reference_file} ${reference_file_index} ${chrom_sizes} ${chroms_txt} ${sep=',' bigwigs} ${peaks}

		echo "copying all files to cromwell_root folder"
		
		cp /project/peaks_inliers.bed /cromwell_root/peaks_inliers.bed
		
	}
	
	output {
		File peaks_inliers_bed = "peaks_inliers.bed"
	
	
	}

	runtime {
		docker: 'kundajelab/tf-atlas:gcp-outliers'
		memory: 30 + "GB"
		bootDiskSizeGb: 100
		disks: "local-disk 250 HDD"

	}
}

workflow outlier_detection {
	input {
		String experiment
		File input_outlier_json
		File reference_file
		File reference_file_index
		File chrom_sizes
		File chroms_txt
		Array [File] bigwigs
		File peaks
	}

	call run_outlier_detection {
		input:
			experiment = experiment,
			input_outlier_json = input_outlier_json,
			reference_file = reference_file,
			reference_file_index = reference_file_index,	
			chrom_sizes = chrom_sizes,
			chroms_txt = chroms_txt,
			bigwigs = bigwigs,
			peaks = peaks
 	}
	output {
		File peaks_inliers_bed = run_outlier_detection.peaks_inliers_bed
		
	}
}
