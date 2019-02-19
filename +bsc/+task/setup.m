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
image_set = data.Value.STIMULI.image_set;
image_rect = data.Value.STIMULI.image_rect;
stim_params = data.Value.STIM_PARAMS;

image_p = fullfile( bsc.util.get_project_folder(), 'stimuli', 'images' );
image_sets = shared_utils.io.dirnames( image_p, 'folders' );

shared_utils.assertions.assert__is_parameter( image_set, image_sets, 'image set' );

image_p = fullfile( image_p, image_set );
subdirs = { 'left', 'right', 'straight' };

images = containers.Map();
debug_images = containers.Map();
image_rois = containers.Map(); % contains eye, face, etc.
stim_rects = containers.Map();

image_identifiers = {};

for i = 1:numel(subdirs)  
  subdir = subdirs{i};
  
  image_files = shared_utils.io.find( fullfile(image_p, subdir), '.png' );
  image_filenames = shared_utils.io.filenames( image_files );
  
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
    
%     [image_rect, eye_rect] = convert_stim_rect_to_image_rect( cropping_rect, eye_rect, stim_rect );
    stim_rect = convert_image_rect_to_stim_rect( cropping_rect, eye_rect, image_rect );
    stim_rect = round( stim_rect );
    
    configure_image_object_from_rect( stimulus_object, image_rect );
    configure_image_object_from_rect( debug_stimulus_object, stim_rect );
    
    image_identifier = sprintf( '%s/%s/%s', image_set, subdir, image_filenames{j} );
    image_identifiers{end+1} = image_identifier;  %#ok
    
    images(image_identifier) = stimulus_object;
    debug_images(image_identifier) = debug_stimulus_object;
    image_rois(image_identifier) = image_roi;
    stim_rects(image_identifier) = stim_rect;
  end
end

IMAGES = struct();
IMAGES.images = images;
IMAGES.debug_images = debug_images;
IMAGES.image_identifiers = image_identifiers;
IMAGES.image_set = image_set;
IMAGES.image_rois = image_rois;

stim_params.stim_rects = stim_rects;

data.Value.IMAGES = IMAGES;
data.Value.STIM_PARAMS = stim_params;

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

function [new_image_rect, new_roi_rect] = convert_stim_rect_to_image_rect(crop_rect, roi_rect, stim_rect)

target_width = stim_rect(3) - stim_rect(1);
target_height = stim_rect(4) - stim_rect(2);
target_x_offset = stim_rect(1);
target_y_offset = stim_rect(2);

cx = crop_rect(1);
cy = crop_rect(2);

make_origin_referenced = @(r, cx, cy) [r(1)-cx, r(2)-cy, r(3)-cx, r(4)-cy];
make_width = @(r) r(3) - r(1);
make_height = @(r) r(4) - r(2);

origin_referenced_eye = make_origin_referenced( roi_rect, cx, cy );
origin_referenced_crop = make_origin_referenced( crop_rect, cx, cy );

roi_crop_width = make_width( origin_referenced_eye );
roi_crop_height = make_height( origin_referenced_eye );

crop_width = make_width( origin_referenced_crop );
crop_height = make_height( origin_referenced_crop );

x_offset_to_roi = crop_rect(1) - roi_rect(1);
y_offset_to_roi = crop_rect(2) - roi_rect(2);

% match to eyes
frac_width = target_width / roi_crop_width;
frac_height = target_height / roi_crop_height;

x_frac_offset = x_offset_to_roi * frac_width;
y_frac_offset = y_offset_to_roi * frac_height;

new_width = crop_width * frac_width;
new_height = crop_height * frac_height;

new_image_rect = [ 0, 0, new_width, new_height ];

new_image_rect([1, 3]) = new_image_rect([1, 3]) + target_x_offset + x_frac_offset;
new_image_rect([2, 4]) = new_image_rect([2, 4]) + target_y_offset + y_frac_offset;

new_roi_rect = [ 0, 0, roi_crop_width*frac_width, roi_crop_height*frac_height ];
new_roi_rect([1, 3]) = new_roi_rect([1, 3]) + target_x_offset;
new_roi_rect([2, 4]) = new_roi_rect([2, 4]) + target_y_offset;

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