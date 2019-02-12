meas = struct();
meas.inter_eye_dist_cm = 4;
%meas.face_width_cm = 12.4;
meas.face_width_cm = 14.2;
%meas.face_height_cm = 11.2;
meas.face_height_cm = 13.1;
%meas.face_top_to_eye_center_cm = 3.4;
meas.face_top_to_eye_center_cm = 4.1;
%meas.face_left_to_eye_center_cm = 6.2;
meas.face_left_to_eye_center_cm = 7.1;

% cropping_rect = shared_utils.io.fload( '/Users/Nick/Desktop/test2.mat' );
cropping_rect = [];

bsc_image_crop_tool( ...
    'far_plane_measurements', meas ...
    , 'padding', [500, 500] ...
);