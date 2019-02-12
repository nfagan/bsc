function state = task_entry(data)

state = ptb.State();
state.Name = 'task_entry';

state.Duration = 0;

state.Entry = @(state) entry(state, data);
state.Exit = @(state) exit(state, data);

end

function entry(state, data)

tracker =   data.Value.TRACKER;
comm =      data.Value.SYNC_COMM;
task =      data.Value.TASK;
interface = data.Value.INTERFACE;
serial =    data.Value.SERIAL;

use_arduino = interface.use_arduino;
sync_pulse_map = serial.sync_pulse_map;

send( tracker, 'SYNCH' );
sync_pulse( comm, sync_pulse_map.start );

if ( use_arduino )
  brains.util.increment_start_pulse_count();
  data.Value.SYNC.plex_sync_index = brains.util.get_current_start_pulse_count();
end

sync_stp = data.Value.SYNC.plex_sync_stp;

data.Value.SYNC.plex_sync_times(sync_stp) = elapsed( task );
data.Value.SYNC.plex_sync_stp = sync_stp + 1;

end

function exit(state, data)

states = data.Value.STATES;
next( state, states('new_trial') );

end