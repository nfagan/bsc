function state = break_state(data)

time_in = data.Value.TIME_IN;
structure = data.Value.STRUCTURE;

if ( structure.use_key_to_exit_break )
  duration = Inf;
else
  duration = time_in.break;
end

state = ptb.State();
state.Name = 'break';

state.Duration = duration;
state.UserData.check_key = structure.use_key_to_exit_break;
state.UserData.key_name_to_check = 'n';

state.Entry = @(state) entry(state, data);
state.Loop = @(state) loop(state, data);
state.Exit = @(state) exit(state, data);

end

function entry(state, data)

bsc.task.mark_event( data, 'break' );

check_key = state.UserData.check_key;
key_to_check = state.UserData.key_name_to_check;

if ( check_key )
  fprintf( '\n Press "%s" to exit break.', key_to_check );
end

end

function loop(state, data)

check_key = state.UserData.check_key;
key_to_check = state.UserData.key_name_to_check;

if ( check_key && ptb.util.is_key_down(KbName(key_to_check)) )
  escape( state );
end

end

function exit(state, data)

states = data.Value.STATES;
next( state, states('new_trial') );

end