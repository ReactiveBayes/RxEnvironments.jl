module EntityTests

using ReTest
using Rocket
using RxEnvironments

include("mockenvironment.jl")

@testset "entity" begin
    @testset "constructor" begin
        import RxEnvironments: RxEntity
        let entity = RxEntity(MockAgent())
            @test entity.entity isa MockAgent
            @test entity.observations isa Rocket.RecentSubjectInstance
            @test entity.actions isa AbstractDict
        end
    end

    @testset "mutual subscribe" begin
        import RxEnvironments: __add!, inspect_observations, data
        let first_entity = RxEntity(MockAgent())
            let second_entity = RxEntity(MockAgent())
                __add!(first_entity, second_entity)
                obs = inspect_observations(second_entity)
                next!(first_entity, second_entity, 10)
                @test data.(obs.values) == [10]
            end
        end
    end

    @testset "inspect_observations" begin
        import RxEnvironments: inspect_observations, observations, Message
        let env = RxEnvironment(MockEnvironment(0.0))
            actor = add!(env, MockAgent())
            obs = inspect_observations(actor)
            @test length(obs) == 0
            next!(observations(env), Message(MockAgent(), nothing))
            @test length(obs) == 1
        end
    end

end

end
