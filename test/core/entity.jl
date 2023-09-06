module EntityTests

using ReTest
using Rocket
using RxEnvironments
import RxEnvironments:
    entity,
    observations,
    markov_blanket,
    conduct_action!,
    Observation,
    create_entity,
    ContinuousEntity,
    DiscreteEntity,
    IsEnvironment,
    IsNotEnvironment

include("../mockenvironment.jl")

@testset "entity" begin
    @testset "constructor" begin
        import RxEnvironments: RxEntity, MarkovBlanket, Observations
        let rxentity = create_entity(MockAgent())
            @test rxentity isa RxEntity{MockAgent}
            @test entity(rxentity) isa MockAgent
            @test observations(rxentity) isa Observations
            @test markov_blanket(rxentity) isa MarkovBlanket
        end
    end

    @testset "mutual subscribe" begin
        import RxEnvironments: subscribe_to_observations!, data
        let first_entity = create_entity(MockAgent())
            let second_entity = create_entity(MockAgent())
                add!(first_entity, second_entity)
                @test is_subscribed(first_entity, second_entity)
                @test is_subscribed(second_entity, first_entity)
            end
        end

        let first_entity = create_entity(MockAgent(); discrete = true)
            let second_entity = create_entity(MockAgent(); discrete = true)
                add!(first_entity, second_entity)
                @test is_subscribed(first_entity, second_entity)
                @test is_subscribed(second_entity, first_entity)
            end
        end

        let first_entity = create_entity(MockAgent())
            let second_entity = create_entity(MockAgent(); discrete = true)
                @test_throws RxEnvironments.MixedStateSpaceException add!(
                    first_entity,
                    second_entity,
                )
                @test_throws RxEnvironments.MixedStateSpaceException subscribe!(
                    first_entity,
                    second_entity,
                )
                @test_throws RxEnvironments.MixedStateSpaceException subscribe!(
                    second_entity,
                    first_entity,
                )
            end
        end

    end

    @testset "subscribe to observations" begin
        import RxEnvironments: subscribe_to_observations!, observations, Observation
        let env = RxEnvironment(MockEnvironment(0.0))
            actor = add!(env, MockAgent())
            obs = keep(Any)
            subscribe_to_observations!(actor, obs)
            @test length(obs) == 0
            next!(observations(env), Observation(actor, nothing))
            @test length(obs) == 1
            @test RxEnvironments.data.(obs.values) == [nothing]
        end

        let env = RxEnvironment(MockEnvironment(0.0); discrete=true)
            actor = add!(env, MockAgent())
            obs = logger()
            sub = subscribe_to_observations!(actor, obs)
        end
    end

    @testset "terminate!" begin
        let env = RxEnvironment(MockEnvironment(0.0); discrete = true)
            agent = add!(env, MockAgent())
            terminate!(agent)
            @test !is_subscribed(agent, env)
            @test is_terminated(agent)
            @test length(subscribers(env)) == 0
        end

        let env = RxEnvironment(MockEnvironment(0.0); discrete = true)
            agent = add!(env, MockAgent())
            terminate!(env)
            @test !is_subscribed(agent, env)
            @test is_terminated(env)
            @test length(subscribers(agent)) == 0
        end

        let env = RxEnvironment(MockEnvironment(0.0))
            agent = add!(env, MockAgent())
            terminate!(agent)
            @test !is_subscribed(agent, env)
            @test is_terminated(agent)
            @test length(subscribers(env)) == 0
        end

        let env = RxEnvironment(MockEnvironment(0.0))
            agent = add!(env, MockAgent())
            terminate!(env)
            @test !is_subscribed(agent, env)
            @test is_terminated(env)
            @test length(subscribers(agent)) == 0
        end
    end

    @testset "add adds same type of entity" begin
        import RxEnvironments: state_space
        let env = RxEnvironment(MockEnvironment(0.0))
            agent = add!(env, MockAgent())
            @test state_space(agent) == state_space(env)
        end
    end

    @testset "two generic agents sending message" begin
        import RxEnvironments: create_entity, conduct_action!
        let agent_1 = create_entity(MockAgent())
            let agent_2 = create_entity(MockAgent())
                add!(agent_1, agent_2)
                result = keep(RxEnvironments.AbstractObservation)
                subscribe_to_observations!(agent_2, result)
                conduct_action!(agent_1, agent_2, 1)
                @test RxEnvironments.data.(result.values) == [1]
                conduct_action!(agent_1, agent_2, 2)
                @test RxEnvironments.data.(result.values) == [1, 2]
            end
        end
    end

end

end
