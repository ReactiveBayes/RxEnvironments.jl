@testitem "continuous environment" begin
    using RxEnvironments
    import RxEnvironments: state_space, last_update, is_active
    include("mockenvironment.jl")

    @testset "creation" begin
        let env = RxEnvironment(MockEnvironment())
            @test is_active(env)
            @test state_space(env) == RxEnvironments.ContinuousEntity()
        end

        import RxEnvironments: clock, start_time

        let env = RxEnvironment(MockEnvironment(); emit_every_ms=10)
            @test is_active(env)
            t = time(env)
            sleep(0.1)
            @test last_update(clock(env)) > t
        end
    end

    @testset "environment emits when agent emits" begin
        import RxEnvironments: data

        let env = RxEnvironment(MockEnvironment())
            agent = MockEntity()
            agent = add!(env, agent)
            actor = keep(Any)
            subscribe_to_observations!(agent, actor)
            # When the agent sends to the environment
            send!(env, agent, 10)
            # Then the environment should emit an observation to the agent.
            @test data.(actor.values) == [nothing]
        end
    end

    @testset "environment emits on regular interval" begin
        import RxEnvironments: data

        let env = RxEnvironment(MockEnvironment())
            agent = MockEntity()
            agent = add!(env, agent)
            actor = keep(Any)
            subscribe_to_observations!(agent, actor)
            # When the agent sends to the environment
            sleep(1)
            # Then the environment should emit an observation to the agent.
            @test data.(actor.values) == [nothing]
        end
    end

    @testset "environment without update! defined throws warning" begin
        import RxEnvironments: update!, decorated, terminate!
        let env = RxEnvironment(MockEntity(); emit_every_ms=10)
            sleep(0.2)
            Test.@test_logs (
                :warn,
                "`update!` triggered for entity of type $(typeof(decorated(env))), but no update function is defined for this type.",
            )
            terminate!(env)
        end
    end
end

@testitem "discrete environment" begin
    using RxEnvironments
    import RxEnvironments: state_space, last_update, is_active
    include("mockenvironment.jl")

    @testset "creation" begin
        let env = RxEnvironment(MockEnvironment(); is_discrete=true)
            @test is_active(env)
            @test state_space(env) == RxEnvironments.DiscreteEntity()
        end
    end

    @testset "environment emits when agent emits" begin
        import RxEnvironments: data

        let env = RxEnvironment(MockEnvironment(); is_discrete=true)
            agent = MockEntity()
            agent = add!(env, agent)
            actor = keep(Any)
            subscribe_to_observations!(agent, actor)
            # When the agent sends to the environment
            send!(env, agent, 10)
            # Then the environment should emit an observation to the agent.
            @test data.(actor.values) == [nothing]
        end
    end

    @testset "environment waits until all agents have emitted" begin
        let env = RxEnvironment(MockEnvironment(), is_discrete=true)
            first_agent = add!(env, MockEntity())
            second_agent = add!(env, MockEntity())
            values = keep(Any)
            sub = subscribe_to_observations!(second_agent, values)
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

    @testset "environment without update! defined throws warning" begin
        import RxEnvironments: update!, decorated
        let env = RxEnvironment(MockEntity(), is_discrete=true)
            update!(env)
            Test.@test_logs (
                :warn,
                "`update!` triggered for entity of type $(typeof(decorated(env))), but no update function is defined for this type.",
            )
        end
    end

    @testset "environment with active subscribers waits until all subscribers have emitted" begin
        let env = RxEnvironment(DiscreteMockEnvironment(), is_discrete=true)
            agent_1 = DiscreteMockEntity()
            agent_1 = add!(env, agent_1; is_active=true)
            agent_2 = DiscreteMockEntity()
            agent_2 = add!(env, agent_2; is_active=true)
            values = keep(Any)
            sub = subscribe_to_observations!(agent_1, values)
            send!(env, agent_1, 0.0)
            @test length(values.values) == 0
            send!(env, agent_2, 0.0)
            @test length(values.values) == 2
            send!(env, agent_1, 0.0)
            @test length(values.values) == 2
            send!(env, agent_2, 0.0)
            @test length(values.values) == 4
        end
    end

end
