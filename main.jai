#import "Basic"()(MEMORY_DEBUGGER = true);
#import "Jay_Core";
#import "Jay_ECS";
#import "Jay_Render";

main :: () {
    engine: Engine(Packages(
        Jay_ECS(
            System(test, xx Game_Stage_Temp.TICK),
            // System(test2)
        ),
        Jay_Render,
        Test,
        Test2
    ));

    run(*engine);
}

Test :: struct {
    after: Lifecycle.Simulation; 
}

Test2 :: struct {
    before: Lifecycle.Render;
}

test :: (delta_time: Delta_Time) {
    log("% - %", delta_time, 1/delta_time);
}


