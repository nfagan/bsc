function stim_params = reconcile_stim_params(stim_params)

stim_params.protocol = bsc.serial.util.stim_protocol_name_to_id( stim_params.protocol_name );
stim_params.active_rois = bsc.serial.util.check_active_roi_names( stim_params.active_rois );

end