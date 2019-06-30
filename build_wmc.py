import os
import sys
import json
import argparse
import numpy as np
import nibabel as nib
import scipy.io as sio
from matplotlib import cm
from json import encoder

encoder.FLOAT_REPR = lambda o: format(o, '.2f') 


def build_wmc(tck_file, tractID_list):
    """
    Build the wmc structure.
    """
    print("building wmc structure")
    tractogram = nib.streamlines.load(tck_file)
    tractogram = tractogram.streamlines
    labels = np.zeros((len(tractogram),1))
    os.makedirs('tracts')
    tractsfile = []
    
    with open('tract_name_list.txt') as f:
    	tract_name_list = f.read().splitlines()

    for t, tractID in enumerate(tractID_list):
    	tract_name = tract_name_list[t]
    	idx_fname = 'estimated_bundle_idx_lap_%s.npy' %tract_name		
    	idx_tract = np.load(idx_fname)
    	labels[idx_tract] = tractID

    	#build json file
    	filename = '%s.json' %tractID
    	tract = tractogram[idx_tract]
    	count = len(tract)
    	streamlines = np.zeros([count], dtype=object)
    	for e in range(count):
    		streamlines[e] = np.transpose(tract[e]).round(2)
    	color=list(cm.nipy_spectral(t))[0:3]

    	print("sub-sampling for json")
    	if count < 1000:
    		max = count
    	else:
    		max = 1000
    	jsonfibers = np.reshape(streamlines[:max], [max,1]).tolist()
    	for i in range(max):
    		jsonfibers[i] = [jsonfibers[i][0].tolist()]

    	with open ('tracts/%s' %filename, 'w') as outfile:
    		jsonfile = {'name': tract_name, 'color': color, 'coords': jsonfibers}
    		json.dump(jsonfile, outfile)
    
    	splitname = tract_name.split('_')
    	fullname = splitname[-1].capitalize()+' '+' '.join(splitname[0:-1])  
    	tractsfile.append({"name": fullname, "color": color, "filename": filename})

    print("saving classification.mat")
    sio.savemat('classification.mat', { "classification": {"names": tract_name, "index": labels }})

    with open ('tracts/tracts.json', 'w') as outfile:
    	json.dump(tractsfile, outfile, separators=(',', ': '), indent=4)


if __name__ == '__main__':
    
    parser = argparse.ArgumentParser()
    parser.add_argument('-tractogram', nargs='?', const=1, default='',
                        help='The tractogram file')
    args = parser.parse_args()

    with open('config.json') as f:
    	data = json.load(f)
    	tractID_list = np.array(eval(data["tractID_list"]))
    
    build_wmc(args.tractogram, tractID_list)

    sys.exit()
