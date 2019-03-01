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

stim_rect = handle_stim_comm( data, state );

window = data.Value.WINDOW;
structure = data.Value.STRUCTURE;
trial_data = data.Value.CURRENT_TRIAL_DATA;
image = trial_data.image;

is_debug = structure.is_debug; 

draw( image, window );

if ( is_debug )
  debug_image = trial_data.debug_image;
  draw( debug_image, window );
  
  bsc.task.log( sprintf('Image: "%s"', trial_data.image_identifier), data, 'param' );
end

conditional_draw_eyelink_stim_rect( data, stim_rect );

flip( window );

bsc.task.mark_event( data, 'image_onset' );

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
    , current_time_in_state), data, 'event' );
end

end

function exit(state, data)

activate_deactivate_stim_comm( data, 0 ); % deactivate

states = data.Value.STATES;
next( state, states('inter_image_interval') );

end

function conditional_draw_eyelink_stim_rect(data, stim_rect)

interface = data.Value.INTERFACE;

if ( ~interface.use_eyelink )
  return;
end

Eyelink( 'Command', 'clear_screen 0' );
brains.util.el_draw_rect( stim_rect, 1 );

end

function stim_rect = handle_stim_comm(data, state)

current_trial_data = data.Value.CURRENT_TRIAL_DATA;
stim_comm = data.Value.STIM_COMM;
stim_params = data.Value.STIM_PARAMS;

stim_rect = current_trial_data.stim_rect;
active_roi = stim_params.active_rois;

% set current stimulated roi depending on image
update_stimulated_roi( stim_comm, active_roi, stim_rect );

% enable stimulation
activate_deactivate_stim_comm( data, 1 ); 

state.UserData.is_stim_comm_active = true;

end

function update_stimulated_roi(stim_comm, active_roi, stim_rect)

import brains.arduino.calino.send_bounds;

if ( isempty(stim_comm) || ~isvalid(stim_comm) )
  return
end

send_bounds( stim_comm, 'm1', active_roi, round(stim_rect) );

end

function activate_deactivate_stim_comm(data, tf)

stim_params = data.Value.STIM_PARAMS;
stim_comm = data.Value.STIM_COMM;

active_rois = stim_params.active_rois;

[success, msg] = bsc.serial.private.activate_deactive_stim( stim_comm, active_rois, tf );
assert( success, msg );

end