classdef FileSet < handle
  
  properties (Access = private)
    all_identifiers;
    used_identifiers;
  end
  
  properties (SetAccess = private, GetAccess = public)
    IsFinalized;
  end
  
  methods
    function obj = FileSet(identifiers)
      obj.all_identifiers = {};
      obj.used_identifiers = {};
      obj.IsFinalized = false;
      
      if ( nargin == 1 )
        identifiers = cellstr( identifiers );
        
        for i = 1:numel(identifiers)
          add_identifier( obj, identifiers{i} );
        end
        
        finalize( obj );
      end
    end
  end
  
  methods (Access = public)
    function add_identifier(obj, id)
      validateattributes( id, {'char'}, {}, mfilename, 'identifier' );
      obj.all_identifiers{end+1, 1} = id;
    end
    
    function id = get_next_identifier(obj)      
      if ( ~obj.IsFinalized )
        error( 'Call finalize() before requesting an id.' );
      end
      
      remaining_ids = setdiff( obj.all_identifiers, obj.used_identifiers );
      
      if ( isempty(remaining_ids) )
        obj.used_identifiers = {};

        id = get_next_identifier( obj );
      else
        used_id_index = randi( numel(remaining_ids) );
        
        id = remaining_ids{used_id_index};
        
        obj.used_identifiers{end+1, 1} = id;
      end
    end
    
    function finalize(obj)
      n_ids = numel( obj.all_identifiers );
      permuted_index = randperm( n_ids );
      obj.all_identifiers = obj.all_identifiers(permuted_index);
      obj.IsFinalized = true;
    end
  end
  
end