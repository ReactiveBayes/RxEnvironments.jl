
@testitem "NotSubscribedException" begin
    using RxEnvironments

    include("mockenvironment.jl")

    env = RxEnvironment(MockEnvironment())
    agent = MockEntity()
    import RxEnvironments: NotSubscribedException, origin, recipient
    let exception = NotSubscribedException(env, agent)
        @test exception isa NotSubscribedException
        @test origin(exception) === env
        @test recipient(exception) === agent
        @test_throws NotSubscribedException throw(exception)
    end

end

@testitem "MixedStateSpaceException" begin
    using RxEnvironments

    include("mockenvironment.jl")

    env = RxEnvironment(MockEnvironment())
    agent = MockEntity()
    import RxEnvironments: MixedStateSpaceException, first_entity, second_entity
    let exception = MixedStateSpaceException(env, agent)
        @test exception isa MixedStateSpaceException
        @test first_entity(exception) === env
        @test second_entity(exception) === agent
        @test_throws MixedStateSpaceException throw(exception)
    end
end

@testitem "SelfSubscriptionException" begin
    using RxEnvironments

    include("mockenvironment.jl")

    env = create_entity(MockEnvironment())
    import RxEnvironments: SelfSubscriptionException, entity
    let exception = SelfSubscriptionException(env)
        @test exception isa SelfSubscriptionException
        @test entity(exception) === env
        @test_throws SelfSubscriptionException throw(exception)
    end
end