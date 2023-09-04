module TestMountainCarEnvironment

using RxEnvironments
using ReTest
using Rocket

import RxEnvironments: RxEntity, MountainCarEnvironment, MountainCarAgent, MountainCarState, subscribers, get_agent, conduct_action!, Throttle, entity

@testset "Mountain car environment" begin
    @testset "Create environment" begin
        let env = MountainCar(1) 
            @test env isa RxEntity{RxEnvironments.MountainCarEnvironment}
            @test length(subscribers(env)) == 1
        end
    end

    @testset "Multiagent" begin
        import RxEnvironments: entity, throttle
        let env = MountainCar(2)
            agent_1 = get_agent(env; index = 1)
            agent_2 = get_agent(env; index = 2)
            conduct_action!(agent_1, env, RxEnvironments.Throttle(1.0))
            conduct_action!(agent_2, env, RxEnvironments.Throttle(-1.0))
            @test throttle(entity(agent_1)) == entity(agent_1).engine_power
            @test throttle(entity(agent_2)) == -entity(agent_2).engine_power
        end
    end

    @testset "gravity" begin
        import RxEnvironments: gravitation
        let agent = MountainCarAgent(0.0, 1, 1, 1)
            @test gravitation(agent, (_) -> 1) == 0
            @test gravitation(agent, (x) -> x) == -sin(π / 4) * 9.81
            @test gravitation(agent, (x) -> 2x) == -sin(atan(2)) * 9.81
            @test gravitation(agent, (x) -> x^2) == 0
        end
    end

    @testset "friction" begin
        import RxEnvironments: friction, set_velocity!
        let agent = MountainCarAgent(0.0, 1, 1, 1)
            @test friction(agent) == 0
            set_velocity!(agent, 1)
            @test friction(agent) == -1
            set_velocity!(agent, -1)
            @test friction(agent) == 1
        end
    end

    @testset "Discrete MountainCar" begin
        let env = MountainCar(1; discrete=true)
            agent = get_agent(env)
            actor = keep(Any)
            subscribe_to_observations!(agent, actor)
            conduct_action!(agent, env, Throttle(1.0))
            @test length(actor.values) == 1
        end

    end
end

end