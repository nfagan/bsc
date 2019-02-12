function [bounds, keys, key_map, padding_cm, consts] = get_bounds_and_far_plane_calibration_or_default()

import brains.arduino.calino.bound_funcs.both_eyes;
import brains.arduino.calino.bound_funcs.face_top_and_bottom;
import brains.arduino.calino.bound_funcs.social_control_dots_left;

key_file = [];

try
  key_file = brains.util.get_latest_far_plane_calibration( [], false );
catch err
  warning( err.message );
end

padding_cm = brains.arduino.calino.define_padding();
consts = brains.arduino.calino.define_calibration_target_constants();

padding_cm.eyes.x = 2.75;
padding_cm.eyes.y = 2.75;
padding_cm.face.x = 0;
padding_cm.face.y = 0;
padding_cm.mouth.x = 0;
padding_cm.mouth.y = 0;

if ( ~isempty(key_file) )
  keys = brains.arduino.calino.convert_key_struct( key_file.keys, key_file.key_map );
  key_map = key_file.key_name_map;

  bounds = struct();
  bounds.eyes = both_eyes( keys, key_map, padding_cm, consts );
  bounds.face = face_top_and_bottom( keys, key_map, padding_cm, consts );
  bounds.mouth = zeros( 1, 4 );
  bounds.social_control_dots_left = social_control_dots_left( keys, key_map, padding_cm, consts );
else
  keys = [];
  key_map = [];
  bounds = struct();
end

end