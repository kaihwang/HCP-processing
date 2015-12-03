SCRIPT='/home/despoB/kaihwang/bin/HCP-processing/Scripts'
DATA='/home/despoB/kaihwang/bin/HCP-processing/Data'

for s in $(cat $DATA/List_of_100_least_movement_subjects); do
	#if [ ! -e "/home/despoB/kaihwang/Rest/Graph/gsetCI_${Subject}.mat" ]; then
	sed "s/s in 133928/s in ${s}/g" < ${SCRIPT}/HCP_preproc.sh > ~/tmp/s${s}.sh
	qsub -V -M kaihwang -m e -e ~/tmp -o ~/tmp ~/tmp/s${s}.sh
	#fi

done

