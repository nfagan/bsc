
function conf = create(do_save)

%   CREATE -- Create the config file. 
%
%     Define editable properties of the config file here.
%
%     IN:
%       - `do_save` (logical) -- Indicate whether to save the created
%         config file. Default is `false`

if ( nargin < 1 ), do_save = false; end

const = bsc.config.constants();

conf = struct();

% ID
conf.(const.config_id) = true;

% PATHS
PATHS = struct();
PATHS.repositories = fileparts( bsc.util.get_project_folder() );

%	SCREEN
SCREEN = struct();
SCREEN.index = 0;
SCREEN.background_color = [ 0 0 0 ];
SCREEN.rect = [ 0, 0, 400, 400 ];

% TIMINGS
TIME_IN = struct();
TIME_IN.present_image = 10;
TIME_IN.inter_image_interval = 3;
TIME_IN.task = 5 * 60;
TIME_IN.delay_to_reward = 0;
TIME_IN.break = 10;

% INTERFACE
INTERFACE = struct();
INTERFACE.use_arduino = false;
INTERFACE.use_eyelink = false;
INTERFACE.save_data = true;
INTERFACE.sync_reward_serial_port = 'COM4';

% STRUCTURE
STRUCTURE = struct();
STRUCTURE.inter_image_interval_reward_size = 100;
STRUCTURE.inter_image_interval_n_reward_pulses = 1;
STRUCTURE.key_press_reward_size = 50;
STRUCTURE.is_debug = true;
STRUCTURE.debug_tags = 'all';
STRUCTURE.max_n_trials = Inf;
STRUCTURE.n_blocks = 100;
STRUCTURE.n_trials_to_break = Inf;
STRUCTURE.use_key_to_exit_break = false;

% STIM_PARAMS
STIM_PARAMS = struct();
STIM_PARAMS.use_stim_comm = false;
STIM_PARAMS.sync_m1_m2_params = false;
STIM_PARAMS.probability = 0;
STIM_PARAMS.frequency = 15000;
STIM_PARAMS.max_n = 0;
STIM_PARAMS.active_rois = 'eyes'; % which rois will trigger stimulation
STIM_PARAMS.protocol = nan;
STIM_PARAMS.protocol_name = 'm1_exclusive_event';
STIM_PARAMS.deactivate_stim_after_image_onset_seconds = 0;
STIM_PARAMS.stim_rect = [];
STIM_PARAMS.port = 'COM6';

% STIMULI
STIMULI = struct();
% Value such that, on a 1024x768 display, and using an image originally of
% size 479x639, the eye roi of social images will align with the average
% eye roi in the free viewing task.
STIMULI.image_rect = [326, 77, 804, 715];
STIMULI.image_set = '';
STIMULI.n_left = 1;
STIMULI.n_right = 1;
STIMULI.n_straight = 2;
STIMULI.max_n_repeats_for_image_set = 2;
STIMULI.image_subdirectory_name = 'images';

% EXPORT
conf.PATHS = PATHS;
conf.SCREEN = SCREEN;
conf.STIM_PARAMS = STIM_PARAMS;
conf.TIME_IN = TIME_IN;
conf.STRUCTURE = STRUCTURE;
conf.INTERFACE = INTERFACE;
conf.STIMULI = STIMULI;

if ( do_save )
  bsc.config.save( conf );
end

end