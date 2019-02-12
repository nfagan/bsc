function log(msg, data, tag, add_newline)

%   LOG -- Conditionally log messages, depending on the debug status and
%     allowed debug tags.
%
%     bsc.task.log( msg, data, tag ); logs the character vector `msg`, so
%     long as the task is in debug mode, and `tag` is one of the current
%     allowed debug tags. The mode of the task and allowed debug tags are
%     given by the structure subfield of `data`.
%
%     bsc.task.log( ..., add_newline ); indicates whether to prepend a
%     newline character before the message. Default is true.

provided_tag = nargin > 2;

if ( ~provided_tag ), tag = ''; end
if ( nargin < 4 ), add_newline = true; end

structure = data.Value.STRUCTURE;

is_debug = structure.is_debug;
debug_tags = cellstr( structure.debug_tags );

if ( ~is_debug )
  return
end

try
  cond_a = ~provided_tag;
  cond_b = numel( debug_tags ) == 1 && strcmp( debug_tags, 'all' );
  cond_c = ismember( tag, debug_tags );
  
  if ( cond_a || cond_b || cond_c )
    if ( add_newline )
      fprintf( '\n %s', msg );
    else
      fprintf( '%s', msg );
    end
  end
catch err
  warning( err.message );
end

end