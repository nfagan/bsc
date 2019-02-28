function data = setup(conf, brains_conf)

%   SETUP -- Initialize task, return 
%
%     data = bsc.task.setup() returns the complete set of components required
%     to run the task. `data` is a ptb.Reference object; when it is deleted
%     or cleared, 

if ( nargin < 1 || isempty(conf) )
  conf = bsc.config.load();
else
  bsc.util.assertions.assert__is_config( conf );
end

if ( nargin < 2 || isempty(brains_conf) )
  brains_conf = brains.config.load();
end

conf = bsc.config.prune( bsc.config.reconcile(conf) );
brains_conf = brains.config.reconcile( brains_conf );

% Create task data.
[data, data_folder, edf_filename] = make_data( conf, brains_conf );

make_unified_opts( data, conf );

% Create eye tracker.
use_eyelink = data.Value.INTERFACE.use_eyelink;
make_tracker( data, use_eyelink, data_folder, edf_filename );

% Create sync times.
make_sync( data );

% Create far plane calibration info.
% make_far_plane( data );

% Create task object.
make_task( data );

% Create state objects.
make_states( data );

% Open windows.
make_windows( data );

% Create images.
make_images( data );

% Create arduino interfaces.
make_sync_comm( data, conf );
make_stim_comm( data );

% We won't save data unless we make it here.
data.Value.is_setup_complete = true;

end

function make_unified_opts(data, conf)

interface = struct();
interface.use_arduino = conf.INTERFACE.use_arduino;
interface.use_eyelink = conf.INTERFACE.use_eyelink;
interface.save_data =   conf.INTERFACE.save_data;

screen = struct();
screen.rect = conf.SCREEN.rect;
screen.index = conf.SCREEN.index;
screen.background_color = conf.SCREEN.background_color;

time_in = conf.TIME_IN;
structure = conf.STRUCTURE;
stimuli = conf.STIMULI;

stim_params = bsc.serial.reconcile_stim_params( conf.STIM_PARAMS );

data.Value.INTERFACE = interface;
data.Value.SCREEN = screen;
data.Value.TIME_IN = time_in;
data.Value.STRUCTURE = structure;
data.Value.STIM_PARAMS = stim_params;
data.Value.STIMULI = stimuli;

end

function make_images(data)

window = data.Value.WINDOW;
stimuli = data.Value.STIMULI;
structure = data.Value.STRUCTURE;
image_set = stimuli.image_set;
image_rect = stimuli.image_rect;
stim_params = data.Value.STIM_PARAMS;

time_limit_per_permutation_iter = 1;

n_blocks = structure.n_blocks;
max_n_repeats = stimuli.max_n_repeats_for_image_set;
image_subdir = stimuli.image_subdirectory_name;

image_p = fullfile( bsc.util.get_project_folder(), 'stimuli', image_subdir );
image_sets = shared_utils.io.dirnames( image_p, 'folders' );

directions = { 'left', 'right', 'straight' };

images = containers.Map();
debug_images = containers.Map();
image_rois = containers.Map(); % contains eye, face, etc.
stim_rects = containers.Map();
image_set_containers = containers.Map();

image_identifiers = {};
all_image_sets = containers.Map();

C = combvec( 1:numel(directions), 1:numel(image_sets) );

