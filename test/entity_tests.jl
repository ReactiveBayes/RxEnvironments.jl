@testitem "continuous entity" begin
    import RxEnvironments: create_entity, subscribe_to_observations!
    using Rocket

    include("mockenvironment.jl")
    @testset "constructor" begin
        e = create_entity(MockEntity())
        @test e isa RxEnvironments.RxEntity{MockEntity}
    end

    @testset "decorated" begin
        import RxEnvironments: decorated

        e = create_entity(MockEntity())
        @test decorated(e) === MockEntity()

        e = create_entity(MockEnvironment())
        @test decorated(e) === MockEnvironment()

        e = create_entity(MockEntity(); is_environment = true)
        @test decorated(e) === MockEntity()
    end

    @testset "markov blanket functionality" begin
        let e = create_entity(MockEntity())
            @test e.markov_blanket isa RxEnvironments.MarkovBlanket
        end
    end

    @testset "subscribe_to_observations!" begin
        import RxEnvironments: observations, data
        let e = create_entity(MockEntity())
            obs = keep(Any)
            subscribe_to_observations!(e, obs)

            @test length(obs) == 0

            next!(observations(e), RxEnvironments.Observation(e, nothing))
            @test length(obs) == 1
            @test last(obs) === RxEnvironments.Observation(e, nothing)
            @test data.(obs.values) == [nothing]

            next!(observations(e), RxEnvironments.Observation(e, 1))
            @test length(obs) == 2
            @test last(obs) === RxEnvironments.Observation(e, 1)
            @test data.(obs.values) == [nothing, 1]
        end
    end

    @testset "clock and time keeping" begin
        import RxEnvironments: clock

        # Test functionality for different real time factors
        for real_time_factor in [0.25, 0.5, 1, 2, 5]
            let e = create_entity(MockEntity(); real_time_factor = real_time_factor)
                obs = keep(Any)
                subscribe_to_observations!(e, obs)

                # Test timekeeping functionality
                @test clock(e).real_time_factor == real_time_factor
                prev_time = time(clock(e))
                sleep(0.1)
                elapsed_time = time(clock(e)) - prev_time
                @test isapprox(elapsed_time, 0.1 / real_time_factor, atol = 1e-2)

                # Sanity check that no observations are obtained (timer and clock are decoupled)
                @test length(obs) == 0
            end
        end
    end

    @testset "add timer" begin
        import RxEnvironments: add_timer!

        let e = create_entity(MockEntity())
            obs = keep(Any)
            subscribe_to_observations!(e, obs)

            add_timer!(e, 10)
            for i = 1:10
                prev_n_obs = length(obs)
                sleep(0.1)
                @test length(obs) > prev_n_obs
            end

        end
    end

    @testset "add subscriber" begin
        # Test default case of two interacting entities

        let first_entity = create_entity(MockEntity())
            let second_entity = create_entity(MockEntity())
                subscribe!(first_entity, second_entity)
                @test !is_subscribed(first_entity, second_entity)
                @test is_subscribed(second_entity, first_entity)
            end
        end

        # Test case of three interacting entities
        let first_entity = create_entity(MockEntity())
            let second_entity = create_entity(MockEntity())
                let third_entity = create_entity(MockEntity())
                    subscribe!(first_entity, second_entity)
                    subscribe!(second_entity, third_entity)
                    @test !is_subscribed(first_entity, second_entity)
                    @test is_subscribed(second_entity, first_entity)
                    @test !is_subscribed(second_entity, third_entity)
                    @test is_subscribed(third_entity, second_entity)
                end
            end
        end

        # Test self-subscription
        let first_entity = create_entity(MockEntity())
            @test_throws RxEnvironments.SelfSubscriptionException subscribe!(
                first_entity,
                first_entity,
            )
        end
    end

    @testset "mutual subscribe" begin
        let first_entity = create_entity(MockEntity())
            let second_entity = create_entity(MockEntity())
                add!(first_entity, second_entity)
                @test is_subscribed(first_entity, second_entity)
                @test is_subscribed(second_entity, first_entity)
            end
        end
    end

    @testset "unsubscribe" begin
        let first_entity = create_entity(MockEntity())
            let second_entity = create_entity(MockEntity())
                first_obs = keep(Any)
                second_obs = keep(Any)
                subscribe_to_observations!(first_entity, first_obs)
                subscribe_to_observations!(second_entity, second_obs)

                add!(first_entity, second_entity)
                # Test that we can send messages from first_entity to second_entity
                @test send!(first_entity, second_entity, 1) isa Any

                unsubscribe!(first_entity, second_entity)
                @test !is_subscribed(second_entity, first_entity)
                @test_throws RxEnvironments.NotSubscribedException send!(
                    second_entity,
                    first_entity,
                    1,
                )
            end
        end
    end

    @testset "receive observations" begin
        import RxEnvironments: data

        # Test simple case of two interacting entities
        let first_entity = create_entity(MockEntity())
            let second_entity = create_entity(MockEntity())
                first_obs = keep(Any)
                second_obs = keep(Any)
                subscribe_to_observations!(first_entity, first_obs)
                subscribe_to_observations!(second_entity, second_obs)

                add!(first_entity, second_entity)

                # Test that we correctly receive observations in first_entity
                send!(first_entity, second_entity, 1)
                @test data.(first_obs.values) == [1]
                # Test that second_entity does not receive observations
                @test length(second_obs) == 0

                send!(first_entity, second_entity, nothing)
                @test data.(first_obs.values) == [1, nothing]
                @test length(second_obs) == 0

                # Test that we correctly receive observations in second_entity
                send!(second_entity, first_entity, 2)
                @test data.(second_obs.values) == [2]
                # Test that first_entity does not receive observations
                @test data.(first_obs.values) == [1, nothing]

                send!(second_entity, first_entity, nothing)
                @test data.(second_obs.values) == [2, nothing]
                @test data.(first_obs.values) == [1, nothing]
            end
        end

        # Test case of three interacting entities
        # Subscriptions:
        # first_entity <-> second_entity <-> third_entity
        let first_entity = create_entity(MockEntity())
            let second_entity = create_entity(MockEntity())
                let third_entity = create_entity(MockEntity())
                    first_obs = keep(Any)
                    second_obs = keep(Any)
                    third_obs = keep(Any)
                    subscribe_to_observations!(first_entity, first_obs)
                    subscribe_to_observations!(second_entity, second_obs)
                    subscribe_to_observations!(third_entity, third_obs)

                    add!(first_entity, second_entity)
                    add!(second_entity, third_entity)

                    # Test that we correctly receive observations in first_entity
                    send!(first_entity, second_entity, 1)
                    @test data.(first_obs.values) == [1]
                    # Test that second_entity does not receive observations
                    @test length(second_obs) == 0
                    # Test that third_entity does not receive observations
                    @test length(third_obs) == 0
                    # Test that we can't send messages from third_entity to first_entity
                    @test_throws RxEnvironments.NotSubscribedException send!(
                        third_entity,
                        first_entity,
                        1,
                    )

                    send!(third_entity, second_entity, 2)
                    @test data.(third_obs.values) == [2]
                    @test length(second_obs) == 0
                    @test length(first_obs) == 1
                end
            end
        end
    end

    @testset "send message" begin
        let first_entity = create_entity(MockEntity())
            obs = keep(Any)
            subscribe!(first_entity, obs)
            send!(obs, first_entity, 1)
            @test last(obs) == 1
            send!(obs, first_entity, 2)
            @test last(obs) == 2
        end
    end

    @testset "emits" begin
        import RxEnvironments: emits, decorated

        # Test that by default we always emit
        let first_entity = create_entity(MockEntity())
            let second_entity = create_entity(MockEntity())
                add!(first_entity, second_entity)
                @test emits(decorated(first_entity), decorated(second_entity), nothing) ==
                      true
                @test emits(decorated(second_entity), decorated(first_entity), nothing) ==
                      true
            end
        end

        # Test that we can trigger emission behaviour
        let first_entity = create_entity(SelectiveSendingEntity(); is_environment = true)
            let second_entity = create_entity(SelectiveReceivingEntity())
                # Assert that we only block emission if the incoming message is `Nothing`
                @test emits(decorated(first_entity), decorated(second_entity), nothing) ==
                      false
                @test emits(decorated(first_entity), decorated(second_entity), 1) == true

                # Keep track of the observations of second_entity
                obs = keep(Any)
                subscribe_to_observations!(second_entity, obs)

                add!(first_entity, second_entity)
                # If we send an integer from second_entity to first_entity, second_entity should receive an observation
                send!(first_entity, second_entity, 1)
                @test length(obs) == 1

                # If we send `nothing` from second_entity to first_entity, second_entity should not receive an additional observation
                send!(first_entity, second_entity, nothing)
                @test length(obs) == 1
            end
        end
    end

    @testset "terminate!" begin
        import RxEnvironments: terminate!, is_terminated

        let first_entity = create_entity(MockEntity())
            let second_entity = create_entity(MockEntity())
                add!(first_entity, second_entity)

                @test is_subscribed(first_entity, second_entity)
                @test is_subscribed(second_entity, first_entity)
                @test !is_terminated(first_entity)

                terminate!(first_entity)

                @test !is_subscribed(first_entity, second_entity)
                @test !is_subscribed(second_entity, first_entity)
                @test is_terminated(first_entity)
            end
        end
    end

    @testset "selective message sending" begin

    end
