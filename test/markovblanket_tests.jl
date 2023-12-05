@testitem "actuator" begin
    import RxEnvironments:
        Actuator,
        Sensor,
        MarkovBlanket,
        RxEntity,
        markov_blanket,
        subscribe_to_observations!,
        NotSubscribedException,
        DiscreteEntity,
        ContinuousEntity,
        create_entity

    include("mockenvironment.jl")
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

@testitem "markov blanket" begin

    include("mockenvironment.jl")
    using RxEnvironments
    import RxEnvironments:
        Actuator,
        Sensor,
        MarkovBlanket,
        RxEntity,
        markov_blanket,
        subscribe_to_observations!,
        NotSubscribedException,
        DiscreteEntity,
        ContinuousEntity,
        create_entity
    @testset "constructor" begin
        let markov_blanket = MarkovBlanket(DiscreteEntity())
            @test markov_blanket isa MarkovBlanket{DiscreteEntity}
        end
        let markov_blanket = MarkovBlanket(ContinuousEntity())
            @test markov_blanket isa MarkovBlanket{ContinuousEntity}
        end
    end

    @testset "add and remove subscriber" begin
        import RxEnvironments: IsNotEnvironment
        let env = create_entity(MockEnvironment(); is_active = true)
            agent = create_entity(MockEntity())
            subscribe!(env, agent)
            @test is_subscribed(agent, env)

            second_agent = create_entity(MockEntity())
            subscribe!(env, second_agent)
            @test is_subscribed(second_agent, env)
            @test length(subscribers(env)) == 2
            @test subscribers(env) == [agent, second_agent]

            unsubscribe!(env, agent)
            @test !is_subscribed(agent, env)
            @test is_subscribed(second_agent, env)
            @test length(subscribers(env)) == 1
            @test_throws NotSubscribedException send!(env, agent, 10)

            unsubscribe!(env, second_agent)
            @test !is_subscribed(agent, env)
            @test !is_subscribed(second_agent, env)
            @test length(subscribers(env)) == 0
        end

        let env = RxEnvironment(MockEnvironment())
            actor = keep(Any)
            sub = subscribe!(env, actor)
            @test is_subscribed(actor, env)
            unsubscribe!(env, actor, sub)
            @test !is_subscribed(actor, env)
        end
    end

    @testset "add subscription" begin

        import RxEnvironments: IsNotEnvironment
        let env = create_entity(MockEnvironment(); is_active = true)
            agent = create_entity(MockEntity())
            subscribe!(agent, env)
            @test is_subscribed(env, agent)
            @test subscribed_to(env) == [agent]
        end
    end
end

@testitem "sensor" begin
    import RxEnvironments:
        Actuator,
        Sensor,
        MarkovBlanket,
        RxEntity,
        markov_blanket,
        subscribe_to_observations!,
        NotSubscribedException,
        DiscreteEntity,
        ContinuousEntity,
        create_entity,
        IsNotEnvironment

    include("mockenvironment.jl")

    let env = create_entity(MockEnvironment(); is_active = true)
        agent = create_entity(MockEntity())
        subscribe!(env, agent)
        actor = keep(Any)
        subscribe_to_observations!(agent, actor)
        send!(agent, env, 10)
        @test RxEnvironments.data.(actor.values) == [10]

        second_agent = create_entity(MockEntity())
        subscribe!(env, second_agent)
        second_actor = keep(Any)
        subscribe_to_observations!(second_agent, second_actor)
        send!(second_agent, env, 20)
        @test RxEnvironments.data.(actor.values) == [10]
        @test RxEnvironments.data.(second_actor.values) == [20]
    end
end

# @testitem "send branching" begin
#     using RxEnvironments
#     import RxEnvironments: DiscreteEntity, create_entity
#     include("../mockenvironment.jl")
#     let env = RxEnvironment(MockEnvironment(0.0); discrete = true)
#         agent = add!(env, MockAgent())
#         obs = subscribe_to_observations!(agent, RxEnvironments.keep(Any))
#         send!(env, agent, 10)
#         send!(env, agent, 10.0)
#         @test obs.values[1] == "Integer"

#     end
# end
