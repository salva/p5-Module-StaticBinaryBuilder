use Module::Build;

Module::Build
    -> new( module_name => 'Module::StaticBinaryBuilder',
            license     => 'perl' )
    -> create_build_script;
