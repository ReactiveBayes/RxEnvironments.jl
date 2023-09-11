module EnvironmentTests

using ReTest
using RxEnvironments
using Rocket
import RxEnvironments: Observation, DiscreteEntity, ContinuousEntity, state_space

include("../mockenvironment.jl")

@testset "environment" begin
    @testset "creation" begin
        import RxEnvironments: observations
        state = 0.0
        let env = RxEnvironment(MockEnvironment(state), discrete = true)
            @test state_space(env) == DiscreteEntity()
            # Check that the environment will pass messages coming into the observations to subscribed actors.
            agent = add!(env, MockAgent())
            actor = keep(Any)
            subscribe!(env, actor)
            next!(observations(env), Observation(agent, nothing))
            @test actor.values == [state]
            next!(observations(env), Observation(agent, nothing))
            @test actor.values == [state, state]
        end

        import RxEnvironments: last_update

        let env = RxEnvironment(MockEnvironment(0.0); emit_every_ms = 10)
            @test state_space(env) == ContinuousEntity()
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
        import RxEnvironments: AbstractEntity
        let env = RxEnvironment(MockEnvironment(0.0))
            agent = MockAgent()
            agent = add!(env, agent)
            # Test that adding an agent to the environment works.
            @test length(subscribers(env)) == 1
            @test subscribers(env) == [agent]
            # Test that adding an agent propagates an observation to the agent.
            actor = keep(Any)
            subscribe!(observations(agent), actor)
            next!(observations(env), Observation(MockAgent(), nothing))
            @test RxEnvironments.data.(actor.values) == [nothing]

            second_agent = SecondMockAgent()
            second_agent = add!(env, second_agent)
            # Test that adding a second agent to the environment works.
            @test length(subscribers(env)) == 2
            @test subscribers(env) == Any[agent, second_agent]
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
            @test length(subscribers(env)) == 1
            # Test that adding an agent propagates an observation to the agent.
            actor = keep(Any)
            subscribe_to_observations!(agent, actor)
            next!(observations(env), Observation(MockAgent(), nothing))
            @test RxEnvironments.data.(actor.values) == [nothing]

            second_agent = SecondMockAgent()
            second_agent = add!(env, second_agent)
            # Test that adding a second agent to the environment works.
            @test length(subscribers(env)) == 2
            # Test that adding a second agent propagates an observation to the agent.
            actor = keep(Any)
            subscribe_to_observations!(second_agent, actor)
            next!(observations(env), Observation(MockAgent(), nothing))
            @test RxEnvironments.data.(actor.values) == [RxEnvironments.EmptyMessage()]
        end
    end

    @testset "receive observation" begin
        let env = RxEnvironment(MockEnvironment(0.0))
            agent = MockAgent()
            agent = add!(env, agent)
            actor = keep(Any)
            subscribe_to_observations!(env, actor)
            for i = 1:10
                send!(env, agent, i)
                @test RxEnvironments.data.(actor.values) == collect(1:i)
            end
        end
    end

    @testset "add" begin
        let env = RxEnvironment(MockEnvironment(0.0))
            agent = MockAgent()
            agent = add!(env, agent)
            @test length(subscribers(env)) == 1
        end

        let env = RxEnvironment(MockEnvironment(0.0); emit_every_ms = 10)
            agent = MockAgent()
            agent = add!(env, agent)
            @test length(subscribers(env)) == 1
        end

        let env1 = RxEnvironment(MockEnvironment(0.0))
            let env2 = RxEnvironment(MockEnvironment(0.0))
                add!(env1, env2)
                @test subscribers(env1) == [env2]
                @test subscribers(env2) == [env1]
            end
        end
    end
end

end
