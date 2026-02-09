#import "Jay_Core";
#import "Jay_Render";
#import "Basic"()(MEMORY_DEBUGGER=true);

main :: () {
    engine: Engine(
        Packages(Jay_Render),
    );
    
    run(*engine);
}
