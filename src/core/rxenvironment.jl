using Rocket

export RxEnvironment, add!

function RxEnvironment(
    environment;
    discrete::Bool = false,
    emit_every_ms::Int = 1000,
    real_time_factor::Real = 1.0,
)
    state_space = discrete ? Discrete() : Continuous()
    entity = create_entity(environment, state_space, IsEnvironment())
    if !discrete
        add_timer!(entity, emit_every_ms; real_time_factor = real_time_factor)
    end
    return entity
end
