

@testitem "discrete environment" begin
    using RxEnvironments
    using Rocket
    import RxEnvironments: subscribe_to_observations!, add_timer!

    include("mockenvironment.jl")

    @testset "wait until all actors fire" begin
        let env = RxEnvironment(MockEnvironment(), discrete = true)
            first_agent = add!(env, MockEntity())
            second_agent = add!(env, MockEntity())
            values = subscribe_to_observations!(second_agent, keep(Any))
            send!(env, first_agent, 0.0)
            send!(env, first_agent, 0.0)
            @test length(values.values) == 0
            send!(env, second_agent, 0.0)
            @test length(values.values) == 1
            send!(env, second_agent, 0.0)
            @test length(values.values) == 1
            send!(env, first_agent, 0.0)
            @test length(values.values) == 2
        end
    end

    @testset "not possible to add timer" begin
        let env = RxEnvironment(MockEnvironment(), discrete = true)
            @test_throws MethodError add_timer!(env, 1000)
        end
    end

end
