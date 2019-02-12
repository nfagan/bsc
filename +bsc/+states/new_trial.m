function state = new_trial(data)

state = ptb.State();
state.Name = 'new_trial';

state.Duration = 0;

state.Entry = @(state) entry(state, data);
state.Exit = @(state) exit(state, data);

end

function entry(state, data)

data.Value.CURRENT_TRIAL_DATA = create_trial_data( data );

end

function exit(state, data)

states = data.Value.STATES;
next( state, states('present_image') );

end

function trial_data = create_trial_data(data)

trial_data = struct();
trial_data.events = struct();
trial_data.image_identifier = get_current_image_identifier( data );
trial_data.image = get_current_image( data, trial_data.image_identifier );
trial_data.debug_image = get_current_debug_image( data, trial_data.image_identifier );

end

function image = get_current_image(data, id)

image = data.Value.IMAGES.images(id);

end

function image = get_current_debug_image(data, id)

image = data.Value.IMAGES.debug_images(id);

end

function id = get_current_image_identifier(data)

ids = data.Value.IMAGES.image_identifiers;
id = ids{ randi(numel(ids)) };

end