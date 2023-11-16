@testitem "ManualClock" begin
    import RxEnvironments:
        ManualClock, elapsed_time, add_elapsed_time!, set_last_update!, start_time

    clock = ManualClock()

    @test time(clock) === 0.0
    @test start_time(clock) === 0.0
    @test_throws ErrorException elapsed_time(clock)

    add_elapsed_time!(clock, 1.0)

    @test time(clock) === 1.0
    @test time(clock) > start_time(clock)
    @test_throws ErrorException add_elapsed_time!(clock, -1)

    set_last_update!(clock, 2.0)

    @test time(clock) === 2.0
end

@testitem "WallClock" begin
    import RxEnvironments: WallClock, elapsed_time, add_elapsed_time!, set_last_update!

    for real_time_factor ∈ [0.25, 0.5, 1, 2, 5, 10]
        clock = WallClock(real_time_factor)
        @test isapprox(time(clock), 0.0; atol = 1e-3)
        sleep(0.1)
        @test 0.2 / real_time_factor > time(clock) > 0.1 / real_time_factor
        set_last_update!(clock, time(clock))
        @test time(clock) > elapsed_time(clock)
    end
end

@testitem "TimerActor" begin
    import RxEnvironments: TimerActor, create_entity, entity
    include("mockenvironment.jl")

    rxentity = create_entity(MockEntity())
    actor = TimerActor(rxentity)
    @test entity(actor) === rxentity
end

@testitem "Timer" begin
    import RxEnvironments: Timer, create_entity, subscribe_to_observations!
    using Rocket
    include("mockenvironment.jl")

    rxentity = create_entity(MockEntity())
    log = keep(Any)
    subscribe_to_observations!(rxentity, log)
    timer = Timer(10, rxentity)
    for _ = 1:10
        prev_len = length(log.values)
        sleep(0.1)
        @test length(log.values) > prev_len
    end

end
