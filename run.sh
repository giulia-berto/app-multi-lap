#!/bin/bash

echo "copying moving and static tractograms"
subjID=`jq -r '._inputs[0].meta.subject' config.json`
static=`jq -r '.tractogram_static' config.json`
t1_static=`jq -r '.t1_static' config.json`
segmentations=`jq -r '.segmentations' config.json`
movings=`jq -r '.tractograms_moving' config.json`
t1s=`jq -r '.t1s_moving' config.json`
tractID=`jq -r '.tract' config.json`
slr=`jq -r '.slr' config.json`
 
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

if [[ $slr == True ]];then
	echo "SLR registration"
	for i in `seq 1 $num_ex`; 
	do
		id_mov=$(jq -r "._inputs[1+$i+$num_ex].meta.subject" config.json | tr -d "_")
		tractogram_moving=tractograms_directory/$id_mov'_track.trk'
		python tractograms_slr.py -moving $tractogram_moving -static $subjID'_track.trk'
	done
else
	echo "Assuming subjects already co-registered in the same space."
fi

echo "Create examples directory"
if [[ $static == *.trk ]];then
	echo "Tracts already in .trk format"
	tract_name=$(jq -r "._inputs[2+$num_ex].tags[0]" config.json | tr -d "_")
	echo $tract_name > tract_name_list.txt
	mkdir examples_directory_$tract_name;
	for i in `seq 1 $num_ex`; 
	do
		id_mov=$(jq -r "._inputs[1+$i+$num_ex].meta.subject" config.json | tr -d "_")
		cp ${arr_seg[i]//[,\"]} examples_directory_$tract_name/$id_mov'_'$tract_name'_tract.trk';
	done
else
	echo "Tracts conversion to trk"
	for i in `seq 1 $num_ex`; 
	do
		t1_moving=${arr_t1s[i]//[,\"]}
		id_mov=$(jq -r "._inputs[1+$i+$num_ex].meta.subject" config.json | tr -d "_")
		tractogram_moving=tractograms_directory/$id_mov'_track.trk'		
		seg_file=${arr_seg[i]//[,\"]}
		python wmc2trk.py -tractogram $tractogram_moving -classification $seg_file -tractID $tractID
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

echo "Building the wmc structure"
python build_wmc.py -tractogram $static -tract_idx 'estimated_bundle_idx_lap.npy' -tractID $tractID
if [ -f 'classification.mat' ]; then 
    echo "WMC structure created."
else 
	echo "WMC structure missing."
	exit 1
fi

echo "Complete"
