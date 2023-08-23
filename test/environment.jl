module EnvironmentTests

using ReTest
using RxEnvironments
using Rocket

include("mockenvironment.jl")

@testset "environment" begin
    @testset "creation" begin
        import RxEnvironments: DiscreteEnvironment, TimerEnvironment, observations, Message

        let env = RxEnvironment(MockEnvironment(0.0))
            @test env isa DiscreteEnvironment
            # Check that the environment will pass messages coming into the observations to subscribed actors.
            actor = keep(Any)
            subscribe!(env, actor)
            next!(observations(env), Message(MockAgent(), nothing))
            @test actor.values == [RxEnvironments.EmptyMessage()]
            next!(observations(env), Message(MockAgent(), nothing))
            @test actor.values ==
                  [RxEnvironments.EmptyMessage(), RxEnvironments.EmptyMessage()]
        end

        import RxEnvironments: last_update

        let env = RxEnvironment(MockEnvironment(0.0); emit_every_ms = 10)
            @test env isa TimerEnvironment
            @test last_update(env) == 0.0
            actor = keep(Any)
            subscribe!(env, actor)
            next!(observations(env), Message(MockAgent(), nothing))
            sleep(0.008)
            @test length(actor.values) === 2
            sleep(0.008)
            @test length(actor.values) === 3
        end
    end

    @testset "add to other entity" begin
        import RxEnvironments: actions
        let env = RxEnvironment(MockEnvironment(0.0))
            agent = MockAgent()
            agent = add!(env, agent)
            # Test that adding an agent to the environment works.
            @test length(actions(env)) == 1
            # Test that adding an agent propagates an observation to the agent.
            actor = keep(Any)
            subscribe!(observations(agent), actor)
            next!(observations(env), Message(MockAgent(), nothing))
            @test RxEnvironments.data.(actor.values) == [nothing]

            second_agent = SecondMockAgent()
            second_agent = add!(env, second_agent)
            # Test that adding a second agent to the environment works.
            @test length(actions(env)) == 2
            # Test that adding a second agent propagates an observation to the agent.
            actor = keep(Any)
            subscribe!(observations(second_agent), actor)
            next!(observations(env), Message(MockAgent(), nothing))
            @test RxEnvironments.data.(actor.values) == [RxEnvironments.EmptyMessage()]
        end

        let env = RxEnvironment(MockEnvironment(0.0); emit_every_ms = 10)
            agent = MockAgent()
            agent = add!(env, agent)
            # Test that adding an agent to the environment works.
            @test length(actions(env)) == 1
            # Test that adding an agent propagates an observation to the agent.
            actor = keep(Any)
            subscribe!(observations(agent), actor)
            next!(observations(env), Message(MockAgent(), nothing))
            @test RxEnvironments.data.(actor.values) == [nothing]

            second_agent = SecondMockAgent()
            second_agent = add!(env, second_agent)
            # Test that adding a second agent to the environment works.
            @test length(actions(env)) == 2
            # Test that adding a second agent propagates an observation to the agent.
            actor = keep(Any)
            subscribe!(observations(second_agent), actor)
            next!(observations(env), Message(MockAgent(), nothing))
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
                next!(actions(agent, env), i)
                @test RxEnvironments.data.(actor.values) == collect(1:i)
            end
        end
    end

    @testset "show" begin
        let env = RxEnvironment(MockEnvironment(0.0))
            io = IOBuffer()
            ioc = IOContext(io)
            show(io, env)
        end

        let env = RxEnvironment(MockEnvironment(0.0); emit_every_ms = 10)
            io = IOBuffer()
            ioc = IOContext(io)
            show(io, env)
        end
    end

end

end
