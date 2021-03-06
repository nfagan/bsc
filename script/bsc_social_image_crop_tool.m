function bsc_social_image_crop_tool(resize_to, roi_area_ratio, varargin)

defaults = get_defaults();
params = shared_utils.general.parsestruct( defaults, varargin );

aspect_ratio = resize_to(1) / resize_to(2);
image_matrix = params.image_matrix;

crop_coordinates = struct();
crop_coordinates.image = create_crop_coordinates();
crop_coordinates.roi = create_crop_coordinates();

crop_rects = struct();
crop_rects.image = zeros( 1, 4 );
crop_rects.roi = zeros( 1, 4 );

crop_rectangle_handles = struct();
crop_rectangle_handles.image = [];
crop_rectangle_handles.roi = [];

has_cropping_rects = struct( 'image', false, 'roi', false );

currently_editing = 'image';  % image or roi

is_dragging = struct( 'image', false, 'roi', false );
is_first_drag = struct( 'image', false, 'roi', false );
drag_deltas = struct( 'image', zeros(1, 2), 'roi', zeros(1, 2) );
drag_coords = struct( 'image', zeros(1, 2), 'roi', zeros(1, 2) );

% image_crop_rect_drag_coords = zeros( 1, 2 );
editing_control = [];

if ( isempty(image_matrix) )
  load_image();
else
  image_matrix = resize_image_to_aspect_ratio( image_matrix, aspect_ratio );
end

make_gui();

function make_gui()
  f = figure(1);
  
  set( f, 'WindowButtonMotionFcn', @mouse_move_cb );
  
  ax = gca();
  cla( ax );
  
  image_handle = imshow( image_matrix, 'parent', ax );
  image_handle.ButtonDownFcn = @mouse_down_cb;
  
  ctrl_w = 60;
  ctrl_h = 20;
  ctrl_pad = 5;
  
  N = 0;
  
  editing_control = uicontrol( ...
      'parent', f ...
    , 'style', 'pushbutton' ...
    , 'string', currently_editing ...
    , 'position', [0, 0, ctrl_w, ctrl_h] ...
    , 'callback', @handle_editing_press ...
  );

  N = N + 1;

  clear_rect_control = uicontrol( 'parent', f ...
    , 'style', 'pushbutton' ...
    , 'string', 'Clear' ...
    , 'callback', @clear_all_cropping_rects ...
    , 'position', [ctrl_w+ctrl_pad*N, 0, ctrl_w, ctrl_h] ...
  );

  N = N + 1;

%   crop_rect_control = uicontrol( 'parent', f ...
%     , 'style', 'pushbutton' ...
%     , 'string', 'Crop' ...
%     , 'callback', @crop_to_image_rect ...
%     , 'position', [ctrl_w*2 + ctrl_pad*2, 0, ctrl_w, ctrl_h] ...
%   );

  save_control = uicontrol( 'parent', f ...
    , 'style', 'pushbutton' ...
    , 'string', 'Crop + save' ...
    , 'callback', @save_image ...
    , 'position', [ctrl_w*N + ctrl_pad*N, 0, ctrl_w, ctrl_h] ...
  );

  N = N + 1;
  
  load_control = uicontrol( 'parent', f ...
    , 'style', 'pushbutton' ...
    , 'string', 'Load' ...
    , 'callback', @load_and_recreate ...
    , 'position', [ctrl_w*N + ctrl_pad*N, 0, ctrl_w, ctrl_h] ...
  );
end

function crop_to_image_rect(varargin)
  
  if ( ~has_cropping_rects.image )
    return
  end
  
  apply_cropping();
  clear_all_cropping_rects();
  make_gui();
end

function apply_cropping()
  im_size = size( image_matrix );
  
  if ( has_cropping_rects.image )
    image_crop_rect = round( crop_rects.image );
  
    m1 = clamp( image_crop_rect(2), 1, Inf ); % min y: row index 1
    m2 = clamp( image_crop_rect(4), -Inf, im_size(1) ); % max y: row index 2
    n1 = clamp( image_crop_rect(1), 1, Inf ); % min x: col index 1
    n2 = clamp( image_crop_rect(3), -Inf, im_size(2) ); % max x: col index 2
  
    image_matrix = image_matrix(m1:m2, n1:n2, :);
    
    im_size = size( image_matrix );
    
    x_roi_offset = n1;
    y_roi_offset = m1;
  else
    x_roi_offset = 0;
    y_roi_offset = 0;
  end
  
  image_crop_rect = [ 0, 0, im_size(2), im_size(1) ];
  
  crop_rects.image = image_crop_rect;
  
  if ( has_cropping_rects.roi )
    roi_crop_rect = crop_rects.roi;
    roi_crop_rect([1, 3]) = roi_crop_rect([1, 3]) - x_roi_offset;
    roi_crop_rect([2, 4]) = roi_crop_rect([2, 4]) - y_roi_offset;
    
    crop_rects.roi = roi_crop_rect;
  end
