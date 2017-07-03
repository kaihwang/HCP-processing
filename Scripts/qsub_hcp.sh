SCRIPT='/home/despoB/kaihwang/bin/HCP-processing/Scripts'
DATA='/home/despoB/kaihwang/bin/HCP-processing/Data'

cd /home/despoB/connectome-data
for s in $(cat ${DATA}/unrelated.csv); do #(/bin/ls -d *)


	#if [ ! -e "/home/despoB/kaihwang/Rest/Graph/gsetCI_${Subject}.mat" ]; then
	sed "s/s in 100307/s in ${s}/g" < ${SCRIPT}/HCP_preproc_forMac.sh > ~/tmp/HCP${s}.sh
	qsub -l mem_free=11G -V -M kaihwang -m e -e ~/tmp -o ~/tmp ~/tmp/HCP${s}.sh
	#fi

done

