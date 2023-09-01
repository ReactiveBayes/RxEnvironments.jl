module TestDiscreteEnvironment

using RxEnvironments
using Rocket
using ReTest
import RxEnvironments: subscribe_to_observations!, conduct_action!, add_timer!

include("../mockenvironment.jl")

@testset "discrete environment" begin

    @testset "wait until all actors fire" begin
        let env = RxEnvironment(MockEnvironment(0.0), discrete=true)
            first_agent = add!(env, MockAgent())
            second_agent = add!(env, SecondMockAgent())
            values = subscribe_to_observations!(second_agent, keep(Any))
            RxEnvironments.conduct_action!(first_agent, env, 0.0)
            RxEnvironments.conduct_action!(first_agent, env, 0.0)
            @test length(values.values) == 0
            RxEnvironments.conduct_action!(second_agent, env, 0.0)
            @test length(values.values) == 1
            RxEnvironments.conduct_action!(second_agent, env, 0.0)
            @test length(values.values) == 1
            RxEnvironments.conduct_action!(first_agent, env, 0.0)
            @test length(values.values) == 2
        end
    end

    @testset "not possible to add timer" begin
        let env = RxEnvironment(MockEnvironment(0.0), discrete=true)
            @test_throws MethodError add_timer!(env, 1000)
        end
    end

end

end