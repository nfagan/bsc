function bsc_image_crop_tool(varargin)

defaults = get_defaults();
params = shared_utils.general.parsestruct( defaults, varargin );

image = params.image;
resize_to = params.resize_to;
figure_handle = [];

current_eye_index = [];
eye_left_coords = [];
eye_right_coords = [];
cropping_rectangle_coordinates = [];
cropping_rect = params.cropping_rect;
eye_cropping_rect = [];
face_cropping_rect = [];
original_image = image;

if ( nargin == 0 || isempty(image) )
  % Calls reset
  load_image();
else
  reset();
end

if ( ~isempty(cropping_rect) )
  cropping_rectangle_coordinates = rect_to_rectangle( cropping_rect );
  crop_image();
end

function mouse_down_cb(src, event)
  coord = event.IntersectionPoint(1:2);

  if ( current_eye_index == 1 )
    eye_left_coords = coord;
  elseif ( current_eye_index == 2 )
    eye_right_coords = coord;

    create_rectangle();
  else
    reset();
    return
  end

  current_eye_index = current_eye_index + 1;
end

function reset()
  
  if ( ~isempty(figure_handle) )
    delete( figure_handle );
  end
  
  f = figure(1);
  
  ax = gca();
  cla( ax );
  
  image_handle = imshow( image, 'parent', ax );
  image_handle.ButtonDownFcn = @mouse_down_cb;

  current_eye_index = 1;
  eye_left_coords = [];
  eye_right_coords = [];
  cropping_rectangle_coordinates = [];
  
  crop_control = uicontrol( ...
      'parent', f ...
    , 'style', 'pushbutton' ...
    , 'string', 'Crop' ...
    , 'position', [0, 0, 60, 20] ...
    , 'callback', @crop_image ...
  );

  crop_sz = crop_control.Position;

  revert_control = uicontrol( ...
      'parent', f ...
    , 'style', 'pushbutton' ...
    , 'string', 'Revert' ...
    , 'callback', @revert_image ...
    , 'position', [crop_sz(1) + crop_sz(3), 0, crop_sz(3), crop_sz(4)] ...
  );

  rev_sz = revert_control.Position;

  save_control = uicontrol( ...
      'parent', f ...
    , 'style', 'pushbutton' ...
    , 'string', 'Save' ...
    , 'callback', @save_image ...
    , 'position', [rev_sz(1) + rev_sz(3), 0, rev_sz(3), rev_sz(4)] ...
  );

  save_sz = save_control.Position;

  load_control = uicontrol( ...
      'parent', f ...
    , 'style', 'pushbutton' ...
    , 'string', 'Load' ...
    , 'callback', @load_image ...
    , 'position', [save_sz(1) + save_sz(3), 0, save_sz(3), save_sz(4)] ...
  );

  load_sz = load_control.Position;

  apply_control = uicontrol( ...
      'parent', f ...
    , 'style', 'pushbutton' ...
    , 'string', 'Bounds ...' ...
    , 'callback', @load_cropping_rect ...
    , 'position', [load_sz(1) + load_sz(3), 0, load_sz(3), load_sz(4)] ...
  );

  apply_sz = apply_control.Position;

  min_width = crop_sz(3) + rev_sz(3) + save_sz(3) + load_sz(3) + apply_sz(3);
  
  if ( f.Position(3) < min_width )
    f.Position(3) = min_width;
  end
  
  figure_handle = f;
end

function crop_image(src, event)
  
  if ( isempty(cropping_rectangle_coordinates) )
    reset();
    return
  end
  
  image_size = size( image );
  
  min_x = floor( cropping_rectangle_coordinates(1) );
  max_x = min_x + floor( cropping_rectangle_coordinates(3) );
  min_y = floor( cropping_rectangle_coordinates(2) );
  max_y = min_y + floor( cropping_rectangle_coordinates(4) );
  
  if ( min_x < 0 || min_y < 0 || max_x > image_size(2) || max_y > image_size(1) )
    warning( 'Crop coordinates are outside the image bounds. Not cropping ...' );
    reset();
    return
  end
  
  image = image(min_y:max_y, min_x:max_x, :);
  cropping_rect = [ min_x, min_y, max_x, max_y ];
  
  reset();
end

function save_image(src, event)
  
  [filename, path] = uiputfile( '*.png', 'Save' );
  
  if ( ~ischar(filename) )
    return
  end
  
  if ( ~isempty(resize_to) )
    saved_image = imresize( image, flip(resize_to) );
  else
    saved_image = image;
  end
  
  try
    imwrite( saved_image, fullfile(path, filename), 'png' );
    save( fullfile(path, strrep(filename, '.png', '.mat')) ...
      , 'cropping_rect', 'eye_cropping_rect', 'face_cropping_rect' );
  catch err
    warning( 'Failed to write file: %s.', err.message );
  end
