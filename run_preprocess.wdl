version 1.0

task run_preprocess {
  String experiment
  String gcp_bucket
  String pipeline_destination
  File metadata

  command {
    cd /; mkdir my_data
    cd /scratch/
    git clone https://github.com/viramalingam/tf_atlas_analysis.git
    cd tf_atlas_analysis
    sudo chmod 777 run_preprocess.sh
    echo "run ./run_preprocess.sh" 
    ./run_preprocess.sh
  }
  output {
    File response = stdout()
  }
  runtime {
   docker: 'vivekramalingam/tf-atlas'
  }
}

workflow preprocess {
  String experiment
  String? gcp_bucket 
  String gcp_bucket = select_first([gcp_bucket, "gbsc-gcp-lab-kundaje-tf-atlas"])

  String pipeline_destination
  File metadata

  call run_preprocess {
    input:
    	experiment = experiment,
        gcp_bucket = gcp_bucket,
	pipeline_destination = pipeline_destination,
	metadata = metadata	
  }

}
