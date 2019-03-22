function state = end_trial(data)

state = ptb.State();
state.Name = 'end_trial';

state.Duration = 0;

state.Exit = @(state) exit(state, data);

end

function exit(state, data)

if ( ~isfield(data.Value, 'TRIAL_DATA') )
  data.Value.TRIAL_DATA = data.Value.CURRENT_TRIAL_DATA;
else
  data.Value.TRIAL_DATA(end+1) = data.Value.CURRENT_TRIAL_DATA;
end

current_n_trials = numel( data.Value.TRIAL_DATA );
max_n_trials = data.Value.STRUCTURE.max_n_trials;
trials_to_break = data.Value.STRUCTURE.n_trials_to_break;

if ( current_n_trials < max_n_trials )
  % As long as we haven't exceeded the max trials, go to the new trial
  % or break state. Otherwise, no state is marked as next, and the task stops.
  states = data.Value.STATES;
  
  if ( should_break(current_n_trials, trials_to_break) )
    next( state, states('break') );
  else
    next( state, states('new_trial') );
  end
end

end

function tf = should_break(current_n_trials, trials_to_break)

tf = current_n_trials > 0 && ~isinf( trials_to_break ) && ...
  mod( current_n_trials, trials_to_break ) == 0;

end