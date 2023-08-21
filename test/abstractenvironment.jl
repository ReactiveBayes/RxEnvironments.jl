module test_abstract_environment

using Test
using RxEnvironments
using Rocket

include("bayesianthermostat.jl")

@testset "environment" begin
    @testset "constructor" begin
        environment = BayesianThermostat(0.0, -10, 10)
        rxenv = RxEnvironment(environment)
        @test rxenv isa RxEnvironment{ThermostatAction}
    end

    @testset "add actor" begin
        import RxEnvironments: entities
        environment = BayesianThermostat(0.0, -10, 10)
        rxenv = RxEnvironment(environment)

        actor = ThermostatAgent()
        entity = add!(rxenv, actor)
        @test first(entities(rxenv)) === entity
    end

    @testset "conduct action" begin
        import RxEnvironments: action_subject
        environment = BayesianThermostat(0.0, -10, 10)
        rxenv = RxEnvironment(environment)

        actor = ThermostatAgent()
        entity = add!(rxenv, actor)
        next!(action_subject(entity), ThermostatAction(1.0))
        @test environment.temperature == 1.0
        next!(action_subject(entity), ThermostatAction(1.0))
        @test environment.temperature == 2.0
    end

    @testset "get observation" begin
        import RxEnvironments: observation_subject
    end
end

end