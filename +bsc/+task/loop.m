function loop(task, data)

persistent reward_key_timer;

keys_to_check = { ptb.keys.esc(), KbName('r') };
key_state = ptb.util.are_keys_down( keys_to_check{:} );

if ( key_state(1) )
  % Escape key pressed; abort
  escape( task );
  return;
end

tracker =   data.Value.TRACKER;
comm =      data.Value.SYNC_COMM; % sync comm also delivers reward.
structure = data.Value.STRUCTURE;

key_press_reward_size = structure.key_press_reward_size;

if ( key_state(2) && (isempty(reward_key_timer) || toc(reward_key_timer) > 0.2) )
  % Reward key pressed and more than 200 ms since last reward.
  reward( comm, 1, key_press_reward_size );
  
  reward_key_timer = tic();
end

current_time = elapsed( task );
sync = data.Value.SYNC;
next_sync_time = sync.next_sync_time;

if ( isnan(next_sync_time) || current_time > next_sync_time )
  sync_pulse_map = data.Value.SERIAL.sync_pulse_map;
  
  send_message( tracker, 'RESYNCH' );
  sync_pulse( comm, sync_pulse_map.periodic_sync );
  
  sync_stp = data.Value.SYNC.plex_sync_stp;
  
  data.Value.SYNC.plex_sync_times(sync_stp) = current_time;
  data.Value.SYNC.plex_sync_stp = sync_stp + 1;
  data.Value.SYNC.next_sync_time = elapsed( task ) + sync.plex_sync_interval;
end

end