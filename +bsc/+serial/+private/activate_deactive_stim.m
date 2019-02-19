function [success, msg] = activate_deactive_stim(stim_comm, for_roi, value)

success = true;
msg = '';

if ( isempty(stim_comm) || ~isvalid(stim_comm) )
  return
end

try  
  for_roi = cellstr( for_roi );
  
  for i = 1:numel(for_roi)    
    brains.arduino.calino.send_stim_param( stim_comm, for_roi{i}, 'stim_stop_start', value );
  end
catch err
  success = false;
  msg = err.message;
end

end