end

function load_image(src, event)
  
  [filename, path] = uigetfile( get_image_extension_str(), 'Open an image.' );
  
  if ( ~ischar(filename) )
    return
  end
  
  try
    image = imread( fullfile(path, filename) );    
    original_image = image;
  catch err
    warning( 'Failed to read file "%s": \n %s', filename, err.message );
  end
  
  reset();
end

function load_cropping_rect(src, event)
  
  [filename, path] = uigetfile( '*.mat', 'Open a cropping rect.' );
  
  if ( ~ischar(filename) )
    return
  end
  
  try
    crop_rect_file = load( fullfile(path, filename) );
    cropping_rectangle_coordinates = rect_to_rectangle( crop_rect_file.cropping_rect );
    
  catch err
    warning( 'Failed to read cropping file "%s":\n "%s".', filename, err.message );
  end
  
  crop_image();
end

function revert_image(src, event)
  image = original_image;
  reset();
end

function create_rectangle()
  if ( isempty(eye_right_coords) || isempty(eye_left_coords) )
    return;
  end

  meas = params.far_plane_measurements;

  vec = eye_right_coords - eye_left_coords;
  eye_dist_px = sqrt( dot(vec, vec) );

  eye_x_px = mean( [eye_right_coords(1), eye_left_coords(1)] );
  eye_y_px = mean( [eye_right_coords(2), eye_left_coords(2)] );

  px_cm_factor = eye_dist_px / meas.inter_eye_dist_cm;

  face_left = eye_x_px - meas.face_left_to_eye_center_cm * px_cm_factor;
  face_top = eye_y_px - meas.face_top_to_eye_center_cm * px_cm_factor;
  face_width_px = meas.face_width_cm * px_cm_factor;
  face_height_px = meas.face_height_cm * px_cm_factor;
  
  pad_amt = params.padding;
  
  cropping_rectangle_coordinates = [face_left, face_top, face_width_px, face_height_px];

  rectangle( 'Position', cropping_rectangle_coordinates );
  
  if ( any(pad_amt ~= 0) )
    padded_rect = cropping_rectangle_coordinates;

    % Add padding
    padded_rect(1) = padded_rect(1) - pad_amt(1) / 2;
    padded_rect(3) = padded_rect(3) + pad_amt(1);
    padded_rect(2) = padded_rect(2) - pad_amt(2) / 2;
    padded_rect(4) = padded_rect(4) + pad_amt(2);
    
    rectangle( 'Position', padded_rect );
    
    cropping_rectangle_coordinates = padded_rect;
  end
  
  % Add eyes
  [eye_w_cm, eye_h_cm] = get_eye_roi_dimensions();
  eye_w_cm = eye_w_cm + meas.inter_eye_dist_cm;
  
  eye_min_x = eye_x_px - eye_w_cm * px_cm_factor / 2;
  eye_min_y = eye_y_px - eye_h_cm * px_cm_factor / 2;
  
  eye_w_px = eye_w_cm * px_cm_factor;
  eye_h_px = eye_h_cm * px_cm_factor;
  
  eye_rect = [ eye_min_x, eye_min_y, eye_w_px, eye_h_px ];
  
  rectangle( 'Position', eye_rect );
  
  eye_cropping_rect = ...
    [ eye_min_x, eye_min_y, eye_min_x+eye_w_px, eye_min_y+eye_h_px ];
  face_cropping_rect = ...
    [ face_left, face_top, face_left+face_width_px, face_top+face_height_px ];
end

end

function meas = get_far_plane_measurements()

meas = struct();
meas.inter_eye_dist_cm = 4;
meas.face_width_cm = 8;
meas.face_height_cm = 14;
meas.face_top_to_eye_center_cm = 4;
meas.face_left_to_eye_center_cm = 4;

end

function [eye_w_cm, eye_h_cm] = get_eye_roi_dimensions()

eye_w_cm = 2.75;
eye_h_cm = 2.75;

end

function dflts = get_defaults()

dflts = struct();
dflts.image = [];
dflts.resize_to = [];
dflts.far_plane_measurements = get_far_plane_measurements();
dflts.padding = [0, 0];
dflts.cropping_rect = [];

end

function str = get_image_extension_str()

str = '*.png;*.jpg;*.JPG';

end

function r = rect_to_rectangle(rect)

r(1) = rect(1);
r(2) = rect(2);
r(3) = rect(3) - r(1);
r(4) = rect(4) - r(2);

end