using Rocket

mutable struct TimeStamp
    time::Float64
end

Base.time(time::TimeStamp) = time.time

struct Clock
    start_time::TimeStamp
    last_update::TimeStamp
    real_time_factor::Real
    timer::Rocket.TimerObservable
end

start_time(clock::Clock) = time(clock.start_time)
last_update(clock::Clock) = time(clock.last_update)
real_time_factor(clock::Clock) = clock.real_time_factor
timer(clock::Clock) = clock.timer

Rocket.subscribe!(clock::Clock, actor::Rocket.Actor) = Rocket.subscribe!(timer(clock), actor)

struct TimerEnvironment{T} <: AbstractEnvironment{T}
    entity::T
    markov_blanket::MarkovBlanket
    clock::Clock
end

function TimerEnvironment(environment, real_time_factor::Float64, emit_every_ms::Int64)
    c = Clock(
        TimeStamp(time()),
        TimeStamp(0),
        real_time_factor,
        Rocket.interval(emit_every_ms),
    )
    env = TimerEnvironment(
        environment,
        MarkovBlanket(),
        c,
    )
    instantiate!(env)
    subscribe!(clock(env), TimerActor(env))
    return env
end

clock(environment::TimerEnvironment) = environment.clock

start_time(environment::TimerEnvironment) = start_time(clock(environment))
last_update(environment::TimerEnvironment) = last_update(clock(environment))
real_time_factor(environment::TimerEnvironment) = real_time_factor(clock(environment))
timer(environment::TimerEnvironment) = timer(clock(environment))

function Base.show(io::IO, environment::TimerEnvironment)
    println(
        io,
        "Timed RxEnvironment, emitting every $(timer(environment).period) milliseconds, on a clock speed of $(real_time_factor(environment)) times real time.",
    )
end

function set_last_update!(environment::TimerEnvironment, time::Float64)
    environment.clock.last_update.time = time
end

function Base.time(environment::AbstractEnvironment)
    return (time() - start_time(environment)) / real_time_factor(environment)
end

function elapsed_time(environment::TimerEnvironment)
    return time(environment) - last_update(environment)
end

function update!(env::TimerEnvironment)
    update!(environment(env), elapsed_time(env))
    set_last_update!(env, time(env))
end

struct TimerActor <: Rocket.Actor{Int}
    environment::TimerEnvironment
end

environment(actor::TimerActor) = actor.environment

function Rocket.on_next!(actor::TimerActor, time::Int)
    next!(observations(environment(actor)), TimerMessage())
end

function Rocket.on_error!(actor::TimerActor, error)
    @error "Error in TimerActor for environment " exception = (error, catch_backtrace())
end


act!(recepient::TimerEnvironment, action::TimerMessage) = nothing
