image_p = '/Users/Nick/Documents/MATLAB/repositories/bfw/data/Cronenberg/edited_side';
out_p = '~/Desktop/';

crop_rect = load( '/Users/Nick/Desktop/test2.mat' );
crop_rect = crop_rect.cropping_rect;

image_filenames = shared_utils.io.find( image_p, '.png' );
images = cellfun( @imread, image_filenames, 'un', 0 );

images = bsc_apply_cropping_rect( images, crop_rect );

[~, image_dirname] = fileparts( image_p );
save_dirname = sprintf( '%s_cropped', image_dirname );
save_p = fullfile( out_p, save_dirname );

for i = 1:numel(images)
  image_file = image_files{i};
  image_filename = shared_utils.io.filenames( image_file );
  image_filename = sprintf( '%s.png', image_filename );
  
  shared_utils.io.require_dir( save_p );
  
  imwrite( images{i}, fullfile(save_p, image_filename) );
end