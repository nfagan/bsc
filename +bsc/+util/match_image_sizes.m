function [cropped_images, new_rois] = match_image_sizes(images, image_rois, stim_rect)

stim_rect = round( bring_rect_to_origin(stim_rect) );

validateattributes( images, {'cell'}, {'vector'}, mfilename, 'images' );
validateattributes( image_rois, {'cell'}, {'vector', 'numel', numel(images)} ...
  , mfilename, 'image rois' );
validateattributes( stim_rect, {'double'}, {'vector', 'numel', 4} ...
  , mfilename, 'target rect' );

new_eye_rects = nan( numel(images), 4 );
distances = nan( numel(images), 4 );
new_images = cell( size(images) );

for i = 1:numel(images)
  img = images{i};
  img_roi = image_rois{i};
  
  crop_rect = img_roi.cropping_rect;
  roi_rect = img_roi.eye_cropping_rect;
  
  % Ensure cropping rect matches image dimensions
  validate_crop_rect( img, crop_rect );
  
  new_rect = convert_stim_rect_to_image_rect( crop_rect, roi_rect, stim_rect );
  distances(i, :) = get_distances( new_rect, stim_rect );
  
  round_rect = round( bring_rect_to_origin(new_rect) );
  
  new_images{i} = imresize( img, [round_rect(4), round_rect(3)] );
  
  adjust_eye_rect = stim_rect;
  adjust_eye_rect([1, 3]) = adjust_eye_rect([1, 3]) + abs(new_rect(1));
  adjust_eye_rect([2, 4]) = adjust_eye_rect([2, 4]) + abs(new_rect(2));
  
  new_eye_rects(i, :) = round( adjust_eye_rect );
end

mins = floor( min(distances, [], 1) );

cropped_images = cell( size(new_images) );
new_rois = cell( size(new_images) );

adjusted_eye_rect = [ mins(1), mins(2), mins(1)+stim_rect(3), mins(2)+stim_rect(4) ];

for i = 1:numel(new_images)  
  new_eye_rect = new_eye_rects(i, :);  
  
  begin_x = new_eye_rect(1) - mins(1) + 1;
  begin_y = new_eye_rect(2) - mins(2) + 1;
  stop_x = new_eye_rect(3) + mins(3);
  stop_y = new_eye_rect(4) + mins(4);
  
  cropped_images{i} = new_images{i}(begin_y:stop_y, begin_x:stop_x, :);
  
  new_width = stop_x - begin_x + 1;
  new_height = stop_y - begin_y + 1;
  
  if ( i > 1 && (new_width ~= last_width || new_height ~= last_height) )
    error( 'Sizes did not match across images.' );
  end
  
  new_roi = struct();
  new_roi.cropping_rect = [1, 1, new_width, new_height];
  new_roi.eye_cropping_rect = adjusted_eye_rect;

  new_rois{i} = new_roi;
  
  last_width = new_width;
  last_height = new_height;
end

end

function rect = bring_rect_to_origin(r)

rect = [ 0, 0, r(3)-r(1), r(4)-r(2) ];

end

function dist = get_distances(image_rect, stim_rect)

dist = zeros( 1, 4 );
dist(1:2) = stim_rect(1:2) - image_rect(1:2);
dist(3:4) = image_rect(3:4) - stim_rect(3:4);

end

function new_image_rect = convert_stim_rect_to_image_rect(crop_rect, roi_rect, stim_rect)

target_width = stim_rect(3) - stim_rect(1);
target_height = stim_rect(4) - stim_rect(2);
target_x_offset = stim_rect(1);
target_y_offset = stim_rect(2);

make_width = @(r) r(3) - r(1);
make_height = @(r) r(4) - r(2);

origin_referenced_eye = bring_rect_to_origin( roi_rect );
origin_referenced_crop = bring_rect_to_origin( crop_rect );

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

end

function validate_crop_rect(img, crop_rect)

img_height = size( img, 1 );
img_width = size( img, 2 );

rect_w = crop_rect(3) - crop_rect(1);
rect_h = crop_rect(4) - crop_rect(2);

assert( img_height == rect_h + 1, 'Heights do not match.' );
assert( img_width == rect_w + 1, 'Heights do not match.' );

end
