reference_eye_coord_file = '/Users/Nick/Documents/MATLAB/repositories/bsc/stimuli/images/Ephron/right/ephron_right_01.mat';
reference_eye_coords = load( reference_eye_coord_file );

area_from_rect = @(x) (x(3)-x(1)) * (x(4)-x(2));

image_rect = reference_eye_coords.cropping_rect;
eye_rect = reference_eye_coords.eye_cropping_rect;

w = image_rect(3) - image_rect(1);
h = image_rect(4) - image_rect(2);

area_ratio = area_from_rect(eye_rect) / area_from_rect(image_rect);

im = imread( '/Users/Nick/Documents/MATLAB/repositories/bsc/stimuli/__images/Non-social/non_social_control_02.jpg' );
% im = imread( '/Users/Nick/Documents/MATLAB/repositories/bsc/stimuli/__images/Non-social/non_social_control_14.jpg' );

bsc_social_image_crop_tool( [w, h], area_ratio ...
  , 'image_matrix', im );

%%

test_p = '/Users/Nick/Desktop';
test_file = 'test';

test_img = imread( fullfile(test_p, sprintf('%s.png', test_file)) );
test_coord_file = load( fullfile(test_p, sprintf('%s.mat', test_file)) );

figure(1); clf();
imshow( test_img ); hold on;

test_rect = test_coord_file.eye_cropping_rect;

r = rectangle( 'position', [test_rect(1), test_rect(2) ...
  , test_rect(3)-test_rect(1), test_rect(4)-test_rect(2)] );
r.LineWidth = 4;
r.EdgeColor = [ 1, 0, 0];