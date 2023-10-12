
@testitem "NotSubscribedException" begin
    using RxEnvironments

    include("../mockenvironment.jl")

    env = RxEnvironment(MockEnvironment(0.0))
    agent = MockAgent()
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

    include("../mockenvironment.jl")

    env = RxEnvironment(MockEnvironment(0.0))
    agent = MockAgent()
    import RxEnvironments: MixedStateSpaceException, first_entity, second_entity
    let exception = MixedStateSpaceException(env, agent)
        @test exception isa MixedStateSpaceException
        @test first_entity(exception) === env
        @test second_entity(exception) === agent
        @test_throws MixedStateSpaceException throw(exception)
    end
end
