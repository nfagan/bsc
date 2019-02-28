function bsc_luminance_match_images(input_p, output_p)

image_files = shared_utils.io.find( input_p, '.png', true );
images = cellfun( @imread, image_files, 'un', 0 );

matched_images = shine_rgb_match( images );

for i = 1:numel(image_files)
  fprintf( '\n Saving %d of %d', i, numel(image_files) );
  
  output_filename = strrep( image_files{i}, input_p, output_p );
  output_dir = fileparts( output_filename );
  
  shared_utils.io.require_dir( output_dir );
  
  imwrite( matched_images{i}, output_filename );
  
  src_roi_mat_file = strrep( image_files{i}, '.png', '.mat' );
  
  % Copy roi files to destination.
  if ( shared_utils.io.fexists(src_roi_mat_file) )
    dest_roi_mat_file = strrep( output_filename, '.png', '.mat' );
    copyfile( src_roi_mat_file, dest_roi_mat_file );
  else
    warning( 'Missing roi file for luminance matched image: "%s".', output_filename );
  end
end

end