for i = 1:size(C, 2)
  subdir = directions{C(1, i)};
  image_set = image_sets{C(2, i)};
  
  if ( strncmp(image_set, '__', 2) )
    % Ignore image sets that begin with __
    continue;
  end
  
  sub_image_p = fullfile( image_p, image_set, subdir );
  
  image_files = shared_utils.io.find( sub_image_p, '.png' );
  image_filenames = shared_utils.io.filenames( image_files );
  image_set_id = sprintf( '%s/%s', image_set, subdir );
  
  image_set_container = bsc.stimuli.FileSet();
  
  if ( ~isKey(all_image_sets, image_set) )
    all_image_sets(image_set) = true;
  end
  
  for j = 1:numel(image_files)
    image_file = image_files{j};
    image_roi_file = sprintf( '%s.mat', shared_utils.io.filenames(image_file) );
    image_roi_file = fullfile( fileparts(image_file), image_roi_file );
    
    image_matrix = imread( image_file );
    image_roi = load( image_roi_file );
    
    image_object = ptb.Image( window, image_matrix );
    
    stimulus_object = ptb.stimuli.Rect();
    stimulus_object.FaceColor = image_object;
    
    debug_stimulus_object = ptb.stimuli.Rect();
    debug_stimulus_object.FaceColor = ptb.Null();
    debug_stimulus_object.EdgeColor = set( ptb.Color(), [255, 255, 255] );
    
    cropping_rect = image_roi.cropping_rect;
    eye_rect = image_roi.eye_cropping_rect;
    
    stim_rect = convert_image_rect_to_stim_rect( cropping_rect, eye_rect, image_rect );
    stim_rect = round( stim_rect );
    
    configure_image_object_from_rect( stimulus_object, image_rect );
    configure_image_object_from_rect( debug_stimulus_object, stim_rect );
    
    image_identifier = sprintf( '%s/%s', image_set_id, image_filenames{j} );
    image_identifiers{end+1} = image_identifier;  %#ok
    
    images(image_identifier) = stimulus_object;
    debug_images(image_identifier) = debug_stimulus_object;
    image_rois(image_identifier) = image_roi;
    stim_rects(image_identifier) = stim_rect;
    
    image_set_container.add_identifier( image_identifier );
  end
  
  finalize( image_set_container );
  image_set_containers(image_set_id) = image_set_container;
end

all_image_sets = keys( all_image_sets );

[condition_ids, condition_labels] = ...
  get_condition_ids_and_labels_mult_image_sets( n_blocks, stimuli ...
  , all_image_sets, directions, max_n_repeats, time_limit_per_permutation_iter );

IMAGES = struct();
IMAGES.images = images;
IMAGES.debug_images = debug_images;
IMAGES.image_identifiers = image_identifiers;
IMAGES.image_set = image_set;
IMAGES.image_rois = image_rois;
IMAGES.image_set_containers = image_set_containers;
IMAGES.condition_ids = condition_ids;
IMAGES.condition_labels = condition_labels;
IMAGES.condition_index = 1;

stim_params.stim_rects = stim_rects;

data.Value.IMAGES = IMAGES;
data.Value.STIM_PARAMS = stim_params;

end

function [n_reps_per_direction, total_n_reps] = get_n_repetitions_per_direction(stimuli, directions)

n_reps_per_direction = struct();
total_n_reps = 0;

for i = 1:numel(directions)
  direction = directions{i};
  
  n_use_fieldname = sprintf( 'n_%s', direction );
  
  if ( ~isfield(stimuli, n_use_fieldname) )
    error( 'Direction "%s" has no corresponding n_%s field in STRUCTURE.' ...
      , direction, direction );
  end
  
  n_use = stimuli.(n_use_fieldname);
  
  n_reps_per_direction.(direction) = n_use;
  total_n_reps = total_n_reps + n_use;
end

end

function [final_ids, labels] = ...
  get_condition_ids_and_labels_mult_image_sets(n_blocks, stimuli, image_sets ...
  , directions, max_repeating_sets, time_limit_per_iteration)

[n_reps_per_direction, total_n_reps] = get_n_repetitions_per_direction( stimuli, directions );

n_sets = numel( image_sets );
n_conditions = total_n_reps * n_sets;

tmp_ids = shared_utils.general.get_blocked_condition_indices( n_blocks, n_conditions, n_conditions );
final_ids = nan( size(tmp_ids) );
image_set_ids = nan( size(tmp_ids) );

remaining_ids = randperm( n_conditions );
condition_id = 1;
labels = containers.Map( 'keytype', 'double', 'valuetype', 'char' );

make_image_set_label = @(image_set, direction) sprintf( '%s/%s', image_set, direction );

