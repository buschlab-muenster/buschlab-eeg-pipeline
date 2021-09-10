function do_protect = protect_from_overwrite(the_fullfile, do_overwrite)

do_protect = exist(the_fullfile, 'file') & ...
    do_overwrite == false;

end