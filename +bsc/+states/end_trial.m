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

states = data.Value.STATES;
next( state, states('new_trial') );

end