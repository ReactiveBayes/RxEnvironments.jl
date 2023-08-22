module EnvironmentTests

using ReTest
using RxEnvironments
using Rocket

include("mockenvironment.jl")

@testset "environment" begin
    @testset "creation" begin
        import RxEnvironments: observations, Message

        let env = RxEnvironment(MockEnvironment(0.0))
            @test env isa RxEnvironment
            # Check that the environment will pass messages coming into the observations to subscribed actors.
            actor = keep(Any)
            subscribe!(env, actor)
            next!(observations(env), Message(MockAgent(), nothing))
            @test actor.values == [RxEnvironments.EmptyMessage()]
            next!(observations(env), Message(MockAgent(), nothing))
            @test actor.values ==
                  [RxEnvironments.EmptyMessage(), RxEnvironments.EmptyMessage()]
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

end

end
