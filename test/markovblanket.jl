module TestMarkovBlanket

using ReTest
using Rocket
using RxEnvironments
import RxEnvironments:
    Actuator,
    Sensor,
    MarkovBlanket,
    RxEntity,
    markov_blanket,
    subscribe_to_observations!,
    conduct_action!,
    NotSubscribedException,
    Discrete,
    Continuous,
    create_entity

include("mockenvironment.jl")

@testset "actuator" begin
    @testset "constructor" begin
        let actuator = Actuator()
            @test actuator isa Actuator
            @test_throws MethodError Actuator(10)
        end
    end

    @testset "send_action!" begin
        import RxEnvironments: send_action!
        let actuator = Actuator()
            agent = keep(Any)
            subscribe!(actuator, agent)
            send_action!(actuator, 10)
            @test agent.values == [10]
            send_action!(actuator, 20)
            @test agent.values == [10, 20]
        end
    end
end

@testset "markov blanket" begin
    @testset "constructor" begin
        let markov_blanket = MarkovBlanket(Discrete())
            @test markov_blanket isa MarkovBlanket{Discrete}
        end
        let markov_blanket = MarkovBlanket(Continuous())
            @test markov_blanket isa MarkovBlanket{Continuous}
        end
    end

    @testset "add and remove subscriber" begin
        import RxEnvironments: IsNotEnvironment
        let env = RxEnvironment(MockEnvironment(0.0))
            agent = create_entity(MockAgent(), Continuous(), IsNotEnvironment())
            subscribe!(env, agent)
            @test is_subscribed(agent, env)

            second_agent = create_entity(MockAgent(), Continuous(), IsNotEnvironment())
            subscribe!(env, second_agent)
            @test is_subscribed(second_agent, env)
            @test length(subscribers(env)) == 2
            @test subscribers(env) == [agent, second_agent]

            unsubscribe!(env, agent)
            @test !is_subscribed(agent, env)
            @test is_subscribed(second_agent, env)
            @test length(subscribers(env)) == 1
            @test_throws NotSubscribedException conduct_action!(env, agent, 10)

            unsubscribe!(env, second_agent)
            @test !is_subscribed(agent, env)
            @test !is_subscribed(second_agent, env)
            @test length(subscribers(env)) == 0
        end

        let env = RxEnvironment(MockEnvironment(0.0))
            actor = keep(Any)
            sub = subscribe!(env, actor)
            @test is_subscribed(actor, env)
            unsubscribe!(env, actor, sub)
            @test !is_subscribed(actor, env)
        end
    end

    @testset "add subscription" begin
        import RxEnvironments: IsNotEnvironment
        let env = RxEnvironment(MockEnvironment(0.0))
            agent = create_entity(MockAgent(), Continuous(), IsNotEnvironment())
            subscribe!(agent, env)
            @test is_subscribed(env, agent)
            @test subscribed_to(env) == [agent]
        end
    end
end

@testset "sensor" begin
    import RxEnvironments: IsNotEnvironment
    let env = RxEnvironment(MockEnvironment(0.0))
        agent = create_entity(MockAgent(), Continuous(), IsNotEnvironment())
        subscribe!(env, agent)
        actor = keep(Any)
        subscribe_to_observations!(agent, actor)
        conduct_action!(env, agent, 10)
        @test RxEnvironments.data.(actor.values) == [10]

        second_agent = create_entity(MockAgent(), Continuous(), IsNotEnvironment())
        subscribe!(env, second_agent)
        second_actor = keep(Any)
        subscribe_to_observations!(second_agent, second_actor)
        conduct_action!(env, second_agent, 20)
        @test RxEnvironments.data.(actor.values) == [10]
        @test RxEnvironments.data.(second_actor.values) == [20]
    end
end

end
