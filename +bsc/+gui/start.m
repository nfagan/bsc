function start(conf)

persistent F;

if ( isempty(F) || ~isvalid(F) )
  F = figure();
end

if ( nargin < 1 )
  conf = bsc.config.load();
end

conf = bsc.config.prune( bsc.config.reconcile(conf) );

N = 4;    %   n panels
W = 0.9;
Y = 0.05;
X = (1 - W) / 2;
L = (1 / N) - Y/2;

clf( F );

panels = struct();

% STIM_PARAMS
panels.stim_params = uipanel( F ...
  , 'Title', 'Stim Params' ...
  , 'Position', [ X, Y, W/2, L ] ...
);

stim_params_popup = shared_utils.gui.TextFieldDropdown();
stim_params_popup.orientation = 'vertical';
stim_params_popup.non_editable = { 'protocol' };
stim_params_popup.on_change = @handle_stim_params_change;
stim_params_popup.parent = panels.stim_params;
stim_params_popup.set_data( conf.STIM_PARAMS );

% SCREEN
panels.screen = uipanel( F ...
  , 'Title', 'Screen' ...
  , 'Position', [ X+W/2, Y, W/2, L ] ...
);

screen_popup = shared_utils.gui.TextFieldDropdown();
screen_popup.orientation = 'vertical';
screen_popup.on_change = @handle_screen_change;
screen_popup.parent = panels.screen;
screen_popup.set_data( conf.SCREEN );

% TIME_IN
panels.time_in = uipanel( F ...
  , 'Title', 'Time in' ...
  , 'Position', [ X, Y+L, W/2, L ] ...
);

time_in_popup = shared_utils.gui.TextFieldDropdown();
time_in_popup.orientation = 'vertical';
time_in_popup.on_change = @handle_time_in_change;
time_in_popup.parent = panels.time_in;
time_in_popup.set_data( conf.TIME_IN );

% INTERFACE
panels.interface = uipanel( F ...
  , 'Title', 'Interface' ...
  , 'Position', [ X + W/2, Y+L, W/2, L ] ...
);

interface_popup = shared_utils.gui.TextFieldDropdown();
interface_popup.orientation = 'vertical';
interface_popup.on_change = @handle_interface_change;
interface_popup.parent = panels.interface;
interface_popup.set_data( conf.INTERFACE );

% Run
panels.run = uipanel( F, 'Title', 'Run', 'Position', [X, Y+L*3, W, L] );

funcs = { 'load', 'save', 'calibrate', 'start' };

w = .5;
l = 1 / numel(funcs);
x = 0;
y = 0;

for i = 1:numel(funcs)
  func_name = funcs{i};
  position = [ x, y, w, l ];
  uicontrol( panels.run ...
    , 'Style', 'pushbutton' ...
    , 'String', func_name ...
    , 'Units', 'normalized' ...
    , 'Position', position ...
    , 'Callback', @handle_button ...
  );
  y = y + l;
end

% STRUCTURE
panels.structure = uipanel( F ...
  , 'Title', 'Structure' ...
  , 'Position', [ X, Y+L*2, W/2, L ] ...
);

structure_popup = shared_utils.gui.TextFieldDropdown();
structure_popup.on_change = @handle_structure_change;
structure_popup.orientation = 'vertical';
structure_popup.parent = panels.structure;
structure_popup.set_data( conf.STRUCTURE );

% STIMULI
panels.stimuli = uipanel( F ...
  , 'Title', 'Stimuli' ...
  , 'Position', [ X+W/2, Y+L*2, W/2, L ] ...
);

stimuli_popup = shared_utils.gui.TextFieldDropdown();
stimuli_popup.on_change = @handle_stimuli_change;
stimuli_popup.orientation = 'vertical';
stimuli_popup.parent = panels.stimuli;
stimuli_popup.set_data( conf.STIMULI );

% stim param change
function new = handle_stim_params_change(old, new, property)
  if ( strcmp(property, 'protocol_name') )
    try
      new = bsc.serial.reconcile_stim_params( new );
    catch err
      warning( 'Failed to update protocol_name with message: \n%s', err.message );
      new = old;
    end
  elseif ( strcmp(property, 'active_rois') )
    try
      bsc.serial.util.check_active_roi_names( new.active_rois );
    catch err
      warning( 'Failed to update active roi name: \n%s', err.message );
      new = old;
    end
  end
  
  conf.STIM_PARAMS = new;
  bsc.config.save( conf );
end

% time in change
function new = handle_time_in_change(old, new, property)
  conf.TIME_IN = new;
  bsc.config.save( conf );
end

% structure change
function new = handle_structure_change(old, new, property)
  conf.STRUCTURE = new;
  bsc.config.save( conf );
end

% stimuli change
function new = handle_stimuli_change(old, new, property)
  conf.STIMULI = new;
  bsc.config.save( conf );
end

% screen change
function new = handle_screen_change(old, new, property)
  conf.SCREEN = new;
  bsc.config.save( conf );
end

% interface change
function new = handle_interface_change(old, new, property)
  conf.INTERFACE = new;
  bsc.config.save( conf );
end

function load_new_config_file()
  [filename, path] = uigetfile( '*.mat', 'Choose a config file.' );

  if ( ~ischar(filename) )
    return
  end

  try
    loaded_conf = shared_utils.io.fload( fullfile(path, filename) );
  catch err
    warning( 'Failed to read file "%s": \n %s', filename, err.message );
  end
  
  if ( ~bsc.config.is_config(loaded_conf) )
    warning( 'The file "%s" is not a valid config file. Not loading ...' ...
      , filename );
    return
  end
  
  bsc.gui.start( loaded_conf );
end

function save_current_config_file()  
  [filename, path] = uiputfile( '*.mat', 'Save' );
  
  if ( ~ischar(filename) )
    return
  end
  
  try
    save( fullfile(path, filename), 'conf' );
  catch err
    warning( 'Failed to save "%s":\n %s.', filename, err.message );
  end
end

% button press
function handle_button(source, event)
  
  func = source.String;
  
  switch ( func )
    case 'start'
      bsc.config.save( conf );
      bsc.task.start( conf );
    case 'calibrate'
      bsc.config.save( conf );
      brains.calibrate.EyeCal();
    case 'load'
      load_new_config_file();
    case 'save'
      save_current_config_file();
    otherwise
      error( 'Unhandled function name: "%s".', func );
  end      
end

end