end

@testitem "discrete entity" begin
    import RxEnvironments: create_entity, subscribe_to_observations!
    using Rocket

    include("mockenvironment.jl")
    @testset "constructor" begin
        e = create_entity(MockEntity(); discrete = true)
        @test e isa RxEnvironments.RxEntity{MockEntity}
    end

    @testset "markov blanket functionality" begin
        let e = create_entity(MockEntity(); discrete = true)
            @test e.markov_blanket isa RxEnvironments.MarkovBlanket
        end
    end

    @testset "subscribe_to_observations!" begin
        import RxEnvironments: observations, data
        let first_entity = create_entity(MockEntity(); discrete = true)
            let second_entity = create_entity(MockEntity(); discrete = true)
                add!(first_entity, second_entity)
                obs = keep(Any)
                subscribe_to_observations!(first_entity, obs)

                @test length(obs) == 0

                next!(
                    observations(first_entity),
                    RxEnvironments.Observation(second_entity, nothing),
                )
                @test length(obs) == 1
                @test last(obs) === RxEnvironments.ObservationCollection((
                    RxEnvironments.Observation(second_entity, nothing),
                ))
                @test data.(obs.values) == [nothing]

                next!(
                    observations(first_entity),
                    RxEnvironments.Observation(second_entity, 1),
                )
                @test length(obs) == 2
                @test last(obs) === RxEnvironments.ObservationCollection((
                    RxEnvironments.Observation(second_entity, 1),
                ))
                @test data.(obs.values) == [nothing, 1]
            end
        end
    end

    @testset "clock and time keeping" begin
        import RxEnvironments: clock, add_elapsed_time!
        let e = create_entity(MockEntity(); discrete = true)
            obs = keep(Any)
            subscribe_to_observations!(e, obs)

            add_elapsed_time!(clock(e), 1)
            @test time(clock(e)) === 1.0

            add_elapsed_time!(clock(e), 1)
            @test time(clock(e)) === 2.0

            @test_throws ErrorException add_elapsed_time!(clock(e), -0.5)
            # Sanity check that no observations are obtained (timer and clock are decoupled)
            @test length(obs) == 0
        end
    end

    @testset "add subscriber" begin
        # Test default case of two interacting entities

        let first_entity = create_entity(MockEntity(); discrete = true)
            let second_entity = create_entity(MockEntity(); discrete = true)
                subscribe!(first_entity, second_entity)
                @test !is_subscribed(first_entity, second_entity)
                @test is_subscribed(second_entity, first_entity)
            end
        end

        # Test case of three interacting entities
        let first_entity = create_entity(MockEntity(); discrete = true)
            let second_entity = create_entity(MockEntity(); discrete = true)
                let third_entity = create_entity(MockEntity(); discrete = true)
                    subscribe!(first_entity, second_entity)
                    subscribe!(second_entity, third_entity)
                    @test !is_subscribed(first_entity, second_entity)
                    @test is_subscribed(second_entity, first_entity)
                    @test !is_subscribed(second_entity, third_entity)
                    @test is_subscribed(third_entity, second_entity)
                end
            end
        end

        # Test self-subscription
        let first_entity = create_entity(MockEntity(); discrete = true)
            @test_throws RxEnvironments.SelfSubscriptionException subscribe!(
                first_entity,
                first_entity,
            )
        end
    end

    @testset "mutual subscribe" begin
        let first_entity = create_entity(MockEntity(); discrete = true)
            let second_entity = create_entity(MockEntity(); discrete = true)
                add!(first_entity, second_entity)
                @test is_subscribed(first_entity, second_entity)
                @test is_subscribed(second_entity, first_entity)
            end
        end
    end

    @testset "unsubscribe" begin
        let first_entity = create_entity(MockEntity(); discrete = true)
            let second_entity = create_entity(MockEntity(); discrete = true)
                first_obs = keep(Any)
                second_obs = keep(Any)
                subscribe_to_observations!(first_entity, first_obs)
                subscribe_to_observations!(second_entity, second_obs)

                add!(first_entity, second_entity)
                # Test that we can send messages from first_entity to second_entity
                @test send!(first_entity, second_entity, 1) isa Any

                unsubscribe!(first_entity, second_entity)
                @test !is_subscribed(second_entity, first_entity)
                @test_throws RxEnvironments.NotSubscribedException send!(
                    second_entity,
                    first_entity,
                    1,
                )
            end
        end
    end

    @testset "receive observations" begin
        import RxEnvironments: data

        # Test simple case of two interacting entities
        let first_entity = create_entity(MockEntity(); discrete = true)
            let second_entity = create_entity(MockEntity(); discrete = true)
                first_obs = keep(Any)
                second_obs = keep(Any)
                subscribe_to_observations!(first_entity, first_obs)
                subscribe_to_observations!(second_entity, second_obs)

                add!(first_entity, second_entity)

                # Test that we correctly receive observations in first_entity
                send!(first_entity, second_entity, 1)
                @test data.(first_obs.values) == [1]
                # Test that second_entity does not receive observations
                @test length(second_obs) == 0

                send!(first_entity, second_entity, nothing)
                @test data.(first_obs.values) == [1, nothing]
                @test length(second_obs) == 0

                # Test that we correctly receive observations in second_entity
                send!(second_entity, first_entity, 2)
                @test data.(second_obs.values) == [2]
                # Test that first_entity does not receive observations
                @test data.(first_obs.values) == [1, nothing]

                send!(second_entity, first_entity, nothing)
                @test data.(second_obs.values) == [2, nothing]
                @test data.(first_obs.values) == [1, nothing]
            end
        end

        # Test case of three interacting entities
        # Subscriptions:
        # first_entity <-> second_entity <-> third_entity
        let first_entity = create_entity(MockEntity(); discrete = true)
            let second_entity = create_entity(MockEntity(); discrete = true)
                let third_entity = create_entity(MockEntity(); discrete = true)
                    first_obs = keep(Any)
                    second_obs = keep(Any)
                    third_obs = keep(Any)
                    subscribe_to_observations!(first_entity, first_obs)
                    subscribe_to_observations!(second_entity, second_obs)
                    subscribe_to_observations!(third_entity, third_obs)

                    add!(first_entity, second_entity)
                    add!(second_entity, third_entity)

                    # Test that we correctly receive observations in first_entity
                    send!(first_entity, second_entity, 1)
                    @test data.(first_obs.values) == [1]
                    # Test that second_entity does not receive observations
                    @test length(second_obs) == 0
                    # Test that third_entity does not receive observations
                    @test length(third_obs) == 0
                    # Test that we can't send messages from third_entity to first_entity
                    @test_throws RxEnvironments.NotSubscribedException send!(
                        third_entity,
                        first_entity,
                        1,
                    )

                    send!(third_entity, second_entity, 2)
                    @test data.(third_obs.values) == [2]
                    @test length(second_obs) == 0
                    @test length(first_obs) == 1

                    # Test that second_entity receives observations only when first_entity and third_entity have emitted
                    send!(second_entity, first_entity, 1)
                    @test length(second_obs) == 0
                    send!(second_entity, third_entity, 2)
                    @test length(second_obs) == 1
                end
            end
        end
    end

    @testset "send message" begin
        let first_entity = create_entity(MockEntity(); discrete = true)
            obs = keep(Any)
            subscribe!(first_entity, obs)
            send!(obs, first_entity, 1)
            @test last(obs) == 1
            send!(obs, first_entity, 2)
            @test last(obs) == 2
        end
    end

    @testset "emits" begin
        import RxEnvironments: emits, decorated

        # Test that by default we always emit
        let first_entity = create_entity(MockEntity(); discrete = true)
            let second_entity = create_entity(MockEntity(); discrete = true)
                add!(first_entity, second_entity)
                @test emits(decorated(first_entity), decorated(second_entity), nothing) ==
                      true
                @test emits(decorated(second_entity), decorated(first_entity), nothing) ==
                      true
            end
        end

        # Test that we can trigger emission behaviour
        let first_entity = create_entity(
                SelectiveSendingEntity();
                is_environment = true,
                discrete = true,
            )
            let second_entity = create_entity(SelectiveReceivingEntity(); discrete = true)
                # Assert that we only block emission if the incoming message is `Nothing`
                @test emits(decorated(first_entity), decorated(second_entity), nothing) ==
                      false
                @test emits(decorated(first_entity), decorated(second_entity), 1) == true

                # Keep track of the observations of second_entity
                obs = keep(Any)
                subscribe_to_observations!(second_entity, obs)

                add!(first_entity, second_entity)
                # If we send an integer from second_entity to first_entity, second_entity should receive an observation
                send!(first_entity, second_entity, 1)
                @test length(obs) == 1

                # If we send `nothing` from second_entity to first_entity, second_entity should not receive an additional observation
                send!(first_entity, second_entity, nothing)
                @test_broken length(obs) == 1
            end
        end
    end

    @testset "terminate!" begin
        import RxEnvironments: terminate!, is_terminated

        let first_entity = create_entity(MockEntity(); discrete = true)
            let second_entity = create_entity(MockEntity(); discrete = true)
                add!(first_entity, second_entity)

                @test is_subscribed(first_entity, second_entity)
                @test is_subscribed(second_entity, first_entity)
                @test !is_terminated(first_entity)

                terminate!(first_entity)

                @test !is_subscribed(first_entity, second_entity)
                @test !is_subscribed(second_entity, first_entity)
                @test is_terminated(first_entity)
            end
        end
    end

    @testset "impossible to add timer" begin
        import RxEnvironments: add_timer!

        let e = create_entity(MockEntity(); discrete = true)
            @test_throws MethodError add_timer!(e, 1000)
        end
    end

    # @testset "selective message sending" begin

    # end
end

@testitem "mixed state space" begin
    using RxEnvironments
    include("mockenvironment.jl")

    @testset "mix state-spaces" begin
        # Test that mixing of state spaces is not allowed
        let first_entity = create_entity(MockEntity(); discrete = true)
            let second_entity = create_entity(MockEntity())
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

    @testset "add! adds same state-space entity" begin
        import RxEnvironments: add!, state_space

        let e = create_entity(MockEntity())
            result = add!(e, MockEntity())
            @test state_space(result) === RxEnvironments.ContinuousEntity()
        end

        let e = create_entity(MockEntity(); discrete = true)
            result = add!(e, MockEntity())
            @test state_space(result) === RxEnvironments.DiscreteEntity()
        end
    end
end
