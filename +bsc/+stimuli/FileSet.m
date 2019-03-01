classdef FileSet < handle
  
  properties (Access = private)
    all_identifiers;
    used_identifiers;
  end
  
  properties (Access = public)
    
    %   ISUNIQUEIDENTIFIERS -- True if identifiers are made unique.
    %
    %     IsUniqueIdentifiers is a logical scalar indicating whether, when
    %     finalizing the object, to make the added identifiers unique.
    %     Default is true.
    %
    %     See also bsc.stimuli.FileSet, bsc.stimuli.FileSet.finalize
    IsUniqueIdentifiers;
  end
  
  properties (SetAccess = private, GetAccess = public)
    IsFinalized;
  end
  
  methods
    function obj = FileSet(identifiers)
      
      %   FILESET -- Create FileSet instance.
      %
      %     A FileSet object represents a list of filenames (often image
      %     files) that are sampled in a random sequence such that each 
      %     file is returned once. Once all files have been sampled, a new
      %     permutation is computed, and sampling continues.
      %
      %     See also bsc.stimuli.FileSet.add_identifier,
      %       bsc.stimuli.FileSet.finalize,
      %       bsc.stimuli.FileSet.get_next_identifier
      
      obj.all_identifiers = {};
      obj.used_identifiers = {};
      obj.IsUniqueIdentifiers = true;
      obj.IsFinalized = false;
      
      if ( nargin == 1 )
        identifiers = cellstr( identifiers );
        
        for i = 1:numel(identifiers)
          add_identifier( obj, identifiers{i} );
        end
        
        finalize( obj );
      end
    end
    
    function set.IsUniqueIdentifiers(obj, v)
      validateattributes( v, {'logical'}, {'scalar'}, mfilename, 'IsUniqueIdentifiers' );
      obj.IsUniqueIdentifiers = v;
    end
  end
  
  methods (Access = public)
    function add_identifier(obj, id)
      
      %   ADD_IDENTIFIER -- Add identifier to object.
      %
      %     add_identifier( obj, id ) adds the char vector `id` to the list
      %     of to-be-sampled identifiers. It is an error to call this
      %     function after a call to finalize().
      %
      %     See also bsc.stimuli.FileSet.finalize, bsc.stimuli.FileSet
      
      if ( obj.IsFinalized )
        error( 'Cannot add an identifier after finalizing.' );
      end
      
      validateattributes( id, {'char'}, {}, mfilename, 'identifier' );
      obj.all_identifiers{end+1, 1} = id;
    end
    
    function id = get_next_identifier(obj)      
      
      %   GET_NEXT_IDENTIFIER -- Get next identifier, in sequence.
      %
      %     See also bsc.stimuli.FileSet
      
      if ( ~obj.IsFinalized )
        error( 'Call finalize() before requesting an id.' );
      end
      
      if ( isempty(obj.all_identifiers) )
        error( 'No identifiers were added.' );
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
    
    function ids = get_identifiers(obj)
      
      %   GET_IDENTIFIERS -- Get all identifiers in the FileSet.
      %
      %     See also bsc.stimuli.FileSet
      
      ids = obj.all_identifiers;
    end
    
    function finalize(obj)
      
      %   FINALIZE -- Finish adding identifiers to the FileSet.
      %
      %     finalize( obj ); marks that all possible identifiers have been
      %     added, enabling the sampling of identifiers with
      %     `get_next_identifier`.
      %
      %     After calling this function, it is an error to add more 
      %     identifiers.
      %
      %     See also bsc.stimuli.FileSet
      
      if ( obj.IsFinalized )
        return
      end
      
      all_ids = obj.all_identifiers(:);
      
      if ( obj.IsUniqueIdentifiers )
        % Ensure column vector.
        all_ids = unique( all_ids );
      end
      
      n_ids = numel( all_ids );
      permuted_index = randperm( n_ids );
      
      obj.all_identifiers = all_ids(permuted_index);
      obj.IsFinalized = true;
    end
  end
  
end