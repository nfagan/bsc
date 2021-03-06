function state = inter_image_interval(data)

time_in = data.Value.TIME_IN;

state = ptb.State();
state.Name = 'inter_image_interval';

state.Duration = time_in.(state.Name);

state.Entry = @(state) entry(state, data);
state.Loop = @(state) loop(state, data);
state.Exit = @(state) exit(state, data);

end

function entry(state, data)

window = data.Value.WINDOW;

flip( window );

bsc.task.mark_event( data, 'image_offset' );

state.UserData.current_reward_pulse_index = 1;
state.UserData.reward_timer = nan;

end

function loop(state, data)

structure = data.Value.STRUCTURE;
sync_comm = data.Value.SYNC_COMM; % performs synch + reward
time_in = data.Value.TIME_IN;

reward_timer = state.UserData.reward_timer;
current_pulse_index = state.UserData.current_reward_pulse_index;

reward_size = structure.inter_image_interval_reward_size;
n_pulses = structure.inter_image_interval_n_reward_pulses;
reward_delay = time_in.delay_to_reward;

% add 50ms padding between rewards -- ensures the previous reward is
% finished before the next one is begun. Doesn't change the actual
% delivered amount.
reward_size_s = (reward_size + 50) / 1e3;

reward_condition_a = current_pulse_index == 1 || toc(reward_timer) > reward_size_s;
reward_condition_b = elapsed( state ) >= reward_delay;

reward_condition_met = reward_condition_a && reward_condition_b && current_pulse_index <= n_pulses;

if ( reward_condition_met )
  reward( sync_comm, 1, reward_size );
  
  state.UserData.current_reward_pulse_index = current_pulse_index + 1;
  state.UserData.reward_timer = tic;
  
  % If this is the first pulse, log the time of reward.
  if ( current_pulse_index == 1 )
    bsc.task.mark_event( data, 'inter_image_interval_reward_onset' );
  end
  
  bsc.task.log( 'Rewarding ...', data, 'reward' );
end

end

function exit(state, data)

states = data.Value.STATES;
next( state, states('end_trial') );

end