end

function apply_final_resizing()
  
  im_size = size( image_matrix );
  im_w = im_size(2);
  im_h = im_size(1);
  
  new_w = resize_to(1);
  new_h = resize_to(2);
  
  if ( has_cropping_rects.roi )
    assert( all(crop_rects.image(1:2) == 0) );
    
    frac_x1 = crop_rects.roi(1) / im_w;
    frac_y1 = crop_rects.roi(2) / im_h;
    frac_x2 = crop_rects.roi(3) / im_w;
    frac_y2 = crop_rects.roi(4) / im_h;
    
    x1 = frac_x1 * new_w;
    x2 = frac_x2 * new_w;
    y1 = frac_y1 * new_h;
    y2 = frac_y2 * new_h;
    
    crop_rects.roi = [ x1, y1, x2, y2 ];
  end
  
  crop_rects.image = [ 0, 0, new_w, new_h ];
  
  image_matrix = imresize( image_matrix, [new_h, new_w] );
end

function clear_all_cropping_rects(varargin)  
  stop_dragging_all();
  
  rect_names = fieldnames( crop_rectangle_handles );
  
  for i = 1:numel(rect_names)
    clear_cropping_rect( rect_names{i} );
  end
end

function clear_cropping_rect(kind)
  
if ( ~isempty(crop_rectangle_handles.(kind)) )
  delete( crop_rectangle_handles.(kind) );
end

has_cropping_rects.(kind) = false;
  
end

function handle_editing_press(varargin)
  stop_dragging_all();
  
  % Cycle between editing
  if ( strcmp(currently_editing, 'image') )
    currently_editing = 'roi';
    bg_color = [ 1, 0, 0 ];
  else
    currently_editing = 'image';
    bg_color = repmat( 0.94, 1, 3 );
  end
  
  editing_control.String = currently_editing;
  editing_control.BackgroundColor = bg_color;
end

function mouse_move_cb(src, event)
  kind = currently_editing;
  
  if ( is_dragging.(kind) )
    coord = event.IntersectionPoint(1:2);
    
    if ( is_first_drag.(kind) )
      drag_deltas.(kind)(:) = 0;
      
      is_first_drag.(kind) = false;
    else
      drag_deltas.(kind) = coord(:)' - drag_coords.(kind);
    end
    
    drag_coords.(kind)(:) = coord;
    
    delta_x = drag_deltas.(kind)(1);
    delta_y = drag_deltas.(kind)(2);
  end
  
  % Special case for image -- move roi too.
  if ( is_dragging.image )
    moved_image_rect = conditional_move_cropping_rect( delta_x, delta_y, 'image' );
    
    if ( has_cropping_rects.roi && moved_image_rect )
      conditional_move_cropping_rect( delta_x, delta_y, 'roi' );
    end
  end
  
  if ( is_dragging.roi )
    conditional_move_cropping_rect( delta_x, delta_y, 'roi' );
  end
end

function did_move = conditional_move_cropping_rect(delta_x, delta_y, kind)
  did_move = false;
  
  crop_rectangle_handle = crop_rectangle_handles.(kind);
  
  if ( isempty(crop_rectangle_handle) || ~isvalid(crop_rectangle_handle) )
    return
  end
  
  rect_position = crop_rectangle_handle.Position;
  
  if ( ~isnan(delta_x) && ~isnan(delta_y) )
    rect_position(1) = rect_position(1) + delta_x;
    rect_position(2) = rect_position(2) + delta_y;

    new_image_crop_rect = crop_rects.(kind);
    new_image_crop_rect([1, 3]) = crop_rects.(kind)([1, 3]) + delta_x;
    new_image_crop_rect([2, 4]) = crop_rects.(kind)([2, 4]) + delta_y;

    if ( ~any(new_image_crop_rect < 0) )
      crop_rectangle_handles.(kind).Position = rect_position;
      crop_rects.(kind) = new_image_crop_rect;
      did_move = true;
    end
  end
