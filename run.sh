#!/bin/bash

echo "copying moving and static tractograms"
subjID=`jq -r '._inputs[0].meta.subject' config.json`
static=`jq -r '.tractogram_static' config.json`
t1_static=`jq -r '.t1_static' config.json`
segmentations=`jq -r '.segmentations' config.json`
movings=`jq -r '.tractograms_moving' config.json`
t1s=`jq -r '.t1s_moving' config.json`
true_segmentation=`jq -r '.true_segmentation' config.json`

# Building arrays
arr_seg=()
arr_seg+=(${segmentations})
arr_mov=()
arr_mov+=(${movings})
arr_t1s=()
arr_t1s+=(${t1s})

echo "Check the inputs subject id"
num_ex=$((${#arr_seg[@]} - 2))
if [ ! $subjID == `jq -r '._inputs[1].meta.subject' config.json` ]; then
echo "Inputs subject id incorrectly inserted. Check them again."
	exit 1
fi
for i in `seq 1 $num_ex`; 
do 
	id_seg=$(jq -r "._inputs[1+$i].meta.subject" config.json | tr -d "_")
	id_mov=$(jq -r "._inputs[1+$i+$num_ex].meta.subject" config.json | tr -d "_")
	id_t1=$(jq -r "._inputs[1+$i+$num_ex+$num_ex].meta.subject" config.json | tr -d "_")	
	if [ $id_seg == $id_mov -a $id_seg == $id_t1 ]; then
	echo "Inputs subject id correctly inserted"
else
	echo "Inputs subject id incorrectly inserted. Check them again."
	exit 1
fi
done
id_fs=$(jq -r "._inputs[2+$num_ex+$num_ex+$num_ex].meta.subject" config.json | tr -d "_")
if [ ! $subjID == $id_fs ]; then
echo "Inputs subject id incorrectly inserted. Check them again."
	exit 1
fi

echo "Building LAP environment"
if [ -f "linear_assignment.c" ];then
	echo "LAP already built. Skipping"
else
	cython linear_assignment.pyx;
	python setup_lapjv.py build_ext --inplace;

	ret=$?
	if [ ! $ret -eq 0 ]; then
		echo "LAP environment build failed"
		echo $ret > finished
		exit $ret
	fi
fi


run=multi-LAP	



echo "Computing ROC curve for multi-LAP"
mkdir csv;
while read tract_name; do
	echo "Tract name: $tract_name"; 
	candidate_idx_lap=candidate_bundle_idx_lap.npy
	min_cost_lap=min_cost_values_lap.npy
	output_filename=${subjID}_${tract_name}_ROC_${run}.png
	python plot_roc_curve.py -candidate_idx $candidate_idx_lap -cost $min_cost_lap -true_tract $tract_name'_tract.trk' -static $subjID'_track.trk';

done < tract_name_list.txt


echo "Running multi-NN"
mkdir tracts_tck_nn;
run=multi-NN	



echo "Computing ROC curve for multi-NN"
while read tract_name; do
	echo "Tract name: $tract_name"; 
	candidate_idx_nn=candidate_bundle_idx_nn.npy
	min_cost_nn=min_cost_values_nn.npy
	output_filename=${subjID}_${tract_name}_ROC_${run}.png
	python plot_roc_curve.py -candidate_idx $candidate_idx_nn -cost $min_cost_nn -true_tract $tract_name'_tract.trk' -static $subjID'_track.trk';

done < tract_name_list.txt




echo "Complete"
