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

echo "Tractogram conversion to trk"
mkdir tractograms_directory;
if [[ $static == *.tck ]];then
	echo "Input in tck format. Convert it to trk."
	cp $static ./tractogram_static.tck;
	python tck2trk.py $t1_static tractogram_static.tck -f;
	cp tractogram_static.trk $subjID'_track.trk';
	for i in `seq 1 $num_ex`; 
	do 
		t1_moving=${arr_t1s[i]//[,\"]}
		id_mov=$(jq -r "._inputs[1+$i+$num_ex].meta.subject" config.json | tr -d "_")
		cp ${arr_mov[i]//[,\"]} ./${id_mov}_tractogram_moving.tck;
		python tck2trk.py $t1_moving ${id_mov}_tractogram_moving.tck -f;
		cp ${id_mov}_tractogram_moving.trk tractograms_directory/$id_mov'_track.trk';
	done
else
	echo "Tractogram already in .trk format"
	cp $static $subjID'_track.trk';
	for i in `seq 1 $num_ex`; 
	do 
		id_mov=$(jq -r "._inputs[1+$i+$num_ex].meta.subject" config.json | tr -d "_")
		cp ${arr_mov[i]//[,\"]} tractograms_directory/$id_mov'_track.trk';
	done
fi

if [ -z "$(ls -A -- "tractograms_directory")" ]; then    
	echo "tractograms_directory is empty."; 
	exit 1;
else    
	echo "tractograms_directory created."; 
fi

echo "SLR registration"
for i in `seq 1 $num_ex`; 
do
	id_mov=$(jq -r "._inputs[1+$i+$num_ex].meta.subject" config.json | tr -d "_")
	tractogram_moving=tractograms_directory/$id_mov'_track.trk'
	python tractograms_slr.py -moving $tractogram_moving -static $subjID'_track.trk'
done

echo "Tracts conversion to trk"
if [[ $true_segmentation == *.trk ]];then
	echo "Tracts already in .trk format"
	tract_name=$(jq -r "._inputs[2+$num_ex+$num_ex+$num_ex].datatype_tags[1]" config.json | tr -d "_")
	echo $tract_name > tract_name_list.txt
	cp $true_segmentation ${tract_name}_tract.trk
	mkdir examples_directory_$tract_name;
	for i in `seq 1 $num_ex`; 
	do
		id_mov=$(jq -r "._inputs[1+$i+$num_ex].meta.subject" config.json | tr -d "_")
		cp ${arr_mov[i]//[,\"]} examples_directory_$tract_name/$id_mov'_'$tract_name'_tract.trk';
	done
else
	for i in `seq 1 $num_ex`; 
	do
		t1_moving=${arr_t1s[i]//[,\"]}
		id_mov=$(jq -r "._inputs[1+$i+$num_ex].meta.subject" config.json | tr -d "_")		
		matlab -nosplash -nodisplay -r "afqConverterMulti(${arr_seg[i]//,}, ${arr_t1s[i]//,})";
		while read tract_name; do
			echo "Tract name: $tract_name";
			if [ ! -d "examples_directory_$tract_name" ]; then
	  			mkdir examples_directory_$tract_name;
			fi
			mv $tract_name'_tract.trk' examples_directory_$tract_name/$id_mov'_'$tract_name'_tract.trk';

			if [ -z "$(ls -A -- "examples_directory_$tract_name")" ]; then    
				echo "examples_directory is empty."; 
				exit 1;
			else    
				echo "examples_directory created."; 
			fi	
		done < tract_name_list.txt
	done
	echo "AFQ conversion of ground truth to trk"
	matlab -nosplash -nodisplay -r "afqConverter1()";
fi

echo "Running multi-LAP"
mkdir tracts_tck;
run=multi-LAP	

while read tract_name; do
	echo "Tract name: $tract_name"; 
	base_name=$tract_name'_tract'
	output_filename=tracts_tck/${subjID}_${base_name}_${run}.tck
	python lap_multiple_examples.py -moving_dir tractograms_directory -static $subjID'_track.trk' -ex_dir examples_directory_$tract_name -out $output_filename;

done < tract_name_list.txt

if [ -z "$(ls -A -- "tracts_tck")" ]; then    
	echo "multi-LAP failed."
	exit 1
else    
	echo "multi-LAP done."
fi

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

while read tract_name; do
	echo "Tract name: $tract_name"; 
	base_name=$tract_name'_tract'
	output_filename=tracts_tck_nn/${subjID}_${base_name}_${run}.tck
	python nn_multiple_examples.py -moving_dir tractograms_directory -static $subjID'_track.trk' -ex_dir examples_directory_$tract_name -out $output_filename;

done < tract_name_list.txt

if [ -z "$(ls -A -- "tracts_tck_nn")" ]; then    
	echo "multi-NN failed."
	exit 1
else    
	echo "multi-NN done."
fi

echo "Computing ROC curve for multi-NN"
while read tract_name; do
	echo "Tract name: $tract_name"; 
	candidate_idx_nn=candidate_bundle_idx_nn.npy
	min_cost_nn=min_cost_values_nn.npy
	output_filename=${subjID}_${tract_name}_ROC_${run}.png
	python plot_roc_curve.py -candidate_idx $candidate_idx_nn -cost $min_cost_nn -true_tract $tract_name'_tract.trk' -static $subjID'_track.trk';

done < tract_name_list.txt


echo "Build partial tractogram"
run=multi-LAP
output_filename=${subjID}'_var-partial_tract_'${run}'.tck';
python build_partial_tractogram.py -tracts_tck_dir 'tracts_tck' -out ${output_filename};
if [ -f ${output_filename} ]; then 
    echo "Partial tractogram built."
else 
	echo "Partial tractogram missing."
	exit 1
fi

echo "Build a wmc structure"
stat_sub=\'$subjID\'
tag=\'$run\'
matlab -nosplash -nodisplay -r "build_wmc_structure($stat_sub, $tag)";
if [ -f 'output.mat' ]; then 
    echo "WMC structure created."
else 
	echo "WMC structure missing."
	exit 1
fi

est_tck=$(ls tracts_tck)
python tck2trk.py $t1_static $est_tck -f;
mv tracts_tck/*.trk track.trk

echo "Complete"
