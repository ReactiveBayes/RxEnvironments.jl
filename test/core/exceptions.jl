module TestExceptions

using ReTest
using RxEnvironments
import RxEnvironments: NotSubscribedException, origin, recipient

include("../mockenvironment.jl")

env = RxEnvironment(MockEnvironment(0.0))
agent = MockAgent()

@testset "NotSubscribedException" begin

    let exception = NotSubscribedException(env, agent)
        @test exception isa NotSubscribedException
        @test origin(exception) === env
        @test recipient(exception) === agent
        @test_throws NotSubscribedException throw(exception)
    end

end

end
