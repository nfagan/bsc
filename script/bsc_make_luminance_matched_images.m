function bsc_make_luminance_matched_images(input_p, output_p)

if ( nargin < 1 )
  input_p = fullfile( bsc.util.get_project_folder(), 'stimuli', 'images' );
end

if ( nargin < 2 )
  output_p = fullfile( bsc.util.get_project_folder(), 'stimuli', 'lum-matched-images' );
end

bsc_luminance_match_images( input_p, output_p );

end