function name = check_active_roi_names(name)

if ( iscell(name) )
  name = cellfun( @validator, name, 'un', 0 );
else
  name = validator( name );
end

end

function name = validator(name)

name = validatestring( name, {'eyes', 'face', 'mouth'}, mfilename, 'active roi name' );

end