for i = 1:n_sets  
  image_set = image_sets{i};
  
  for j = 1:numel(directions)
    direction = directions{j};
    n_reps = n_reps_per_direction.(direction);
    is_select_ind = 1:n_reps;
    
    direction_inds = remaining_ids(is_select_ind);
    is_direction = matches_condition_label( tmp_ids, direction_inds );
    
    final_ids(is_direction) = condition_id;
    image_set_ids(is_direction) = i;  % one image set.
    
    labels(condition_id) = make_image_set_label( image_set, direction );
    
    remaining_ids(is_select_ind) = [];
    condition_id = condition_id + 1;
  end
end

if ( max_repeating_sets > 0 )
  permuted_ind = permute_ensuring_n_non_repeating( image_set_ids, n_conditions ...
    , max_repeating_sets, time_limit_per_iteration );
  final_ids = final_ids(permuted_ind);
end

assert( labels.Count == numel(unique(final_ids)) );

end

function permuted_ind = permute_ensuring_n_non_repeating(values, n_conditions, threshold, time_limit_per_iter)

% For each unique value in `values`, ensure no more than `threshold` of
% them appear in a row. The implementation is such that the number of
% conditions within each block is preserved.

n_values = numel( values );
n_blocks = n_values / n_conditions;
unique_values = unique( values );
n_unique_values = numel( unique_values );

assert( mod(n_blocks, 1) == 0 );  % ensure integer valued n_blocks

permuted_ind = nan( n_values, 1 );

stp = 1;
is_ok = false( numel(unique_values), 1 );
for i = 1:n_blocks
  stop = stp + n_conditions - 1;
  
  subset = reshape( values(stp:stop), [], 1 );
  perm_ind = 1:n_conditions;
  has_valid_permutation = false;
  iter_timer = tic();
  
  while ( toc(iter_timer) < time_limit_per_iter )
    is_ok(:) = false;
    
    if ( i == 1 )
      permuted_subset = subset(perm_ind);
    else
      % Ensure that `threshold` is respected across the boundary between
      % the previous and current block.
      permuted_subset = [ last_block; subset(perm_ind) ];
    end
  
    for j = 1:n_unique_values
      is_value = permuted_subset == unique_values(j);
      
      [~, durs] = shared_utils.logical.find_all_starts( is_value );
      is_ok(j) = ~any( durs > threshold );
    end
    
    if ( all(is_ok) )
      has_valid_permutation = true;
      break;
    else
      perm_ind = randperm( n_conditions );
    end
  end
  
  if ( ~has_valid_permutation )
    error( 'Failed to obtain a valid permutation within %0.3f seconds.', time_limit_per_iter );
  end
  
  permuted_ind(stp:stop) = perm_ind + stp - 1;
  last_block = subset(perm_ind);
  
  stp = stp + n_conditions;
end

end

function all_matches = matches_condition_label(all_indices, condition_labels)

each_matches = arrayfun( @(x) all_indices == x, condition_labels, 'un', 0 );

all_matches = false( numel(all_indices), 1 );

for i = 1:numel(each_matches)
  all_matches = all_matches | each_matches{i};
end

end

function stim_rect = convert_image_rect_to_stim_rect(crop_rect, roi_rect, image_rect)

make_width = @(r) r(3) - r(1);
make_height = @(r) r(4) - r(2);

image_w = make_width( image_rect );
image_h = make_height( image_rect );

crop_w = make_width( crop_rect );
crop_h = make_height( crop_rect );

assert( all(crop_rect(1:2) == 0) || all(crop_rect(1:2) == 1) ...
  , 'Expected crop rect to begin at 1 or 0.' );

if ( all(crop_rect(1:2) == 1) )
  roi_rect = roi_rect - 1;
end

frac_roi_x = roi_rect([1, 3]) / crop_w;
frac_roi_y = roi_rect([2, 4]) / crop_h;

offset_x = image_rect(1);
offset_y = image_rect(2);

new_roi_x = image_w * frac_roi_x + offset_x;
new_roi_y = image_h * frac_roi_y + offset_y;

stim_rect = [ new_roi_x(1), new_roi_y(1), new_roi_x(2), new_roi_y(2) ];

