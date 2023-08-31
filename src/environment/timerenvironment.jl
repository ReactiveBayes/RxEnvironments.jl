using Rocket


struct TimerEnvironment{T} <: AbstractEnvironment{T}
    entity::T
    markov_blanket::MarkovBlanket
    clock::Clock
    terminated::Terminated
end

function TimerEnvironment(environment, real_time_factor::Float64, emit_every_ms::Int64)
    c = Clock(real_time_factor, emit_every_ms)
    env = TimerEnvironment(environment, MarkovBlanket(), c, Terminated(false))
    instantiate!(env)
    add_timer!(env, c)
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

function update!(env::TimerEnvironment)
    update!(environment(env), elapsed_time(clock(env)))
    set_last_update!(clock(env), time(clock(env)))
end
