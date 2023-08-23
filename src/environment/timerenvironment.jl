struct TimerMessage end

mutable struct TimeStamp
    time::Float64
end

Base.time(time::TimeStamp) = time.time

struct TimerEnvironment <: AbstractEnvironment
    entity::Any
    observations::Rocket.RecentSubjectInstance
    actions::AbstractDict{Any,Rocket.RecentSubjectInstance}
    start_time::TimeStamp
    last_update::TimeStamp
    real_time_factor::Float64
    timer::Rocket.TimerObservable
end

function TimerEnvironment(environment, real_time_factor::Float64, emit_every_ms::Int64)
    env = TimerEnvironment(
        environment,
        RecentSubject(Any),
        Dict{Any,Rocket.RecentSubjectInstance}(),
        TimeStamp(time()),
        TimeStamp(0),
        real_time_factor,
        Rocket.interval(emit_every_ms)
    )
    instantiate!(env)
    subscribe!(env.timer, TimerActor(env))
    @show env
    return env
end

start_time(environment::TimerEnvironment) = time(environment.start_time)
last_update(environment::TimerEnvironment) = time(environment.last_update)
real_time_factor(environment::TimerEnvironment) = environment.real_time_factor

function Base.show(io::IO, environment::TimerEnvironment)
    println(io, "Timed RxEnvironment, emitting every $(environment.timer.period) milliseconds, on a clock speed of $(environment.real_time_factor) times real time.")
    println(io, "Subscribed entities: $(keys(environment.actions))")
end

function set_last_update!(environment::TimerEnvironment, time::Float64)
    environment.last_update.time = time
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
    @error "Error in TimerActor for environment " exception=(error, catch_backtrace())
end


act!(recepient::TimerEnvironment, action::TimerMessage) = nothing