end

function configure_image_object_from_rect(obj, image_rect)

x_position = mean( image_rect([1, 3]) );
y_position = mean( image_rect([2, 4]) );

image_w = image_rect(3) - image_rect(1);
image_h = image_rect(4) - image_rect(2);

obj.Position = [ x_position, y_position ];
obj.Position.Units = 'px';

obj.Scale = [ image_w, image_h ];
obj.Scale.Units = 'px';

end

function make_tracker(data, use_eyelink, data_folder, edf_filename)

tracker = EyeTracker( edf_filename, data_folder, 0 );
tracker.bypass = ~use_eyelink;
init( tracker );

data.Value.TRACKER = tracker;

end

function make_sync(data)

sync = struct();
sync.sync_times = [];
sync.plex_sync_times = nan( 1e4, 1 );
sync.plex_sync_stp = 1;
sync.plex_sync_index = nan;
sync.next_sync_time = nan;
sync.plex_sync_interval = 1;  % sync pulse every second

data.Value.SYNC = sync;

end

function make_sync_comm(data, conf)

comm = bsc.serial.get_sync_comm( conf );

start( comm );

data.Value.SYNC_COMM = comm;
data.Value.SERIAL.sync_pulse_map = brains.arduino.get_sync_pulse_map();

end

function make_far_plane(data)

[bounds, keys, key_map, padding, consts] = ...
  bsc.util.get_bounds_and_far_plane_calibration_or_default();

key_file = struct( 'keys', keys, 'key_map', key_map );

far_plane = struct();
far_plane.bounds = bounds;
far_plane.keys = keys;
far_plane.key_map = key_map;
far_plane.key_file = key_file;
far_plane.padding = padding;
far_plane.constants = consts;

data.Value.FAR_PLANE = far_plane;

end

function make_states(data)

states = containers.Map();

states('task_entry') = bsc.states.task_entry( data );
states('new_trial') = bsc.states.new_trial( data );
states('end_trial') = bsc.states.end_trial( data );
states('present_image') = bsc.states.present_image( data );
states('inter_image_interval') = bsc.states.inter_image_interval( data );

% Enable logging of state entry and exit times.
state_names = keys( states );

for i = 1:numel(state_names)
  state = states(state_names{i});

  set_logging( state, true );
  % false -> don't add new line
  state.LogFunc = @(msg) bsc.task.log( msg, data, 'transition', false );
end

data.Value.STATES = states;

end

function make_stim_comm(data)

window = data.Value.WINDOW;
stim_params = data.Value.STIM_PARAMS;

port = stim_params.port;
window_rect = get( window.Rect );

stim_comm = bsc.serial.init_stim_comm( port, stim_params, window_rect );

data.Value.STIM_COMM = stim_comm;

end

function make_task(data)

task = ptb.Task();

task.Duration = Inf;
task.Loop = @(task) bsc.task.loop( task, data );

data.Value.TASK = task;

end

function make_windows(opts)

screen = opts.Value.SCREEN;

display_window = ptb.Window();

display_window.Index = screen.index;
display_window.Rect = screen.rect;
display_window.BackgroundColor = screen.background_color;

open( display_window );

opts.Value.WINDOW = display_window;

end

function [data, data_folder, edf_filename] = make_data(conf, brains_conf)

data_folder = get_data_folder();
shared_utils.io.require_dir( data_folder );

data = ptb.Reference();

referenced_data = struct();
referenced_data.config = conf;
referenced_data.brains_config = brains_conf;
referenced_data.is_setup_complete = false;

edf_filename = shared_utils.io.get_next_numbered_filename( data_folder, '.edf' );
data.Destruct = @bsc.task.destruct;

referenced_data.data_folder = data_folder;
referenced_data.edf_filename = edf_filename;

data.Value = referenced_data;

end


function save_p = get_data_folder()

repositories_p = fileparts( bsc.util.get_project_folder() );
save_p = fullfile( repositories_p, 'brains', 'data' ...
  , datestr(now, 'mmddyy'), 'image_control' );

end