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
        let rxentity = create_entity(MockAgent(), ContinuousEntity(), IsNotEnvironment())
            @test entity(rxentity) isa MockAgent
            @test observations(rxentity) isa Observations
            @test markov_blanket(rxentity) isa MarkovBlanket
        end
    end

    @testset "mutual subscribe" begin
        import RxEnvironments: subscribe_to_observations!, data
        let first_entity =
                create_entity(MockAgent(), ContinuousEntity(), IsNotEnvironment())
            let second_entity =
                    create_entity(MockAgent(), ContinuousEntity(), IsNotEnvironment())
                add!(first_entity, second_entity)
                @test is_subscribed(first_entity, second_entity)
                @test is_subscribed(second_entity, first_entity)
            end
        end
    end

    @testset "subscribe to observations" begin
        import RxEnvironments: subscribe_to_observations!, observations
        let env = RxEnvironment(MockEnvironment(0.0))
            actor = add!(env, MockAgent())
            obs = keep(Any)
            subscribe_to_observations!(actor, obs)
            @test length(obs) == 0
            next!(observations(env), Observation(actor, nothing))
            @test length(obs) == 1
        end
    end

    @testset "terminate!" begin
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

        let env = RxEnvironment(MockEnvironment(0.0); emit_every_ms = 10)
            agent = add!(env, MockAgent())
            terminate!(agent)
            @test !is_subscribed(agent, env)
            @test is_terminated(agent)
            @test length(subscribers(env)) == 0
        end

        let env = RxEnvironment(MockEnvironment(0.0); emit_every_ms = 10)
            agent = add!(env, MockAgent())
            terminate!(env)
            @test !is_subscribed(agent, env)
            @test is_terminated(env)
            @test length(subscribers(agent)) == 0
        end

    end

end

end
