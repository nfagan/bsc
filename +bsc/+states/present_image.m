function state = present_image(data)

time_in = data.Value.TIME_IN;

state = ptb.State();
state.Name = 'present_image';

state.Duration = time_in.(state.Name);

state.Entry = @(state) entry(state, data);
state.Loop = @(state) loop(state, data);
state.Exit = @(state) exit(state, data);

end

function entry(state, data)

activate_deactivate_stim_comm( data, 1 ); % activate

state.UserData.is_stim_comm_active = true;

window = data.Value.WINDOW;
task = data.Value.TASK;
structure = data.Value.STRUCTURE;
image = data.Value.CURRENT_TRIAL_DATA.image;

is_debug = structure.is_debug; 

draw( image, window );

if ( is_debug )
  debug_image = data.Value.CURRENT_TRIAL_DATA.debug_image;
  draw( debug_image, window );
end

flip( window );

data.Value.CURRENT_TRIAL_DATA.events.image_onset = elapsed( task ); % task time.

end

function loop(state, data)

stim_params = data.Value.STIM_PARAMS;
stim_comm = data.Value.STIM_COMM;

active_rois = stim_params.active_rois;
deactivate_timeout = stim_params.deactivate_stim_after_image_onset_seconds;
is_stim_comm_active = state.UserData.is_stim_comm_active;
current_time_in_state = elapsed( state );

if ( is_stim_comm_active && current_time_in_state > deactivate_timeout )
  % deactivate after deactivate_timeout *seconds*
  bsc.serial.deactivate_stim( stim_comm, active_rois );
  
  state.UserData.is_stim_comm_active = false;
  
  bsc.task.log( sprintf('Deactivating stim after %0.3f seconds ...' ...
    , current_time_in_state), data, 'stime' );
end

end

function exit(state, data)

activate_deactivate_stim_comm( data, 0 ); % deactivate

states = data.Value.STATES;
next( state, states('inter_image_interval') );

end

function activate_deactivate_stim_comm(data, tf)

stim_params = data.Value.STIM_PARAMS;
stim_comm = data.Value.STIM_COMM;

active_rois = stim_params.active_rois;

[success, msg] = bsc.serial.private.activate_deactive_stim( stim_comm, active_rois, tf );
assert( success, msg );

end