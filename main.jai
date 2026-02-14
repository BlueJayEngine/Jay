#import "Jay_Core";
#import "Jay_Render";
#import "Basic"()(MEMORY_DEBUGGER=true);

main :: () {
    context.logger = cli_logger;

    engine: Engine(
        Packages(Jay_Render, Jay_Logger_CLI),
    );
    
    run(*engine);
}
