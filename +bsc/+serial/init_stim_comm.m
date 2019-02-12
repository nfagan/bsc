function stim_comm = init_stim_comm(port, stim_params, screen_rect)

import brains.arduino.calino.send_bounds;
import brains.arduino.calino.get_ids;
import brains.arduino.calino.send_stim_param;

stim_comm = [];

if ( ~stim_params.use_stim_comm )
  return;
end

baud = 9600;
stim_comm = brains.arduino.calino.init_serial( port, baud );

active_roi = char( stim_params.active_rois );
target_roi_rect = stim_params.stim_rect;

send_bounds( stim_comm, 'm1', 'screen', round(screen_rect) );
send_bounds( stim_comm, 'm1', active_roi, round(target_roi_rect) );

send_stim_param( stim_comm, 'all', 'probability', stim_params.probability );
send_stim_param( stim_comm, 'all', 'frequency', stim_params.frequency );
send_stim_param( stim_comm, 'all', 'stim_stop_start', 0 );
send_stim_param( stim_comm, 'all', 'max_n', stim_params.max_n );
send_stim_param( stim_comm, 'all', 'protocol', stim_params.protocol );

end
