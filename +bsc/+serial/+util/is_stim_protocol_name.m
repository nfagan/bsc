function tf = is_stim_protocol_name(name)

ids = brains.arduino.calino.get_ids();
tf = ischar( name ) && isfield( ids.stim_protocols, name(:)' );

end