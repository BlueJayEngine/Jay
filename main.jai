#import "Basic"()(MEMORY_DEBUGGER = true);
#import "Jay_Core";
#import "Jay_Render";
#import "Jay_Logger";

Test :: struct {
    foo: string;
    bar: Test_Child; 
    fizz: float;
    buzz: int;

    test_func :: () {
        return;
    }
}

Test_Child :: struct {
    big: float64;
    smol: s8;
}

main :: () {
    test_example: Test;


    test_example = .{
        foo = "",
        bar = .{
            
        },
    };

    test_example.bar = .{
                
    };
    
    context.logger = jay_logger; 

    engine: Engine(
        Packages(
            Jay_Render
        )
    );

    run(*engine);

    report_memory_leaks();
}
