using Rocket

export RxEnvironment, add!



RxEnvironment(environment; real_time_factor = nothing, emit_every_ms = nothing) = RxEnvironment(environment, real_time_factor, emit_every_ms)
RxEnvironment(environment, real_time_factor::Nothing, emit_every_ms::Int64) =
    RxEnvironment(environment, 1.0, emit_every_ms)
RxEnvironment(environment, real_time_factor::Float64, emit_every_ms::Int64) =
    TimerEnvironment(environment, real_time_factor, emit_every_ms)
RxEnvironment(environment, real_time_factor::Nothing, emit_every_ms::Nothing) =
    DiscreteEnvironment(environment)
