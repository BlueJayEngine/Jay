#import "Basic";
#import "String";
#import "File";
#import "File_Utilities";
#import "Compiler";
#import "Process";
#import "Metaprogram_Plugins";

#run {
    set_build_options_dc(.{ do_output = false });

    main_workspace := compiler_create_workspace(path_filename(trim(#filepath, "/")));

    build_options := get_build_options();

    new_path: [..]string;
    array_add(*new_path, ..build_options.import_path);
    array_add(*new_path, "engine");
    build_options.import_path = new_path;

    #if #exists(JAILS_DIAGNOSTICS_BUILD) build_options.output_type = .NO_OUTPUT;

    build_options.backend = .X64;
    set_optimization(*build_options, .DEBUG);
    build_options.array_bounds_check = .ON;

    args := build_options.compile_time_command_line;
    success: bool;

    plugins_to_create: [..]Plugin_To_Create;

    success, plugins_to_create, args = parse_plugin_arguments(args);
    if !success {
        log_error("Failed to parse plugin arguments.\n");
        exit(1);
    }

    for arg: args {
        if arg == "opt" { 
         build_options.backend = .LLVM;
            set_optimization(*build_options, Optimization_Type.VERY_OPTIMIZED, true);
        } else if arg == "release" {
            build_options.backend = .LLVM;
            set_optimization(*build_options, Optimization_Type.OPTIMIZED_VERY_SMALL, false);
        }
        else {
            print("Unknown argument: %\n", arg);
        }
    }

    build_options.output_type = .EXECUTABLE;
    build_options.output_executable_name = path_filename(trim(#filepath, "/"));
    build_options.output_path = join(#filepath, "bin/");
    make_directory_if_it_does_not_exist(build_options.output_path);

    build_options.compile_time_command_line = args;

    plugins: [..]*Metaprogram_Plugin;
    success = init_plugins(plugins_to_create, *plugins, main_workspace);
    if !success {
        log_error("A plugin init() failed. Exiting.\n");
        exit(1);
    }

    set_build_options(build_options, main_workspace);

    intercept_flags: Intercept_Flags;
    for plugins if it.before_intercept it.before_intercept(it, *intercept_flags);

    compiler_begin_intercept(main_workspace, intercept_flags);

    for plugins if it.add_source it.add_source(it);
    add_build_file("main.jai", main_workspace);

    message_loop(plugins);

    compiler_end_intercept(main_workspace);

    for plugins if it.finish it.finish(it);
    for plugins if it.shutdown it.shutdown(it);
}

message_loop :: (plugins: []*Metaprogram_Plugin) {
    while true {
        message := compiler_wait_for_message();
        for plugins if it.message it.message(it, message);
        if message.kind == .COMPLETE break;
    }
}
