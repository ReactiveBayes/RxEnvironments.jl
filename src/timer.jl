using Rocket

abstract type Clock end

mutable struct TimeStamp
    time::Float64
end

Base.time(time::TimeStamp) = time.time

struct ManualClock <: Clock
    last_update::TimeStamp
end

ManualClock() = ManualClock(TimeStamp(0))

start_time(clock::ManualClock) = 0.0
last_update(clock::ManualClock) = time(clock.last_update)
elapsed_time(::ManualClock) = error("elapsed_time not defined for ManualClock")
set_last_update!(clock::ManualClock, time::Real) = clock.last_update.time = time
add_elapsed_time!(clock::ManualClock, elapsed_time::Real) =
    elapsed_time >= 0 ? clock.last_update.time += elapsed_time :
    error("Cannot go back in time")
Base.time(clock::ManualClock) = last_update(clock)

struct WallClock <: Clock
    start_time::TimeStamp
    last_update::TimeStamp
    real_time_factor::Real
end

function WallClock(real_time_factor::Real)
    return WallClock(TimeStamp(time()), TimeStamp(0), real_time_factor)
end

start_time(clock::WallClock) = time(clock.start_time)
last_update(clock::WallClock) = time(clock.last_update)
set_last_update!(clock::WallClock, time::Real) = clock.last_update.time = time
real_time_factor(clock::WallClock) = clock.real_time_factor

function Base.time(clock::WallClock)
    return (time() - start_time(clock)) / real_time_factor(clock)
end

function elapsed_time(clock::WallClock)
    return time(clock) - last_update(clock)
end


struct TimerActor{T} <: Rocket.Actor{Int}
    entity::T
end

entity(actor::TimerActor) = actor.entity

function Rocket.on_next!(actor::TimerActor, time::Int)
    next!(observations(entity(actor)), TimerMessage())
end

function Rocket.on_error!(actor::TimerActor, error)
    @error "Error in TimerActor" exception = (error, catch_backtrace())
end

struct Timer
    timer::Rocket.TimerObservable
    actor::TimerActor
    subscription::Any
end

function Timer(emit_every_ms::Int, entity)
    timer = Rocket.interval(emit_every_ms)
    actor = TimerActor(entity)
    subscription = subscribe!(timer, actor)
    return Timer(timer, actor, subscription)
end
