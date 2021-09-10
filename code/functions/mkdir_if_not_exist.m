function mkdir_if_not_exist(dir_name)

if ~exist(dir_name), 'dir')
    
    fprintf('Creating new directory: %s', dir_name)
    mkdir(dir_name)    
    
else