function destruct(data)

%   DESTRUCT -- Function called after the task exits, when the data object
%     is being deleted.
%
%     This function is called regardless of whether the task successfully
%     completes, so long as the `data` object has been created.
%
%     See also bsc.task.setup

warn_on_error( @() handle_tracker_close(data) );
warn_on_error( @() handle_serial_close(data) );
warn_on_error( @() handle_data_saving(data) );

end

function warn_on_error(func)

try
  func();
catch err
  warning( err.message );
end

end

function handle_tracker_close(data)

shutdown( data.Value.TRACKER );

end

function handle_serial_close(data)

sync_comm = data.Value.SYNC_COMM;
stim_comm = data.Value.STIM_COMM;

if ( ~isempty(sync_comm) && isvalid(sync_comm) )
  try
    close( sync_comm )
  catch err
    warning( err.message );
  end
end

if ( ~isempty(stim_comm) && isvalid(stim_comm) )
  try
    % Different close function -- stim_comm is a Matlab serial object,
    % whereas sync_comm is a serial_comm.SerialManagerPaired object.
    fclose( stim_comm );
  catch err
    warning( err.message );
  end
end

end

function handle_data_saving(data)

if ( ~data.Value.is_setup_complete )
  return
end

data_folder = data.Value.data_folder;
edf_filename = data.Value.edf_filename;
mat_filepath = get_mat_filepath( data_folder );

if ( data.Value.INTERFACE.save_data )
  shared_utils.io.require_dir( data_folder );
  save_data( data, mat_filepath, edf_filename );
end

end

function save_data(data, mat_filepath, edf_filename)

import shared_utils.struct.field_or;

% Match structure of brains.task.dot_stim
to_save = struct();
ref_data = data.Value;

sync =        field_or( ref_data, 'SYNC', struct() );
far_plane =   field_or( ref_data, 'FAR_PLANE', struct() );
stim_params = field_or( ref_data, 'STIM_PARAMS', struct() );
conf =        field_or( ref_data, 'config', struct() );
brains_conf = field_or( ref_data, 'brains_config', struct() );
trial_data =  field_or( ref_data, 'TRIAL_DATA', struct() );

% Switch config to match format of brains.task.dot_stim, etc.
to_save.config =              brains_conf;
to_save.bsc_config =          conf;

to_save.sync_times =          field_or( sync, 'sync_times', [] );
to_save.plex_sync_times =     field_or( sync, 'plex_sync_times', [] );
to_save.plex_sync_index =     field_or( sync, 'plex_sync_index', nan );

to_save.rois =                  field_or( far_plane, 'bounds', struct() );
to_save.far_plane_calibration = field_or( far_plane, 'key_file', struct() );
to_save.far_plane_key_map =     field_or( far_plane, 'key_map', struct() );
to_save.far_plane_padding =     field_or( far_plane, 'padding', struct() );
to_save.far_plane_constants =   field_or( far_plane, 'constants', struct() );

to_save.stimulation_params =  stim_params;
to_save.edf_file =            edf_filename;
to_save.date =                datestr( now );
to_save.task_type =           'image_control';
to_save.trial_data =          trial_data;

save( mat_filepath, 'to_save' );

end

function mat_filepath = get_mat_filepath(save_p)

prefix = 'image_control_';

mat_filename = shared_utils.io.get_next_numbered_filename( save_p, '.mat', prefix );
mat_filepath = fullfile( save_p, mat_filename );

end