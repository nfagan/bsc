function [success, msg] = activate_stim(stim_comm, for_roi)

[success, msg] = bsc.serial.private.activate_deactive_stim( stim_comm, for_roi, 1 );

end