module EnvironmentTests

using ReTest
using RxEnvironments
using Rocket
import RxEnvironments: conduct_action!, Observation, state

include("mockenvironment.jl")

@testset "environment" begin
    @testset "creation" begin
        import RxEnvironments: DiscreteEnvironment, TimerEnvironment, observations

        let env = RxEnvironment(MockEnvironment(0.0))
            @test env isa DiscreteEnvironment
            # Check that the environment will pass messages coming into the observations to subscribed actors.
            actor = keep(Any)
            subscribe!(env, actor)
            next!(observations(env), Observation(MockAgent(), nothing))
            @test actor.values == [state(env)]
            next!(observations(env), Observation(MockAgent(), nothing))
            @test actor.values ==
                  [state(env), state(env)]
        end

        import RxEnvironments: last_update

        let env = RxEnvironment(MockEnvironment(0.0); emit_every_ms = 10)
            @test env isa TimerEnvironment
            @test last_update(env) == 0.0
            actor = keep(Any)
            subscribe!(env, actor)
            next!(observations(env), Observation(MockAgent(), nothing))
            for i = 1:10
                prev_num_values = length(actor.values)
                sleep(0.01)
                num_values = length(actor.values)
                @test num_values > prev_num_values
            end
        end
    end

    @testset "add to other entity" begin
        import RxEnvironments: subscribed_entities, AbstractEntity
        let env = RxEnvironment(MockEnvironment(0.0))
            agent = MockAgent()
            agent = add!(env, agent)
            # Test that adding an agent to the environment works.
            @test length(subscribed_entities(env)) == 1
            @test subscribed_entities(env) == [agent]
            # Test that adding an agent propagates an observation to the agent.
            actor = keep(Any)
            subscribe!(observations(agent), actor)
            next!(observations(env), Observation(MockAgent(), nothing))
            @test RxEnvironments.data.(actor.values) == [nothing]

            second_agent = SecondMockAgent()
            second_agent = add!(env, second_agent)
            # Test that adding a second agent to the environment works.
            @test length(subscribed_entities(env)) == 2
            @test subscribed_entities(env) == Any[agent, second_agent]
            # Test that adding a second agent propagates an observation to the agent.
            actor = keep(Any)
            subscribe!(observations(second_agent), actor)
            next!(observations(env), Observation(MockAgent(), nothing))
            @test RxEnvironments.data.(actor.values) == [RxEnvironments.EmptyMessage()]
        end

        let env = RxEnvironment(MockEnvironment(0.0); emit_every_ms = 10)
            agent = MockAgent()
            agent = add!(env, agent)
            # Test that adding an agent to the environment works.
            @test length(subscribed_entities(env)) == 1
            # Test that adding an agent propagates an observation to the agent.
            actor = keep(Any)
            subscribe!(observations(agent), actor)
            next!(observations(env), Observation(MockAgent(), nothing))
            @test RxEnvironments.data.(actor.values) == [nothing]

            second_agent = SecondMockAgent()
            second_agent = add!(env, second_agent)
            # Test that adding a second agent to the environment works.
            @test length(subscribed_entities(env)) == 2
            # Test that adding a second agent propagates an observation to the agent.
            actor = keep(Any)
            subscribe!(observations(second_agent), actor)
            next!(observations(env), Observation(MockAgent(), nothing))
            @test RxEnvironments.data.(actor.values) == [RxEnvironments.EmptyMessage()]
        end
    end

    @testset "receive observation" begin
        let env = RxEnvironment(MockEnvironment(0.0))
            agent = MockAgent()
            agent = add!(env, agent)
            actor = keep(Any)
            subscribe!(observations(env), actor)
            for i = 1:10
                conduct_action!(agent, env, i)
                @test RxEnvironments.data.(actor.values) == collect(1:i)
            end
        end
    end

    @testset "add" begin
        import RxEnvironments: add!, subscribed_entities
        let env = RxEnvironment(MockEnvironment(0.0))
            agent = MockAgent()
            agent = add!(env, agent)
            @test length(subscribed_entities(env)) == 1
        end

        let env = RxEnvironment(MockEnvironment(0.0); emit_every_ms = 10)
            agent = MockAgent()
            agent = add!(env, agent)
            @test length(subscribed_entities(env)) == 1
        end

        let env1 = RxEnvironment(MockEnvironment(0.0))
            let env2 = RxEnvironment(MockEnvironment(0.0))
                add!(env1, env2)
                @test subscribed_entities(env1) == [env2]
                @test subscribed_entities(env2) == [env1]
            end
        end

    end

    @testset "show" begin
        let env = RxEnvironment(MockEnvironment(0.0))
            io = IOBuffer()
            ioc = IOContext(io)
            agent = MockAgent()
            agent = add!(env, agent)
            show(io, env)
            result = String(take!(io))
            @test occursin("Discrete RxEnvironment", result)
        end

        let env = RxEnvironment(MockEnvironment(0.0); emit_every_ms = 10)
            io = IOBuffer()
            ioc = IOContext(io)
            show(io, env)
            result = String(take!(io))
            @test occursin("Timed RxEnvironment", result)
        end

        let env1 = RxEnvironment(MockEnvironment(0.0))
            let env2 = RxEnvironment(MockEnvironment(0.0))
                add!(env1, env2)
                io = IOBuffer()
                ioc = IOContext(io)
                show(io, env1)
                result = String(take!(io))
                @test occursin("Discrete RxEnvironment", result)
            end
        end
    end

end

end
