function a = prune(a, b)

%   PRUNE -- Remove extraneous fields.
%
%     bsc.config.prune( conf ) removes fields of `conf` that are not
%     present in the config file that would be created in a call to
%     `bsc.config.create()`. For nested structs, only the nested extraneous
%     fields are removed.
%
%     bsc.config.prune(), with no inputs, or bsc.config.prune([]), uses the
%     saved config file.
%
%     bsc.config.prune( ..., compare_with ); removes fields of `conf` not
%     present in `compare_with`.
%
%     See also bsc.config.reconcile

if ( nargin < 1 || isempty(a) )
  a = bsc.config.load();
end

if ( nargin < 2 || isempty(b) )
  b = bsc.config.create( false ); % don't save
end

extraneous = bsc.config.diff( b, false, a );

for i = 1:numel(extraneous)
  split = strsplit( extraneous{i}, '.' );
  
  sub_struct = strjoin( split(1:end-1), '.' );
  field_name = split{end};
  
  cmd = sprintf( 'a%s = rmfield(a%s, ''%s'');' ...
    , sub_struct, sub_struct, field_name );
  
  eval( cmd );
end

end