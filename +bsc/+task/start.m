function start(varargin)

data = bsc.task.setup( varargin{:} );
bsc.task.run( data );

end