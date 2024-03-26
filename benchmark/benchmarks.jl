using BenchmarkTools

const SUITE = BenchmarkGroup()

include("mockenv.jl")

function discrete_benchmarks()
    SUITE = BenchmarkGroup(["Discrete Environment"])
    env = RxEnvironment(MockEnvironment; is_discrete=true)
    agent = add!(env, MockEntity())
    SUITE["send to agent"] = @benchmarkable send!($agent, $env, 10.0)
    SUITE["send to environment"] = @benchmarkable send!($env, $agent, 10.0)
    return SUITE
end

function continuous_benchmarks()
    SUITE = BenchmarkGroup(["Continuous Environment"])
    env = RxEnvironment(MockEnvironment; is_discrete=false)
    agent = add!(env, MockEntity())
    SUITE["send to agent"] = @benchmarkable send!($agent, $env, 10.0)
    SUITE["send to environment"] = @benchmarkable send!($env, $agent, 10.0)
    return SUITE
end

SUITE["Discrete Environment"] = discrete_benchmarks()
SUITE["Continuous Environment"] = continuous_benchmarks()