function state = fixation(data)

state = ptb.State();
state.Name = 'fixation';

state.Duration = 0;

state.Entry = @(state) entry(state, data);
state.Exit = @(state) exit(state, data);

end

function entry(state, data)

end

function exit(state, data)

states = data.Value.STATES;
next( state, states('fixation') );

end