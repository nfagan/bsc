
  function a = reconcile(a, b)

%   RECONCILE -- Add missing fields to config file.
%
%     conf = ... reconcile() loads the current config file and checks for
%     missing fields, that is, fields that are present in the config file
%     that would be generated by ... .config.create(), but which are not
%     present in the saved config file. Any missing fields are set to the
%     contents of the corresponding fields as defined in ...
%     .config.create().
%
%     conf = ... reconcile( conf ) uses the config file `conf`, instead of
%     the saved config file.
%
%     conf = ... reconcile( ..., compare_with ); checks for missing fields
%     against `compare_with`, instead of the default config file.
%
%     See also bsc.config.prune

if ( nargin < 1 )
  a = bsc.config.load();
end

if ( nargin < 2 )
  b = bsc.config.create( false );
end

display = false;
missing = bsc.config.diff( a, display, b );

if ( isempty(missing) )
  return;
end

for i = 1:numel(missing)
  current = missing{i};
  eval( sprintf('a%s = b%s;', current, current) );
end

end