function a = match(a, b)

if ( nargin < 1 || isempty(a) )
  a = bsc.config.load();
end

if ( nargin < 2 || isempty(b) )
  b = bsc.config.create( false );
end

a = bsc.config.prune( bsc.config.reconcile(a, b), b );

end