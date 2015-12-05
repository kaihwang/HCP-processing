SCRIPT='/home/despoB/kaihwang/bin/HCP-processing/Scripts'
DATA='/home/despoB/kaihwang/bin/HCP-processing/Data'

for s in $(cat $DATA/list_of_complete_subjects); do
	#if [ ! -e "/home/despoB/kaihwang/Rest/Graph/gsetCI_${Subject}.mat" ]; then
	sed "s/s in 100408/s in ${s}/g" < ${SCRIPT}/HCP_preproc.sh > ~/tmp/s${s}.sh
	qsub -l mem_free=5G -V -M kaihwang -m e -e ~/tmp -o ~/tmp ~/tmp/s${s}.sh
	#fi

done

