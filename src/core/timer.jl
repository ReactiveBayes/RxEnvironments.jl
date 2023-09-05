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

Clock(real_time_factor, emit_every_ms) =
    Clock(TimeStamp(time()), TimeStamp(0), real_time_factor, Rocket.interval(emit_every_ms))

start_time(clock::Clock) = time(clock.start_time)
last_update(clock::Clock) = time(clock.last_update)
set_last_update!(clock::Clock, time::Real) = clock.last_update.time = time
real_time_factor(clock::Clock) = clock.real_time_factor
timer(clock::Clock) = clock.timer

Rocket.subscribe!(clock::Clock, actor::Rocket.Actor) =
    Rocket.subscribe!(timer(clock), actor)

function Base.time(clock::Clock)
    return (time() - start_time(clock)) / real_time_factor(clock)
end


function elapsed_time(clock::Clock)
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
    @error "Error in TimerActor" exception=(error, catch_backtrace())
end
