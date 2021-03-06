SOURCE='/home/despoB/connectome-raw'
WD='/home/despoB/connectome-data'
SCRIPTS='/home/despoB/kaihwang/bin/HCP-processing'
Tha_folder='/home/despoB/connectome-thalamus/connectome'

for s in 351938 116120 126931 131621 129432 143527 179548 129533 197449 113821 207628 142424 145531 355542 173132 112819 121315 101410 169141 208428 170934 128329 650746 611231 745555 782157 521331 197651 165234 150524 355239 473952 155231 571548 644044 107220 116221 121820 129937 150019 159845 160931 168038 173233 177342 179952 190132 193441 200210 201717 221218 492754 584355 613235 693461 734247 766563 810439 856463 972566 953764; do

	if [ ! -d ${WD}/${s}/ ]; then
		mkdir ${WD}/${s}/		
	fi

	if [ ! -e ${WD}/${s}/aseg+tlrc.BRIK ]; then
		3dcopy ${SOURCE}/${s}/MNINonLinear/aparc+aseg.nii.gz ${WD}/${s}/aseg
		3drefit -view tlrc ${WD}/${s}/aseg+orig
	fi

	#whole brain mask
	if [ ! -e ${WD}/${s}/brainmask_ds.nii.gz ]; then
		#cp ${Tha_folder}/${s}/MNINonLinear/brainmask_ds.nii.gz ${WD}/${s}/brainmask_ds.nii.gz
		cp ${SOURCE}/${s}/MNINonLinear/brainmask_fs.nii.gz ${WD}/${s}/brainmask_fs.nii.gz

		3dresample -inset ${WD}/${s}/brainmask_fs.nii.gz \
		-master ${SOURCE}/${s}/MNINonLinear/Results/rfMRI_REST1_LR/rfMRI_REST1_LR_hp2000_clean.nii.gz \
		-prefix ${WD}/${s}/brainmask_ds.nii.gz
	fi


	#csf mask
	if [ ! -e ${WD}/${s}/CSF_mask_ds_erode1x.nii.gz ]; then
		3dcalc -a ${WD}/${s}/aseg+tlrc -prefix ${WD}/${s}/CSF_mask.nii.gz -expr 'amongst(a,4,43)'
		3dresample -inset ${WD}/${s}/CSF_mask.nii.gz  \
		-master ${WD}/${s}/brainmask_ds.nii.gz \
		-prefix ${WD}/${s}/CSF_mask_ds.nii.gz

		3dmask_tool -input ${WD}/${s}/CSF_mask_ds.nii.gz -dilate_inputs -1 -prefix ${WD}/${s}/CSF_mask_ds_erode1x.nii.gz
	fi

	#wm mask
	if [ ! -e ${WD}/${s}/WM_mask_ds_erode1x.nii.gz ]; then
		3dcalc -a ${WD}/${s}/aseg+tlrc -prefix ${WD}/${s}/WM_mask.nii.gz -expr 'amongst(a,2,7,16,41,46,251,252,253,254,255)'
		3dresample -inset ${WD}/${s}/WM_mask.nii.gz  \
		-master ${WD}/${s}/brainmask_ds.nii.gz \
		-prefix ${WD}/${s}/WM_mask_ds.nii.gz

		3dmask_tool -input ${WD}/${s}/WM_mask_ds.nii.gz -dilate_inputs -1 -prefix ${WD}/${s}/WM_mask_ds_erode1x.nii.gz
	fi




	## do task data
	for data in tfMRI_EMOTION_LR tfMRI_EMOTION_RL tfMRI_GAMBLING_LR tfMRI_GAMBLING_RL tfMRI_LANGUAGE_LR tfMRI_LANGUAGE_RL tfMRI_MOTOR_LR tfMRI_MOTOR_RL tfMRI_RELATIONAL_LR tfMRI_RELATIONAL_RL tfMRI_SOCIAL_LR tfMRI_SOCIAL_RL tfMRI_WM_LR tfMRI_WM_RL; do
	
		if [ ! -d ${WD}/${s}/${data} ]; then
			mkdir ${WD}/${s}/${data}		
		fi
	
		if [ ! -e ${WD}/${s}/${data}/${data}.nii.gz ]; then
			ln -s ${SOURCE}/${s}/MNINonLinear/Results/${data}/${data}.nii.gz ${WD}/${s}/${data}/${data}.nii.gz
		fi
		
		if [ ! -e ${WD}/${s}/${data}/${data}_reg.nii.gz ]; then

			rm ${WD}/${s}/${data}/${data}_reg.nii.gz
			# extract tissue regressors
			3dmaskave -mask ${WD}/${s}/CSF_mask_ds_erode1x.nii.gz -quiet ${WD}/${s}/${data}/${data}.nii.gz > ${WD}/${s}/${data}/${data}_csf.1D
			3dmaskave -mask ${WD}/${s}/WM_mask_ds_erode1x.nii.gz -quiet ${WD}/${s}/${data}/${data}.nii.gz > ${WD}/${s}/${data}/${data}_WM.1D
			3dmaskave -mask ${WD}/${s}/brainmask_ds.nii.gz -quiet ${WD}/${s}/${data}/${data}.nii.gz > ${WD}/${s}/${data}/${data}_WBS.1D	
			rm ${WD}/${s}/${data}/${data}_motion.1D
			ln -s ${SOURCE}/${s}/MNINonLinear/Results/${data}/Movement_Regressors_dt.txt ${WD}/${s}/${data}/${data}_motion.1D
	
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
		fi
	
	done  

		## do rfMRI
	for data in rfMRI_REST1_LR rfMRI_REST1_RL rfMRI_REST2_LR rfMRI_REST2_RL; do

		if [ ! -d ${WD}/${s}/${data} ]; then
			mkdir ${WD}/${s}/${data}		
		fi

		if [ ! -e ${WD}/${s}/${data}/${data}_hp2000_clean.nii.gz ]; then
			rm ${WD}/${s}/${data}/${data}_hp2000_clean.nii.gz
			ln -s ${SOURCE}/${s}/MNINonLinear/Results/${data}/${data}_hp2000_clean.nii.gz ${WD}/${s}/${data}/${data}_hp2000_clean.nii.gz
		fi

		if [ ! -e ${WD}/${s}/${data}/${data}_hp2000_clean_wbsreg.nii.gz ]; then
			
			rm ${WD}/${s}/${data}/${data}_hp2000_clean_wbsreg.nii.gz
			3dmaskave -mask ${WD}/${s}/brainmask_ds.nii.gz -quiet \
			${WD}/${s}/${data}/${data}_hp2000_clean.nii.gz > ${WD}/${s}/${data}_WBS.1D
			
			3dTproject -input ${WD}/${s}/${data}/${data}_hp2000_clean.nii.gz \
			-prefix ${WD}/${s}/${data}/${data}_hp2000_clean_wbsreg.nii.gz \
			-ort ${WD}/${s}/${data}_WBS.1D \
			-passband 0.009 0.08 \
			-automask
		fi
	done 

done