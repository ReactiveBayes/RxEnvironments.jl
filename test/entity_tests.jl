@testitem "entity" begin
    using Rocket
    using RxEnvironments
    import RxEnvironments:
        decorated,
        observations,
        markov_blanket,
        Observation,
        create_entity,
        ContinuousEntity,
        DiscreteEntity,
        IsEnvironment,
        IsNotEnvironment
    include("mockenvironment.jl")
    @testset "constructor" begin
        import RxEnvironments: RxEntity, MarkovBlanket, Observations
        let rxentity = create_entity(MockAgent())
            @test rxentity isa RxEntity{MockAgent}
            @test decorated(rxentity) isa MockAgent
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

        let env = RxEnvironment(MockEnvironment(0.0); discrete = true)
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
        import RxEnvironments: create_entity
        let agent_1 = create_entity(MockAgent())
            let agent_2 = create_entity(MockAgent())
                add!(agent_1, agent_2)
                result = keep(RxEnvironments.AbstractObservation)
                subscribe_to_observations!(agent_2, result)
                send!(agent_2, agent_1, 1)
                @test RxEnvironments.data.(result.values) == [1]
                send!(agent_2, agent_1, 2)
                @test RxEnvironments.data.(result.values) == [1, 2]
            end
        end
    end

    @testset "emits" begin
        let env_1 = RxEnvironment(MockEnvironment(0.0))
            let env_2 = RxEnvironment(MockEnvironment(0.0))
                add!(env_1, env_2)
                obs = subscribe_to_observations!(env_2, keep(Any))
                RxEnvironments.send!(env_1, env_2, 1)
                @test length(obs) == 0
            end
        end
    end

end
