"""Plot ROC curve
"""

from __future__ import print_function
import os
import sys
import argparse
import os.path
import nibabel as nib
import numpy as np
import json
import csv
from nibabel.streamlines import load, save 
from utils import compute_kdtree_and_dr_tractogram, streamlines_idx
#import matplotlib.pyplot as plt
from sklearn.metrics import roc_curve, auc
from utils import resample_tractogram


def compute_roc_curve(candidate_idx_ranked, true_tract, target_tractogram):
    """Compute ROC curve. Here candidate_idx_ranked refers to all the candidate 
       streamlines obtained from multiple examples before refinement.
    """ 
    print("Compute the dissimilarity representation of the target tractogram and build the kd-tree.")
    kdt, prototypes = compute_kdtree_and_dr_tractogram(target_tractogram)

    print("Retrieving indeces of the true_tract")
    true_tract_idx = streamlines_idx(true_tract, kdt, prototypes)

    print("Compute y_score.")
    y_score = np.arange(len(candidate_idx_ranked),0,-1)

    print("Compute y_true.")
    diff = np.setdiff1d(true_tract_idx, candidate_idx_ranked)

    if (len(diff) != 0):
	   print("There are %s/%s streamlines of the true tract that aren't in the superset. Making the superset bigger." %(len(diff), len(true_tract_idx)))
	   candidate_idx_ranked = np.concatenate([candidate_idx_ranked, diff])
	   y_score = np.concatenate([y_score, np.zeros(len(diff))])

    y_true = np.zeros(len(candidate_idx_ranked))
    correspondent_idx_true = np.array([np.where(candidate_idx_ranked==true_tract_idx[i]) for i in range(len(true_tract_idx))])
    y_true[correspondent_idx_true] = 1

    print("Compute ROC curve and AUC.")
    fpr, tpr, thresholds = roc_curve(y_true, y_score)
    AUC = auc(fpr, tpr)

    return fpr, tpr, AUC


#def plot_roc_curve(fpr, tpr, AUC, out_fname):
#   	plt.figure()
#   	lw = 1
#   	plt.plot(fpr, tpr, color='darkorange', lw=lw, label='ROC curve (area = %0.2f)' %AUC)
#	plt.plot([0, 1], [0, 1], color='navy', lw=lw, linestyle='--')
#	plt.xlim([0.0, 1.0])
# 	plt.ylim([0.0, 1.05])
#	plt.xlabel('False Positive Rate')
#	plt.ylabel('True Positive Rate')
# 	plt.title('ROC curve %s' %out_fname)
#   	plt.legend(loc="lower right")
#   	plt.savefig(out_fname)
#	plt.show()


if __name__ == '__main__':

	np.random.seed(0) 

	parser = argparse.ArgumentParser()
	parser.add_argument('-candidate_idx', nargs='?', const=1, default='',
	                    help='The candidate tract indeces ranked')
	parser.add_argument('-true_tract', nargs='?',  const=1, default='',
	                    help='The true tract filename')
	parser.add_argument('-static', nargs='?',  const=1, default='',
	                    help='The static tractogram filename')  
	parser.add_argument('-run', nargs='?',  const=1, default='',
	                    help='The configuration run') 
	parser.add_argument('-out', nargs='?',  const=1, default='',
	                    help='The output filename')                               
	args = parser.parse_args()

	with open('config.json') as f:
		data = json.load(f)
		step_size = data["step_size"]

	print("Loading data..")
	candidate_idx_ranked = np.load(args.candidate_idx)
	true_tract = nib.streamlines.load(args.true_tract).streamlines
	print("Resampling with step size = %s mm" %step_size)
	true_tract_res = resample_tractogram(true_tract, step_size)
	true_tract = true_tract_res
	static_tractogram = nib.streamlines.load(args.static).streamlines
	static_tractogram_res = resample_tractogram(static_tractogram, step_size)
	static_tractogram = static_tractogram_res

	fpr, tpr, AUC = compute_roc_curve(candidate_idx_ranked, true_tract, static_tractogram)

	if args.out:
		plot_roc_curve(fpr, tpr, AUC, args.out)
	
	with open('csv/output_FiberStats.csv', 'a') as csvFile:
		writer = csv.writer(csvFile)
		writer.writerow(np.float16(fpr))
		writer.writerow(np.float16(tpr))
		writer.writerow(AUC*np.ones(1, dtype=np.float16))

	sys.exit()
