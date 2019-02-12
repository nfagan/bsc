function comm = get_sync_comm(conf)

%   GET_SYNC_COMM -- Get an instantiated BrainsSerialManagerPaired
%     object.
%
%     OUT:
%       - `comm` (BrainsSerialManagerPaired)

import brains.arduino.BrainsSerialManagerPaired;

if ( nargin < 1 || isempty(conf) )
  conf = bsc.config.load();
end

interface = conf.INTERFACE;

use_arduino = interface.use_arduino;
port = interface.sync_reward_serial_port;
role = 'master';
rwd_channels = { 'B', 'A' };
messages = struct();

comm = BrainsSerialManagerPaired( port, messages, rwd_channels, role );
comm.bypass = ~use_arduino;

end