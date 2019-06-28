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


def build_wmc(trk_file, tract_idx, tractID):
    """
    Build the wmc structure.
    """
    print("building wmc structure")
    tractogram = nib.streamlines.load(trk_file)
    tractogram = tractogram.streamlines
    
    idx_tract = np.load(tract_idx)
    labels = np.zeros((len(tractogram),1))
    labels[idx_tract] = tractID
    	
    with open('tract_name_list.txt') as f:
    	tract_name = f.read().splitlines()

    print("saving classification.mat")
    sio.savemat('classification.mat', { "classification": {"names": tract_name, "index": labels }})

    #build json file
    filename = '1.json'
    tract = tractogram[idx_tract]
    count = len(tract)
    streamlines = np.zeros([count], dtype=object)
    for e in range(count):
    	streamlines[e] = np.transpose(tract[e]).round(2)
    color=list(cm.nipy_spectral(len(tract_name)+10))[0:3]

    print("sub-sampling for json")
    if count < 1000:
        max = count
    else:
    	max = 1000
    jsonfibers = np.reshape(streamlines[:max], [max,1]).tolist()
    for i in range(max):
        jsonfibers[i] = [jsonfibers[i][0].tolist()]

    os.makedirs('tracts')
    with open ('tracts/1.json', 'w') as outfile:
        jsonfile = {'name': tract_name, 'color': color, 'coords': jsonfibers}
        json.dump(jsonfile, outfile)

    tractsfile = []
    splitname = tract_name[0].split('_')
    fullname = splitname[-1].capitalize()+' '+' '.join(splitname[0:-1])  
    tractsfile.append({"name": fullname, "color": color, "filename": filename})

    with open ('tracts/tracts.json', 'w') as outfile:
    	json.dump(tractsfile, outfile, separators=(',', ': '), indent=4)



if __name__ == '__main__':
    
    parser = argparse.ArgumentParser()
    parser.add_argument('-tractogram', nargs='?', const=1, default='',
                        help='The tractogram file')
    parser.add_argument('-tract_idx', nargs='?', const=1, default='',
                        help='The estimated tracts .tck folder')
    parser.add_argument('-tractID', nargs='?', const=1, default='',
                        help='The tract id')
    args = parser.parse_args()
    
    build_wmc(args.tractogram, args.tract_idx, eval(args.tractID))

    sys.exit()
