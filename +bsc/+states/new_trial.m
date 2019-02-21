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

% Is this a left vs. right vs. straight trial?
condition_label = get_current_condition_label( data );

% Id of to-be-shown image
image_identifier = get_current_image_identifier( data, condition_label );
image = get_current_image( data, image_identifier );

% Representation of stimulated bounds for this image.
debug_image = get_current_debug_image( data, image_identifier );

trial_data = struct();
trial_data.events = struct();
trial_data.image_condition = condition_label;
trial_data.image_identifier = image_identifier;
trial_data.image = image;
trial_data.debug_image = debug_image;

end

function image = get_current_image(data, id)

image = data.Value.IMAGES.images(id);

end

function image = get_current_debug_image(data, id)

image = data.Value.IMAGES.debug_images(id);

end

function condition_label = get_current_condition_label(data)

images = data.Value.IMAGES;
condition_ids = images.condition_ids;
condition_labels = images.condition_labels;
condition_index = images.condition_index;

condition_id = condition_ids(condition_index);
condition_label = condition_labels(condition_id);

condition_index = condition_index + 1;

if ( condition_index > numel(condition_ids) )
  condition_index = 1;
end

data.Value.IMAGES.condition_index = condition_index;

end

function id = get_current_image_identifier(data, condition_label)

images = data.Value.IMAGES;
image_set_container = images.image_set_containers(condition_label);

id = get_next_identifier( image_set_container );

end