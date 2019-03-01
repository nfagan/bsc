function mark_event(data, name)

%   MARK_EVENT -- Add event time to current trial data.

current_time = elapsed( data.Value.TASK );
data.Value.CURRENT_TRIAL_DATA.events.(name) = current_time;

end