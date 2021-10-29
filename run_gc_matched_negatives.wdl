version 1.0

task run_gc_matched_negatives {
	input {
		String experiment
		File reference_file
		File reference_file_index
		File chrom_sizes
		File chroms_txt
		File reference_gc_hg38_nosmooth
		File peaks
		Int ratio

  	}	
	command {
		#create data directories and download scripts
		cd /; mkdir my_scripts
		cd /my_scripts
		git clone https://github.com/viramalingam/tf_atlas_analysis.git
		chmod -R 777 tf_atlas_analysis
		cd tf_atlas_analysis/kubernetes/gc_matched_negatives/




		##outlier_detection

		echo "run /my_scripts/tf_atlas_analysis/gc_matched_negatives.sh" ${experiment} ${reference_file} ${reference_file_index} ${chrom_sizes} ${chroms_txt} ${reference_gc_hg38_nosmooth} ${peaks} ${ratio}
		/my_scripts/tf_atlas_analysis/gc_matched_negatives.sh ${experiment} ${reference_file} ${reference_file_index} ${chrom_sizes} ${chroms_txt} ${reference_gc_hg38_nosmooth} ${peaks} ${ratio}

		echo "copying all files to cromwell_root folder"

		gzip /project/data/peaks_gc_neg_combined.bed
		
		cp /project/data/peaks_gc_neg_combined.bed.gz /cromwell_root/peaks_gc_neg_combined.bed.gz
		
	}
	
	output {
		File peaks_gc_neg_combined_bed = "peaks_gc_neg_combined.bed.gz"
	
	
	}

	runtime {
		docker: 'vivekramalingam/tf-atlas:gcp-gc_matching'
		memory: 30 + "GB"
		bootDiskSizeGb: 100
		disks: "local-disk 250 HDD"

	}
}

workflow gc_matched_negatives {
	input {
		String experiment
		File reference_file
		File reference_file_index
		File chrom_sizes
		File chroms_txt
		File reference_gc_hg38_nosmooth
		File peaks
		Int ratio
	}

	call run_gc_matched_negatives {
		input:
			experiment = experiment,
			reference_file = reference_file,
			reference_file_index = reference_file_index,
			chrom_sizes = chrom_sizes,
			chroms_txt = chroms_txt,
			reference_gc_hg38_nosmooth = reference_gc_hg38_nosmooth,
			peaks = peaks,
			ratio = ratio
 	}
	output {
		File peaks_gc_neg_combined_bed = run_gc_matched_negatives.peaks_gc_neg_combined_bed
		
	}
}
