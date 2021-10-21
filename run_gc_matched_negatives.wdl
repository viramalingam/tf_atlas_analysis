version 1.0

task run_gc_matched_negatives {
	input {
		String experiment
		File input_outlier_json
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
		cd tf_atlas_analysis/kubernetes/gc_matched_negatives/


		##outlier_detection

		echo "run /my_scripts/tf_atlas_analysis/gc_matched_negatives.sh" ${experiment} ${input_outlier_json} ${chrom_sizes} ${chroms_txt} ${sep=',' bigwigs} ${peaks}
		/my_scripts/tf_atlas_analysis/gc_matched_negatives.sh ${experiment} ${input_outlier_json} ${chrom_sizes} ${chroms_txt} ${sep=',' bigwigs} ${peaks}

		echo "copying all files to cromwell_root folder"

		gzip /project/peaks_gc_neg_combined.bed
		
		cp /project/peaks_gc_neg_combined.bed.bed.gz /cromwell_root/peaks_gc_neg_combined.bed.gz
		
	}
	
	output {
		File peaks_gc_neg_combined_bed = "peaks_gc_neg_combined.bed.gz"
	
	
	}

	runtime {
		docker: 'kundajelab/tf-atlas:gcp-gc_matching'
		memory: 30 + "GB"
		bootDiskSizeGb: 100
		disks: "local-disk 250 HDD"

	}
}

workflow gc_matched_negatives {
	input {
		String experiment
		File input_outlier_json
		File chrom_sizes
		File chroms_txt
		Array [File] bigwigs
		File peaks
	}

	call run_gc_matched_negatives {
		input:
			experiment = experiment,
			input_outlier_json = input_outlier_json,
			chrom_sizes = chrom_sizes,
			chroms_txt = chroms_txt,
			bigwigs = bigwigs,
			peaks = peaks
 	}
	output {
		File peaks_gc_neg_combined_bed = run_outlier_detection.peaks_gc_neg_combined_bed
		
	}
}
