
@testitem "Mountain car environment" begin
    using RxEnvironments
    using Rocket

    import RxEnvironments:
        RxEntity,
        MountainCarEnvironment,
        MountainCarAgent,
        MountainCarState,
        subscribers,
        get_agent,
        send!,
        Throttle,
        decorated
    @testset "Create environment" begin
        let env = MountainCar(1)
            @test env isa RxEntity{RxEnvironments.MountainCarEnvironment}
            @test length(subscribers(env)) == 1
            @test decorated(env).landscape(0) == 0
        end
    end

    @testset "Multiagent" begin
        import RxEnvironments: decorated, throttle
        let env = MountainCar(2)
            agent_1 = get_agent(env; index = 1)
            agent_2 = get_agent(env; index = 2)
            send!(env, agent_1, RxEnvironments.Throttle(1.0))
            send!(env, agent_2, RxEnvironments.Throttle(-1.0))
            @test throttle(decorated(agent_1)) == decorated(agent_1).engine_power
            @test throttle(decorated(agent_2)) == -decorated(agent_2).engine_power
        end
    end

    @testset "gravity" begin
        import RxEnvironments: gravitation
        let agent = MountainCarAgent(0.0, 1, 1, 1, 0)
            @test gravitation(agent, 0, (_) -> 1) == 0
            @test gravitation(agent, 0, (x) -> x) == -sin(π / 4) * 9.81
            @test gravitation(agent, 0, (x) -> 2x) == -sin(atan(2)) * 9.81
            @test gravitation(agent, 0, (x) -> x^2) == 0
        end


    end

    @testset "friction" begin
        import RxEnvironments: friction, set_velocity!
        let agent = MountainCarAgent(0.0, 1, 1, 1, 0)
            @test friction(agent, 0) == 0
            @test friction(agent, 1) == -1
            @test friction(agent, -1) == 1
        end
    end

    @testset "Discrete MountainCar" begin
        let env = MountainCar(1; discrete = true)
            agent = get_agent(env)
            actor = keep(Any)
            subscribe_to_observations!(agent, actor)
            send!(agent, env, Throttle(1.0))
            @test length(actor.values) == 1
        end

    end

    @testset "send!" begin
        import RxEnvironments: entity
        let env = MountainCar(1; emit_every_ms = 1)
            agent = get_agent(env)
            @test length(RxEnvironments.send!(decorated(agent), decorated(env))) == 2
            actor = keep(Any)
            subscribe_to_observations!(agent, actor)
            sleep(0.5)
            @test length(actor.values) > 1
        end
    end
end
