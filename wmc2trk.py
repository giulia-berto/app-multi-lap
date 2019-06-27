import os
import sys
import json
import argparse
import numpy as np
import nibabel as nib
from scipy.io import loadmat


def wmc2trk(trk_file, classification, tractID):
    """
    Convert a single wmc classified tract into a single trk file.
    """
    tractogram = nib.streamlines.load(trk_file)
    aff_vox_to_ras = tractogram.affine
    voxel_sizes = tractogram.header['voxel_sizes']
    dimensions = tractogram.header['dimensions']
    tractogram = tractogram.streamlines
    wmc = loadmat(classification)
    data = wmc["classification"][0][0]
    t_name = data[0][0][tractID][0]
    tract_name = t_name.replace(' ', '_')
    indeces = data[1]
    idx_tract = np.array(np.where(indeces==tractID))[0]
    tract = tractogram[idx_tract]

    with open('tract_name_list.txt', 'w') as filetowrite:
    	filetowrite.write('%s\n' %tract_name)

	#creating empty hader 		
    hdr = nib.streamlines.trk.TrkFile.create_empty_header()
    hdr['voxel_sizes'] = voxel_sizes
    hdr['dimensions'] = dimensions
    hdr['voxel_order'] = 'LAS'
    hdr['voxel_to_rasmm'] = aff_vox_to_ras

    #saving tract
    out_filename = '%s_tract.trk' %tract_name
    t = nib.streamlines.tractogram.Tractogram(tract, affine_to_rasmm=np.eye(4))
    nib.streamlines.save(t, out_filename, header=hdr)
    print("Tract saved in %s" % out_filename)



if __name__ == '__main__':
    
    parser = argparse.ArgumentParser()
    parser.add_argument('-tractogram', nargs='?', const=1, default='',
                        help='The tractogram file')
    parser.add_argument('-classification', nargs='?', const=1, default='',
                        help='The classification.mat file')
    parser.add_argument('-tractID', nargs='?', const=1, default='',
                        help='The tract id')
    args = parser.parse_args()
    
    print("Convert a single wmc classified tract into a single trk file")
    wmc2trk(args.tractogram, args.classification, eval(args.tractID))

    sys.exit()
