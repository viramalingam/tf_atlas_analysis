import os
import subprocess as sp
import json
import glob
from hyperopt import fmin, tpe, hp
import argparse

def parse_args():
    parser=argparse.ArgumentParser(description="run hyperparameter tuning using hyperopt")
    parser.add_argument("--input-data")
    parser.add_argument("--output-dir")
    parser.add_argument("--reference-genome")
    parser.add_argument("--chrom-sizes")
    parser.add_argument("--chroms") 
    parser.add_argument("--splits")
    parser.add_argument("--model-arch-name")
    parser.add_argument("--model-arch-params-json")
    parser.add_argument("--sequence-generator-name") 
    parser.add_argument("--threads") 
    return parser.parse_args()

def train_model(learning_rate,counts_loss_weight,args):
    comm = ["train"]
    comm += ["--input-data", args.input_data]
    comm += ["--output-dir", args.output_dir]
    comm += ["--reference-genome", args.reference_genome]
    comm += ["--chrom-sizes", args.chrom_sizes]
    comm += ["--chroms"]
    comm += args.chroms.split(",")
    comm += ["--shuffle"]
    comm += ["--epochs", "2"]
    comm += ["--splits", args.splits]
    comm += ["--model-arch-name", args.model_arch_name]
    comm += ["--model-arch-params-json", "bpnet_params_modified.json"]
    comm += ["--sequence-generator-name", args.sequence_generator_name]
    comm += ["--model-output-filename", f'experiment_lr_{str(learning_rate)}_cw_{str(counts_loss_weight)}']
    comm += ["--input-seq-len", "2114"]
    comm += ["--output-len", "1000"]
    comm += ["--threads", "2"]
    comm += ["--learning-rate", str(learning_rate)]

    proc = sp.Popen(" ".join(comm),stderr=sp.PIPE,shell=True)
    return proc.communicate()

def default_train_model(args):
	return train_model
    
def get_model_loss(history_file):
    data = json.load(open(history_file, 'r'))
    loss=data['val_profile_predictions_loss']["1"]+(100*data['val_logcounts_predictions_loss']["1"])
    return -loss



def main():

	args = parse_args()
	

	#Bounded region of parameter space

	pbounds = {
	    'learning_rate': hp.uniform('learning_rate', 0.00001, 0.01),
	    'counts_loss_weight': hp.uniform('counts_loss_weight', 10, 10000)
	}

	def train_model_and_return_model_loss(params):

		with open(args.model_arch_params_json, "r+") as f:
			text = f.read()
			text_modified = text.replace("<counts_loss_weight>", str(int(params['counts_loss_weight'])))
			print(text_modified)
			f.close()
		with open("bpnet_params_modified.json","w") as f:
			f.write(text_modified)
 

		res = train_model(params['learning_rate'],params['counts_loss_weight'],args)
		learning_rate = params['learning_rate']
		counts_loss_weight =params['counts_loss_weight']

		print(res)

		print(glob.glob(args.output_dir+'/*'))

		history_file=glob.glob(args.output_dir+f'/experiment_lr_{str(learning_rate)}_cw_{str(counts_loss_weight)}'+"*.history.json")[0]

		loss = get_model_loss(history_file)
		
		print(f'experiment_lr_{str(learning_rate)}_cw_{str(counts_loss_weight)}')
		print(loss)
		return loss
	        
	    
	params_dict = fmin(train_model_and_return_model_loss, pbounds, algo=tpe.suggest, max_evals=2)

	print(params_dict)

	params_dict['counts_loss_weight'] = int(params_dict['counts_loss_weight'])

	with open("tuned_learning_rate.txt","w") as f:
		f.write(str(params_dict['learning_rate']))


	with open(args.model_arch_params_json, "r+") as f:
		text = f.read()
		text_modified = text.replace("<counts_loss_weight>", str(int(params_dict['counts_loss_weight'])))
		print(text_modified)
		f.close()
	with open("bpnet_params_modified.json","w") as f:
		f.write(text_modified)


	return
if __name__=="__main__":
    main()