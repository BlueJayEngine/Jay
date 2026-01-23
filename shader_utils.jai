#import "Basic"()(MEMORY_DEBUGGER = true);
#import "Jay_Core";
#import "Jay_Render";
#import "Jay_Logger";

#import "Slang";


main :: () {
    shader_in :: #run sprint("%/assets/shaders/%", get_working_directory(), "test.slang");

    session_desc: SessionDesc;
    target_desc: TargetDesc;

    global_session: *IGlobalSession;

    slang_createGlobalSession(SLANG_API_VERSION, *global_session);

    target_desc.format = .SLANG_SPIRV;
    target_desc.profile = IGlobalSession_findProfile(global_session, to_c_string("spirv_1_5"));

    session_desc.targets = *target_desc;
    session_desc.targetCount = 1;


    options: [..]CompilerOptionEntry;
    array_add(*options, .{
        CompilerOptionName.EmitSpirvDirectly, .{
            CompilerOptionValueKind.Int, 1, 0, null ,null
        }
    });
    session_desc.compilerOptionEntries = options.data;
    session_desc.compilerOptionEntryCount = cast(u32)options.count;
    
    session: *ISession;
    IGlobalSession_createSession(global_session, *session_desc, *session);

    slang_module := ISession_loadModule(session, shader_in.data);
    
    log("Finding entry point");
    entry_point_v: *IEntryPoint;
    IModule_findEntryPointByName(slang_module, to_c_string("vertMain"), *entry_point_v);

    entry_point_f: *IEntryPoint;
    IModule_findEntryPointByName(slang_module, to_c_string("fragMain"), *entry_point_f);


    component_types: [..]*IComponentType;
    array_add(*component_types, slang_module);
    array_add(*component_types, entry_point_v);
    array_add(*component_types, entry_point_f);

    log("Creating composed program");

    diagnostic_blob: *IBlob;
    composed_program: *IComponentType;
    ISession_createCompositeComponentType(session, component_types.data, component_types.count, *composed_program, *diagnostic_blob);
    log("Done!");

    layout : *ProgramLayout = IComponentType_getLayout(composed_program);
    
    print_layout(layout);
}


print_layout :: (layout: *ProgramLayout) {
    print_global(spReflection_getGlobalParamsVarLayout(xx layout));
    
}

print_global :: (var_layout: *SlangReflectionVariableLayout) {

    type_layout := spReflectionVariableLayout_GetTypeLayout(xx var_layout);
    
    t_kind := spReflectionTypeLayout_getKind(type_layout);    
    // assert(t_kind == .STRUCT, "type layout is not STRUCT, its %", t_kind);

    param_count := spReflectionTypeLayout_GetFieldCount(type_layout);
    

    log("params(%):", param_count);

    for 0..param_count-1 {
        var := spReflectionTypeLayout_GetFieldByIndex(type_layout, it);
        print_var(spReflectionVariableLayout_GetVariable(var));
        
    }
}

print_var :: (var: *SlangReflectionVariable, prefix: string = "") {

    print(prefix);
    print(to_string(spReflectionVariable_GetName(var)));
    
    type := spReflectionVariable_GetType(var);
    type_kind := spReflectionType_GetKind(type);
    type_name := spReflectionType_GetName(type);

    print(" : %", to_string(type_name));

    if type_kind == {
        case .STRUCT; {
                log(" {");
                    filed_count := spReflectionType_GetFieldCount(type);
                    for 0..filed_count-1 {
                        field:= spReflectionType_GetFieldByIndex(type, it);
                        print_var(field, sprint("%\t", prefix));
                    } 
                print("}");
            }
        case .SCALAR; {
            print("%", spReflectionType_GetScalarType(type));
        }
        case .NONE; { print("(NONE WTF?)"); }
        case; { 
            print("(Unknown kind: %)", type_kind); 
        }
    }

    print("\n");

}
