using BenchmarkTools
import RxEnvironments: __send!
const SUITE = BenchmarkGroup()

include("mockenv.jl")
include("complexenv.jl")

function simple_discrete_benchmarks()
    SUITE = BenchmarkGroup(["Simple Discrete Environment"])
    env = RxEnvironment(MockEnvironment(); is_discrete=true)
    agent = add!(env, MockEntity())
    SUITE["send to agent"] = @benchmarkable __send!($agent, $env, 10.0)
    SUITE["send to environment"] = @benchmarkable __send!($env, $agent, 10.0)
    return SUITE
end

function complex_discrete_benchmarks()
    SUITE = BenchmarkGroup(["Complex Discrete Environment"])
    world = create_entity(World(rand(44100), 1, 1); is_active=true, is_discrete=true)
    hearing_aid = create_entity(HearingAid((1.0, 0.0)), is_active=true, is_discrete=true)
    agent = create_entity(RxInferAgent(); is_active=false, is_discrete=true)
    user = create_entity(User(); is_active=false, is_discrete=true)

    add!(world, hearing_aid)
    add!(hearing_aid, agent)
    add!(hearing_aid, user)

    SUITE["send to agent"] = @benchmarkable __send!($hearing_aid, $world, view([1.0, 2.0, 3.0], 1:2))
    SUITE["send to environment"] = @benchmarkable __send!($world, $hearing_aid, 10.0)
    return SUITE
end

function simple_continuous_benchmarks()
    SUITE = BenchmarkGroup(["Simple Continuous Environment"])
    env = RxEnvironment(MockEnvironment(); is_discrete=false)
    agent = add!(env, MockEntity())
    SUITE["send to agent"] = @benchmarkable __send!($agent, $env, 10.0)
    SUITE["send to environment"] = @benchmarkable __send!($env, $agent, 10.0)
    return SUITE
end

function complex_continuous_benchmarks()
    SUITE = BenchmarkGroup(["Complex Continuous Environment"])
    world = create_entity(World(rand(44100), 1, 1); is_active=true)
    hearing_aid = create_entity(HearingAid((1.0, 0.0)), is_active=true)
    agent = create_entity(RxInferAgent(); is_active=false)
    user = create_entity(User(); is_active=false)

    add!(world, hearing_aid)
    add!(hearing_aid, agent)
    add!(hearing_aid, user)

    SUITE["send to agent"] = @benchmarkable __send!($hearing_aid, $world, view([1.0, 2.0, 3.0], 1:2))
    SUITE["send to environment"] = @benchmarkable __send!($world, $hearing_aid, 10.0)
    return SUITE
end

function discrete_benchmarks()
    SUITE = BenchmarkGroup(["Discrete Environment"])
    SUITE["Simple"] = simple_discrete_benchmarks()
    SUITE["Complex"] = complex_discrete_benchmarks()
    return SUITE
end

function continuous_benchmarks()
    SUITE = BenchmarkGroup(["Continuous Environment"])
    SUITE["Simple"] = simple_continuous_benchmarks()
    SUITE["Complex"] = complex_continuous_benchmarks()
    return SUITE
end

SUITE["Discrete Environment"] = discrete_benchmarks()
SUITE["Continuous Environment"] = continuous_benchmarks()