end

function mouse_down_cb(src, event)
  coord = event.IntersectionPoint(1:2);
  
  is_editing_image = strcmp( currently_editing, 'image' );
  kind = currently_editing;
  
  crop_rectangle_h = crop_rectangle_handles.(currently_editing);
  is_valid_rectangle_handle = ~isempty( crop_rectangle_h ) && isvalid( crop_rectangle_h );
  
  if ( is_valid_rectangle_handle )
    if ( ~is_dragging.(kind) && coordinate_in_rect(coord, crop_rects.(kind)) )
      start_dragging( kind );
      
      return;
    elseif ( is_dragging.(kind) )
      stop_dragging( kind );
      
      return;
    end
  end
  
  click_index = increment_and_get_mouse_click_index();
  
  crop_coordinates.(currently_editing)(:, click_index) = coord;
  
  if ( click_index == 2 )
    if ( is_editing_image )
      create_image_cropping_rectangle_from_crop_coordinates();
    else
      create_roi_cropping_rectangle_from_crop_coordinates();
    end
    
    crop_coordinates.(currently_editing) = create_crop_coordinates();
  end
end

function create_roi_cropping_rectangle_from_crop_coordinates()
  if ( ~isempty(crop_rectangle_handles.roi) && isvalid(crop_rectangle_handles.roi) )
    delete( crop_rectangle_handles.roi );
  end
  
  [x1, x2, y1, y2] = decompose_crop_coordinages_ensuring_ascend_ordering( crop_coordinates.roi );
  
  if ( has_cropping_rects.image )
    reference_rect = crop_rects.image;
  else
    reference_rect = [ 0, 0, size(image_matrix, 2), size(image_matrix, 1) ];
  end
  
  ref_w = reference_rect(3) - reference_rect(1);
  ref_h = reference_rect(4) - reference_rect(2);
  
  frac_x1 = (x1 - reference_rect(1)) / ref_w;
  frac_x2 = (x2 - reference_rect(1)) / ref_w;
  frac_y1 = (y1 - reference_rect(2)) / ref_h;
  frac_y2 = (y2 - reference_rect(2)) / ref_h;
  
  frac_rect = [ frac_x1, frac_y1, frac_x2, frac_y2 ];
  
  if ( any(frac_rect < 0) || any(frac_rect > 1) )
    warning( 'Cropping coordinates fall outside container. Not cropping ...' );
    return
  end
  
  frac_h = frac_y2 - frac_y1;
  frac_w = frac_x2 - frac_x1;
  
  if ( frac_w > frac_h )
    use_frac_h = roi_area_ratio / frac_w;
    use_frac_w = frac_w;
  else
    use_frac_w = roi_area_ratio / frac_h;
    use_frac_h = frac_h;
  end
  
  start_x = x1;
  stop_x = start_x + ref_w * use_frac_w;
  
  start_y = y1;
  stop_y = start_y + ref_h * use_frac_h;
  
  new_w = stop_x - start_x;
  new_h = stop_y - start_y;
  
  rectangle_position = [ start_x, start_y, new_w, new_h ];
  
  crop_rects.roi = [ start_x, start_y, stop_x, stop_y ];
  crop_rectangle_handles.roi = rectangle( 'position', rectangle_position );
  
  crop_rectangle_handles.roi.LineWidth = 3;
  crop_rectangle_handles.roi.EdgeColor = [ 1, 0, 0 ]; % red.
  
  has_cropping_rects.roi = true;
end

function create_image_cropping_rectangle_from_crop_coordinates()
  if ( ~isempty(crop_rectangle_handles.image) && isvalid(crop_rectangle_handles.image) )
    delete( crop_rectangle_handles.image );
  end
  
  % Invalidate the roi rect.
  clear_cropping_rect( 'roi' );
  
  [x1, x2, y1, y2] = decompose_crop_coordinages_ensuring_ascend_ordering( crop_coordinates.image );
  
  crop_w = x2 - x1;
  crop_h = y2 - y1;
  
  if ( crop_h > crop_w )
    start_x = mean( crop_coordinates.image(1, :) );
    start_y = min( crop_coordinates.image(2, :) );
    
    new_w = crop_h * aspect_ratio;
    
    stop_x = start_x + new_w;
    stop_y = start_y + crop_h;
    
    rectangle_position = [ start_x, start_y, new_w, crop_h ];
  else
    start_x = min( crop_coordinates.image(1, :) );
    start_y = mean( crop_coordinates.image(2, :) );
    
    new_h = crop_w / aspect_ratio;
    
    stop_x = start_x + crop_w;
    stop_y = start_y + new_h;
    
    rectangle_position = [ start_x, start_y, crop_w, new_h ];
  end
  
  crop_rects.image = [ start_x, start_y, stop_x, stop_y ];
  crop_rectangle_handles.image = rectangle( 'position', rectangle_position );
  
  crop_rectangle_handles.image.LineWidth = 3;
  crop_rectangle_handles.image.EdgeColor = ones( 1, 3 );
  
  has_cropping_rects.image = true;
