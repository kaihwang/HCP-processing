#do preprocessing for Mac

SOURCE='/home/despoB/connectome-raw'
WD='/home/despoB/connectome-data'
SCRIPTS='/home/despoB/kaihwang/bin/HCP-processing'
Tha_folder='/home/despoB/connectome-thalamus/connectome'


for s in 100307; do

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
	for data in tfMRI_MOTOR_LR tfMRI_MOTOR_RL tfMRI_WM_LR tfMRI_WM_RL tfMRI_EMOTION_LR tfMRI_EMOTION_RL tfMRI_GAMBLING_LR tfMRI_GAMBLING_RL tfMRI_LANGUAGE_LR tfMRI_LANGUAGE_RL tfMRI_MOTOR_LR tfMRI_MOTOR_RL tfMRI_RELATIONAL_LR tfMRI_RELATIONAL_RL tfMRI_SOCIAL_LR tfMRI_SOCIAL_RL; do
	
		if [ ! -d ${WD}/${s}/${data} ]; then
			mkdir ${WD}/${s}/${data}		
		fi
	
		if [ ! -e ${WD}/${s}/${data}/${data}.nii.gz ]; then
			rm ${WD}/${s}/${data}/${data}.nii.g
			ln -s ${SOURCE}/${s}/MNINonLinear/Results/${data}/${data}.nii.gz ${WD}/${s}/${data}/${data}.nii.gz
		fi
		
		if [ ! -e ${WD}/${s}/${data}/${data}_MACreg.nii.gz ]; then

			# extract tissue regressors using 3dpc (compcor)
			#3dmaskave -mask ${WD}/${s}/CSF_mask_ds_erode1x.nii.gz -quiet ${WD}/${s}/${data}/${data}.nii.gz > ${WD}/${s}/${data}/${data}_csf.1D
			#3dmaskave -mask ${WD}/${s}/WM_mask_ds_erode1x.nii.gz -quiet ${WD}/${s}/${data}/${data}.nii.gz > ${WD}/${s}/${data}/${data}_WM.1D
			#3dmaskave -mask ${WD}/${s}/brainmask_ds.nii.gz -quiet ${WD}/${s}/${data}/${data}.nii.gz > ${WD}/${s}/${data}/${data}_WBS.1D
			if [ ! -e ${WD}/${s}/${data}/CSF_PC_vec.1D  ]; then	
				3dpc -vmean -mask ${WD}/${s}/CSF_mask_ds_erode1x.nii.gz -pcsave 5 -prefix ${WD}/${s}/${data}/CSF_PC ${WD}/${s}/${data}/${data}.nii.gz
			fi

			if [ ! -e ${WD}/${s}/${data}/WM_PC_vec.1D ]; then
				3dpc -vmean -mask ${WD}/${s}/WM_mask_ds_erode1x.nii.gz -pcsave 5 -prefix ${WD}/${s}/${data}/WM_PC ${WD}/${s}/${data}/${data}.nii.gz
			fi	

			rm ${WD}/${s}/${data}/${data}_motion.1D
			ln -s ${SOURCE}/${s}/MNINonLinear/Results/${data}/Movement_Regressors_dt.txt ${WD}/${s}/${data}/${data}_motion.1D
			
			#do surrond tissue
			3dpc -vmean -mask /home/despoB/kaihwang/Rest/ROIs/Thalamus_surround_cortical_mask.nii.gz -pcsave 3 \
			-prefix ${WD}/${s}/${data}/ST_PC ${WD}/${s}/${data}/${data}.nii.gz
			
			#do regression
			#rm ${WD}/${s}/${data}/${data}_MACreg.nii.gz
			## did mac do filter for task?
			3dTproject \
			-input ${WD}/${s}/${data}/${data}.nii.gz \
			-prefix ${WD}/${s}/${data}/${data}_MACreg.nii.gz \
			-ort ${WD}/${s}/${data}/CSF_PC_vec.1D \
			-ort ${WD}/${s}/${data}/WM_PC_vec.1D \
			-ort ${WD}/${s}/${data}/${data}_motion.1D \
			-ort ${WD}/${s}/${data}/ST_PC_vec.1D \
			-automask 
			#-passband 0.009 0.08

		fi
		
		#Thalamus_Morel_consolidated_mask_v3 Morel_plus_Yeo400 bnm_lc
		for roi in Thalamus_Morel_consolidated_mask_v3 Pu Ca NAC GPi GPe; do   #Morel_plus_Yeo400
			
			3dROIstats -nobriklab -mask_f2short -mask /home/despoB/kaihwang/Rest/ROIs/${roi}.nii.gz ${WD}/${s}/${data}/${data}_MACreg.nii.gz > /home/despoB/kaihwang/Rest/ThaGate/forMac/${s}_${roi}_${data}
			#3dNetCorr \
			#-inset ${WD}/${s}/${data}/${data}_MACreg.nii.gz \
			#-in_rois /home/despoB/kaihwang/Rest/ROIs/${roi}.nii.gz \
			#-ts_out \
			#-prefix /home/despoB/kaihwang/Rest/ThaGate/NotBackedUp/${s}_${roi}_${data}
			# need to change path here, ts output
		done
		
		rm ${WD}/${s}/${data}/${data}_MACreg.nii.gz

	
	done  

	## do rfMRI
	for data in rfMRI_REST1_LR rfMRI_REST1_RL rfMRI_REST2_LR rfMRI_REST2_RL; do

		if [ ! -d ${WD}/${s}/${data} ]; then
			mkdir ${WD}/${s}/${data}		
		fi

		if [ ! -e ${WD}/${s}/${data}/${data}.nii.gz ]; then
			rm ${WD}/${s}/${data}/${data}_hp2000_clean.nii.gz
			ln -s ${SOURCE}/${s}/MNINonLinear/Results/${data}/${data}_hp2000_clean.nii.gz ${WD}/${s}/${data}/${data}_hp2000_clean.nii.gz
			rm ${WD}/${s}/${data}/${data}.nii.gz
			ln -s ${SOURCE}/${s}/MNINonLinear/Results/${data}/${data}.nii.gz ${WD}/${s}/${data}/${data}.nii.gz
		fi

		if [ ! -e ${WD}/${s}/${data}/${data}_MACreg.nii.gz ]; then
			
			
			rm ${WD}/${s}/${data}/${data}_motion.1D
			ln -s ${SOURCE}/${s}/MNINonLinear/Results/${data}/Movement_Regressors_dt.txt ${WD}/${s}/${data}/${data}_motion.1D

			if [ ! -e ${WD}/${s}/${data}/CSF_PC_vec.1D ]; then
				3dpc -vmean -mask ${WD}/${s}/CSF_mask_ds_erode1x.nii.gz -pcsave 5 -prefix ${WD}/${s}/${data}/CSF_PC ${WD}/${s}/${data}/${data}.nii.gz
			fi

			if [ ! -e ${WD}/${s}/${data}/WM_PC_vec.1D ]; then
				3dpc -vmean -mask ${WD}/${s}/WM_mask_ds_erode1x.nii.gz -pcsave 5 -prefix ${WD}/${s}/${data}/WM_PC ${WD}/${s}/${data}/${data}.nii.gz
			fi
			
			3dpc -vmean -mask /home/despoB/kaihwang/Rest/ROIs/Thalamus_surround_cortical_mask.nii.gz -pcsave 3 \
			-prefix ${WD}/${s}/${data}/ST_PC ${WD}/${s}/${data}/${data}.nii.gz

			3dTproject \
			-input ${WD}/${s}/${data}/${data}.nii.gz \
			-prefix ${WD}/${s}/${data}/${data}_MACreg.nii.gz \
			-ort ${WD}/${s}/${data}/CSF_PC_vec.1D \
			-ort ${WD}/${s}/${data}/WM_PC_vec.1D \
			-ort ${WD}/${s}/${data}/${data}_motion.1D \
			-ort ${WD}/${s}/${data}/ST_PC_vec.1D \
			-passband 0.009 0.08 \
			-automask

		fi
		
		#Thalamus_Morel_consolidated_mask_v3 bnm_lc
		for roi in Thalamus_Morel_consolidated_mask_v3 Pu Ca NAC GPi GPe; do 
			
			3dROIstats -nobriklab -mask_f2short -mask /home/despoB/kaihwang/Rest/ROIs/${roi}.nii.gz ${WD}/${s}/${data}/${data}_MACreg.nii.gz > /home/despoB/kaihwang/Rest/ThaGate/forMac/${s}_${roi}_${data}
			# 3dNetCorr \
			# -inset ${WD}/${s}/${data}/${data}_MACreg.nii.gz \
			# -in_rois /home/despoB/kaihwang/Rest/ROIs/${roi}.nii.gz \
			# -ts_out \
			# -prefix /home/despoB/kaihwang/Rest/ThaGate/NotBackedUp/${s}_${roi}_${data}
		done	
		
		rm ${WD}/${s}/${data}/${data}_MACreg.nii.gz
	
	done 

done