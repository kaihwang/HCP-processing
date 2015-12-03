SOURCE='/home/despoB/connectome-raw'
WD='/home/despoB/connectome-data'
SCRIPTS='/home/despoB/kaihwang/bin/HCP-processing'
Tha_folder='/home/despoB/connectome-thalamus/connectome'

for s in 133928; do

	if [ ! -d ${WD}/${s}/ ]; then
		mkdir ${WD}/${s}/		
	fi

	3dcopy ${SOURCE}/${s}/MNINonLinear/aparc+aseg.nii.gz ${WD}/${s}/aseg
	3drefit -view tlrc ${WD}/${s}/aseg+orig

	#whole brain mask
	cp ${Tha_folder}/${s}/MNINonLinear/brainmask_ds.nii.gz ${WD}/${s}/brainmask_ds.nii.gz

	#csf mask
	3dcalc -a ${WD}/${s}/aseg+tlrc -prefix ${WD}/${s}/CSF_mask.nii.gz -expr 'amongst(a,4,43)'
	3dresample -inset ${WD}/${s}/CSF_mask.nii.gz  \
	-master ${WD}/${s}/brainmask_ds.nii.gz \
	-prefix ${WD}/${s}/CSF_mask_ds.nii.gz

	3dmask_tool -input ${WD}/${s}/CSF_mask_ds.nii.gz -dilate_inputs -1 -prefix ${WD}/${s}/CSF_mask_ds_erode1x.nii.gz

	#wm mask
	3dcalc -a ${WD}/${s}/aseg+tlrc -prefix ${WD}/${s}/WM_mask.nii.gz -expr 'amongst(a,2,7,16,41,46,251,252,253,254,255)'
	3dresample -inset ${WD}/${s}/WM_mask.nii.gz  \
	-master ${WD}/${s}/brainmask_ds.nii.gz \
	-prefix ${WD}/${s}/WM_mask_ds.nii.gz

	3dmask_tool -input ${WD}/${s}/WM_mask_ds.nii.gz -dilate_inputs -1 -prefix ${WD}/${s}/WM_mask_ds_erode1x.nii.gz

	for data in rfMRI_REST1_LR rfMRI_REST1_RL rfMRI_REST2_LR rfMRI_REST2_RL; do

		if [ ! -d ${WD}/${s}/${data} ]; then
			mkdir ${WD}/${s}/${data}		
		fi

		if [ ! -e ${WD}/${s}/${data}/${data}_hp2000_clean_wbsreg.nii.gz ]; then
			ln -s ${Tha_folder}/${s}/MNINonLinear/${data}_hp2000_clean_wbsreg.nii.gz ${WD}/${s}/${data}/${data}_hp2000_clean_wbsreg.nii.gz
		fi
	done 

	for data in tfMRI_EMOTION_LR tfMRI_EMOTION_RL tfMRI_GAMBLING_LR tfMRI_GAMBLING_RL tfMRI_LANGUAGE_LR tfMRI_LANGUAGE_RL tfMRI_MOTOR_LR tfMRI_MOTOR_RL tfMRI_RELATIONAL_LR tfMRI_RELATIONAL_RL tfMRI_SOCIAL_LR tfMRI_SOCIAL_RL tfMRI_WM_LR tfMRI_WM_RL; do

		if [ ! -d ${WD}/${s}/${data} ]; then
			mkdir ${WD}/${s}/${data}		
		fi

		if [ ! -e ${WD}/${s}/${data}/${data}.nii.gz ]; then
			ln -s ${SOURCE}/${s}/MNINonLinear/Results/${data}/${data}.nii.gz ${WD}/${s}/${data}/${data}.nii.gz
		fi

		# extract tissue regressors
		3dmaskave -mask ${WD}/${s}/CSF_mask_ds_erode1x.nii.gz -quiet ${WD}/${s}/${data}/${data}.nii.gz > ${WD}/${s}/${data}/${data}_csf.1D
		3dmaskave -mask ${WD}/${s}/WM_mask_ds_erode1x.nii.gz -quiet ${WD}/${s}/${data}/${data}.nii.gz > ${WD}/${s}/${data}/${data}_WM.1D
		3dmaskave -mask ${WD}/${s}/brainmask_ds.nii.gz -quiet ${WD}/${s}/${data}/${data}.nii.gz > ${WD}/${s}/${data}/${data}_WBS.1D

		#creat symlink for motion regressors
		if [ ! -e ${WD}/${s}/${data}/${data}_motion.1D ]; then
			ln -s ${SOURCE}/${s}/MNINonLinear/Results/${data}/Movement_Regressors_dt.txt ${WD}/${s}/${data}/${data}_motion.1D
		fi

		#do regression
		3dTproject \
		-input ${WD}/${s}/${data}/${data}.nii.gz \
		-prefix ${WD}/${s}/${data}/${data}_reg.nii.gz \
		-ort ${WD}/${s}/${data}/${data}_csf.1D \
		-ort ${WD}/${s}/${data}/${data}_WM.1D \
		-ort ${WD}/${s}/${data}/${data}_WBS.1D \
		-ort ${WD}/${s}/${data}/${data}_motion.1D \
		-automask \
		-passband 0.009 0.08 \
		-blur 6 \
		-polort 2

	done  

done