end

function load_image(varargin)
  [filename, path] = uigetfile( get_image_extension_str(), 'Open an image.' );

  if ( ~ischar(filename) )
    return
  end

  try
    image_matrix = imread( fullfile(path, filename) );   
    image_matrix = resize_image_to_aspect_ratio( image_matrix, aspect_ratio );
    
    clear_all_cropping_rects();
    stop_dragging_all();
  catch err
    warning( 'Failed to read file "%s": \n %s', filename, err.message );
  end
end

function load_and_recreate(varargin)
  
  load_image();
  make_gui();
  
end

function save_image(src, event)
  
  if ( ~has_cropping_rects.roi )
    error( 'No roi has been established.' );
  end
  
  [filename, path] = uiputfile( '*.png', 'Save' );
  
  if ( ~ischar(filename) )
    return
  end
  
  apply_cropping();
  apply_final_resizing();
  
  cropping_rect = crop_rects.image;
  eye_cropping_rect = crop_rects.roi;
  face_cropping_rect = crop_rects.image;
  
  try
    imwrite( image_matrix, fullfile(path, filename), 'png' );
    save( fullfile(path, strrep(filename, '.png', '.mat')) ...
      , 'cropping_rect', 'eye_cropping_rect', 'face_cropping_rect' );
  catch err
    warning( 'Failed to write file "%s": %s.', filename, err.message );
  end
end

function start_dragging(kind)
  is_dragging.(kind) = true;
  is_first_drag.(kind) = true;
end

function stop_dragging(kind)
  is_dragging.(kind) = false;      
  increment_and_get_mouse_click_index( true );
end

function stop_dragging_all()
  is_dragging = structfun( @(x) false, is_dragging, 'un', 0 );
  increment_and_get_mouse_click_index( true );
end

end

function [x1, x2, y1, y2] = decompose_crop_coordinages_ensuring_ascend_ordering(coords)

x1 = coords(1, 1);
x2 = coords(1, 2);

y1 = coords(2, 1);
y2 = coords(2, 2);

if ( x2 < x1 )
  tmp = x2;
  x2 = x1;
  x1 = tmp;
end

if ( y2 < y1 )
  tmp = y2;
  y2 = y1;
  y1 = tmp;
end

end

function tf = coordinate_in_rect(coord, rect)

x = coord(1);
y = coord(2);

tf = x >= rect(1) && x <= rect(3) && y >= rect(2) && y <= rect(4);

end

function idx = increment_and_get_mouse_click_index(set_to_end)

if ( nargin < 1 )
  set_to_end = false;
end

persistent out_idx;

if ( isempty(out_idx) )
  out_idx = 1;
end

if ( set_to_end )
  out_idx = 2;
end

if ( out_idx > 2 )
  out_idx = 1;
end

idx = out_idx;

out_idx = out_idx + 1;

end

function image_matrix = resize_image_to_aspect_ratio(image_matrix, ar)

im_size = size( image_matrix );

w = im_size(2);
h = im_size(1);

new_h = w / ar;

if ( new_h > h )
  new_h = h;
  new_w = max( round(h * ar), 1 );
else
  new_w = w;
  new_h = round( new_h );
end

image_matrix = imresize( image_matrix, [new_h, new_w] );

end

function coords = create_crop_coordinates()
coords = zeros( 2, 2 );
end

function defaults = get_defaults()

defaults = struct();
defaults.image_matrix = [];

end

function str = get_image_extension_str()

str = '*.png;*.jpg;*.JPG';

end

function v = clamp(v, min, max)

if ( v < min )
  v = min;
elseif ( v > max )
  v = max;
end

end