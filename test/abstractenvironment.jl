module test_abstract_environment

using Test
using RxEnvironments
using Rocket

include("bayesianthermostat.jl")

@testset "environment" begin
    @testset "constructor" begin
        environment = BayesianThermostat(0.0, -10, 10)
        rxenv = RxEnvironment(environment)
        @test rxenv isa RxEnvironment
    end

    @testset "add actor" begin
        import RxEnvironments: actions
        environment = BayesianThermostat(0.0, -10, 10)
        rxenv = RxEnvironment(environment)

        actor = ThermostatAgent()
        entity = add!(rxenv, actor)
        @test first(keys(actions(rxenv))) === entity
    end

    @testset "conduct action" begin
        import RxEnvironments
        environment = BayesianThermostat(0.0, -10, 10)
        rxenv = RxEnvironment(environment)

        actor = ThermostatAgent()
        entity = add!(rxenv, actor)
        next!(actions(entity, rxenv), ThermostatAction(1.0))
        @test environment.temperature == 1.0
        next!(actions(entity, rxenv), ThermostatAction(1.0))
        @test environment.temperature == 2.0
    end

end

end