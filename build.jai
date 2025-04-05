#import "Basic";
#import "String";
#import "File";
#import "File_Utilities";
#import "Compiler";
#import "Process";


#run {
    set_build_options_dc(.{do_output=false});

    main_workspace := compiler_create_workspace(path_filename(trim(#filepath, "/")));

    build_options := get_build_options();

    new_path: [..] string;
    array_add(*new_path, ..build_options.import_path);
    array_add(*new_path, "engine");
    build_options.import_path = new_path;

    #if #exists(JAILS_DIAGNOSTICS_BUILD) build_options.output_type = .NO_OUTPUT;

    build_options.backend =.X64;
    set_optimization(*build_options, .DEBUG);
    build_options.array_bounds_check = .ON;

    args := build_options.compile_time_command_line;
    for arg : args {
        if arg == "release" {
            build_options.backend = .LLVM;
            set_optimization(*build_options, Optimization_Type.VERY_OPTIMIZED);
        } else {
            print("Unknown argument: %\n", arg);
        }
    }

    build_options.output_type = .EXECUTABLE;
    build_options.output_executable_name = path_filename(trim(#filepath, "/"));
    build_options.output_path = join(#filepath, "bin/");
	make_directory_if_it_does_not_exist(build_options.output_path);

    set_build_options(build_options, main_workspace);

    add_build_file("main.jai", main_workspace);
}