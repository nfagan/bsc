function bounds = make_default_stim_bounds()

bounds = struct();

bounds.screen = zeros( 1, 4 );
bounds.eyes = repmat( -1, 1, 4 );
bounds.face = repmat( -1, 1, 4 );
bounds.mouth = repmat( -1, 1, 4 );

end