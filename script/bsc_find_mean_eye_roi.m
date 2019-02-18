runner = bfw.get_looped_make_runner();
runner.convert_to_non_saving_with_output();

runner.input_directories = bfw.gid( {'meta', 'rois', 'single_origin_offsets'} );

res = runner.run( @(x) x );

%%
outputs = { res([res.success]).output };

eye_rois = zeros( numel(outputs), 4 );
eye_roi_labs = fcat();

for i = 1:numel(outputs)
  meta_file = outputs{i}('meta');
  roi_file = outputs{i}('rois');
  offsets_file = outputs{i}('single_origin_offsets');
  
  m1_offset = offsets_file.m1;
  
  eye_roi = roi_file.m1.rects('eyes_nf');
  eye_roi([1, 3]) = eye_roi([1, 3]) + m1_offset(1);
  eye_roi([2, 4]) = eye_roi([2, 4]) + m1_offset(2);
  
  eye_rois(i, :) = eye_roi;
  
  append( eye_roi_labs, bfw.struct2fcat(meta_file) );
end

%%

ignore_sessions = { '04202018', '04242018', '04252018' };

I = findnone( eye_roi_labs, ignore_sessions );

use_eye_rois = eye_rois(I, :);
eye_xs = use_eye_rois(:, 1);
eye_ys = use_eye_rois(:, 2);
eye_max_xs = use_eye_rois(:, 3);
eye_max_ys = use_eye_rois(:, 4);

assert( min(eye_xs) > 1e3 & max(eye_xs) < 2e3 );

eye_rect = mean( use_eye_rois, 1 );

tmp_eye_rect = eye_rect;
tmp_eye_rect([1, 3]) = tmp_eye_rect([1, 3]) - 1024;

mean_w = mean( eye_max_xs - eye_xs );
mean_h = mean( eye_max_ys - eye_ys );

