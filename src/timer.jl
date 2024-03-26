using Rocket

export pause!, resume!

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
pause!(::ManualClock) = @warn "Clock with manual control cannot be paused"

struct IsPaused end
struct IsNotPaused end

mutable struct PausedInformation{T}
    paused::T
    time_paused::TimeStamp
    total_time_paused::Float64
end
PausedInformation() = PausedInformation(IsNotPaused(), TimeStamp(0), 0.0)

is_paused(pause::PausedInformation{IsPaused}) = true
is_paused(pause::PausedInformation{IsNotPaused}) = false
time_paused(pause::PausedInformation{IsPaused}) = time(pause.time_paused)
time_paused(pause::PausedInformation{IsNotPaused}) = throw(NotPausedException())

function total_time_paused(pause::PausedInformation{IsPaused}, current_time::Float64)
    return pause.total_time_paused + (current_time - time_paused(pause))
end

function total_time_paused(pause::PausedInformation{IsNotPaused}, ::Float64)
    return pause.total_time_paused
end


mutable struct WallClock <: Clock
    start_time::TimeStamp
    last_update::TimeStamp
    real_time_factor::Float64
    paused::PausedInformation
end

function WallClock(real_time_factor::Real)
    return WallClock(TimeStamp(time()), TimeStamp(0), real_time_factor, PausedInformation())
end

start_time(clock::WallClock) = time(clock.start_time)
last_update(clock::WallClock) = time(clock.last_update)
set_last_update!(clock::WallClock, time::Real) = clock.last_update.time = time
real_time_factor(clock::WallClock) = clock.real_time_factor
total_time_paused(clock::WallClock, current_time::Float64) =
    total_time_paused(clock.paused, current_time)

function pause!(clock::WallClock)
    current_time = time()
    clock.paused = PausedInformation(
        IsPaused(),
        TimeStamp(current_time),
        total_time_paused(clock, current_time),
    )
end

function resume!(clock::WallClock)
    current_time = time()
    clock.paused = PausedInformation(
        IsNotPaused(),
        TimeStamp(current_time),
        total_time_paused(clock, current_time),
    )
end

function Base.time(clock::WallClock)
    current_time = time()
    return (current_time - start_time(clock) - total_time_paused(clock, current_time)) /
           real_time_factor(clock)
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

mutable struct Timer
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

function terminate!(timer::Timer)
    unsubscribe!(timer.subscription)
    # TODO terminate TimerObservable
end

terminate!(::Nothing) = nothing
pause!(x) = nothing
resume!(x) = nothing

function pause!(timer::Timer)
    unsubscribe!(timer.subscription)
end

function resume!(timer::Timer)
    timer.subscription = subscribe!(timer.timer, timer.actor)
end
