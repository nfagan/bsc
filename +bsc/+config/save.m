
function save(conf)

%   SAVE -- Save the config file.

bsc.util.assertions.assert__is_config( conf );
const = bsc.config.constants();
fprintf( '\n bsc: Config file saved\n\n' );
save( fullfile(const.config_folder, const.config_filename), 'conf' );

end