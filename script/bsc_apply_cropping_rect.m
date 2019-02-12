function images = bsc_apply_cropping_rect(images, cropping_rect)

if ( ~iscell(images) )
  images = apply_cropping_rect( images, cropping_rect );
else
  images = cellfun( @(x) apply_cropping_rect(x, cropping_rect), images, 'un', 0 );
end

end

function image = apply_cropping_rect(image, cropping_rect)

min_x = cropping_rect(1);
max_x = cropping_rect(3);

min_y = cropping_rect(2);
max_y = cropping_rect(4);

image = image(min_y:max_y, min_x:max_x, :);

end