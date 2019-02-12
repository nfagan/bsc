function id = stim_protocol_name_to_id(name)

validateattributes( name, {'char'}, {}, mfilename, 'protocol name' );

name = name(:)';

ids = brains.arduino.calino.get_ids();
protocols = ids.stim_protocols;

assert( isfield(protocols, name) ...
  , '"%s" is not a valid protocol name; options are: \n\n - %s' ...
  , name, strjoin(fieldnames(protocols), '\n - ') );

id = protocols.(name);

end