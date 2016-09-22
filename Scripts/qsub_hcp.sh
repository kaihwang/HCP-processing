SCRIPT='/home/despoB/kaihwang/bin/HCP-processing/Scripts'
DATA='/home/despoB/kaihwang/bin/HCP-processing/Data'

cd /home/despoB/connectome-raw
for s in $(/bin/ls -d * | grep "[0-9]"); do
	#if [ ! -e "/home/despoB/kaihwang/Rest/Graph/gsetCI_${Subject}.mat" ]; then
	sed "s/s in 996782/s in ${s}/g" < ${SCRIPT}/HCP_preproc.sh > ~/tmp/t${s}.sh
	qsub -l mem_free=5G -V -M kaihwang -m e -e ~/tmp -o ~/tmp ~/tmp/t${s}.sh
	#fi

done

