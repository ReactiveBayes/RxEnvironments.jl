module EntityTests

using ReTest
using Rocket
using RxEnvironments
import RxEnvironments: entity, observations, markov_blanket, conduct_action!, Observation

include("mockenvironment.jl")

@testset "entity" begin
    @testset "constructor" begin
        import RxEnvironments: RxEntity, MarkovBlanket
        let rxentity = RxEntity(MockAgent())
            @test entity(rxentity) isa MockAgent
            @test observations(rxentity) isa Rocket.RecentSubjectInstance
            @test markov_blanket(rxentity) isa MarkovBlanket
        end
    end

    @testset "mutual subscribe" begin
        import RxEnvironments: __add!, inspect_observations, data
        let first_entity = RxEntity(MockAgent())
            let second_entity = RxEntity(MockAgent())
                __add!(first_entity, second_entity)
                obs = keep(Any)
                inspect_observations(second_entity, obs)
                conduct_action!(first_entity, second_entity, 10)
                @test data.(obs.values) == [10]
            end
        end
    end

    @testset "inspect_observations" begin
        import RxEnvironments: inspect_observations, observations
        let env = RxEnvironment(MockEnvironment(0.0))
            actor = add!(env, MockAgent())
            obs = keep(Any)
            inspect_observations(actor, obs)
            @test length(obs) == 0
            next!(observations(env), Observation(actor, nothing))
            @test length(obs) == 1
        end
    end

end

end
