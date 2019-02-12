function bsc_make_cropped_images(input_p, output_p, stim_rect)

image_files = shared_utils.io.find( input_p, '.png', true );
image_rois = cell( size(image_files) );
images = cell( size(image_files) );

no_use = shared_utils.cell.contains( images, 'Non-social' );

for i = 1:numel(image_files)
  image_file = image_files{i};
  
  try
    image_rois{i} = load( fullfile(fileparts(image_file) ...
      , sprintf('%s.mat', shared_utils.io.filenames(image_file))) );
    
    images{i} = imread( image_file );
  catch err
    warning( err.message );    
    no_use(i) = true;
  end
end

image_files(no_use) = [];
image_rois(no_use) = [];
images(no_use) = [];

[cropped_images, cropped_rois] = bsc.util.match_image_sizes( images, image_rois, stim_rect );

for i = 1:numel(cropped_images)
  shared_utils.general.progress( i, numel(cropped_images) );
  
  source_file = image_files{i};
  roi_filename = sprintf( '%s.mat', shared_utils.io.filenames(source_file) );
  
  i_stim_p = strfind( source_file, input_p );
  assert( i_stim_p == 1 );
  
  source_file(1:numel(input_p)) = [];
  
  sub_p = fullfile( output_p, fileparts(source_file) );
  shared_utils.io.require_dir( sub_p );
  
  dest_file = fullfile( output_p, source_file );
  roi_file = fullfile( sub_p, roi_filename );
  
  cropped_roi = cropped_rois{i};
  
  imwrite( cropped_images{i}, dest_file );
  save( roi_file, '-struct', 'cropped_roi' );
end

end
