using Rocket

struct IsEnvironment end
struct IsNotEnvironment end

struct DiscreteEntity end
struct ContinuousEntity end

export AbstractEntity,
    add!,
    act!,
    update!,
    observe,
    is_subscribed,
    subscribers,
    subscribed_to,
    terminate!,
    is_terminated,
    animate_state,
    subscribe_to_observations!

"""
    AbstractEntity{T}

The AbstractEntity type supertypes all entities. It describes basic functionality all entities should have. It is assumed that every 
entity has a markov blanket, which has actuators and sensors. The AbstractEntity also has a field that describes whether or not the
entity is terminated. 
"""
abstract type AbstractEntity{T,S,E} end

entity(entity::AbstractEntity) = entity.entity
markov_blanket(entity::AbstractEntity) = entity.markov_blanket
is_terminated(entity::AbstractEntity) = is_terminated(properties(entity).terminated)
state_space(entity::AbstractEntity) = properties(entity).state_space
clock(entity::AbstractEntity) = properties(entity).clock

last_update(entity::AbstractEntity{T,ContinuousEntity,E}) where {T,E} =
    last_update(clock(entity))

observations(entity::AbstractEntity) = observations(markov_blanket(entity))
actuators(entity::AbstractEntity) = actuators(markov_blanket(entity))
sensors(entity::AbstractEntity) = sensors(markov_blanket(entity))
subscribers(entity::AbstractEntity) = collect(keys(actuators(entity)))
subscribed_to(entity::AbstractEntity) = collect(keys(sensors(entity)))

get_actuator(emitter::AbstractEntity, recipient::AbstractEntity) =
    get_actuator(markov_blanket(emitter), recipient)

Rocket.subscribe!(first::AbstractEntity, second::AbstractEntity) =
    throw(MixedStateSpaceException(first, second))

function Rocket.subscribe!(
    emitter::AbstractEntity{T,S,E} where {T,E},
    receiver::AbstractEntity{O,S,P} where {O,P},
) where {S}
    actuator = Actuator()
    insert!(actuators(markov_blanket(emitter)), receiver, actuator)
    add_sensor!(markov_blanket(receiver), emitter, receiver)
    add_to_state!(entity(emitter), entity(receiver))
end

function Rocket.subscribe!(emitter::AbstractEntity, receiver::Rocket.Actor{T} where {T})
    actuator = Actuator()
    insert!(actuators(emitter), receiver, actuator)
    return subscribe!(actuator, receiver)
end


function subscribe_to_observations!(entity::AbstractEntity, actor)
    subscribe!(observations(entity), actor)
    return actor
end

function Rocket.unsubscribe!(emitter::AbstractEntity, receiver::AbstractEntity)
    Rocket.unsubscribe!(sensors(receiver)[emitter])
    delete!(sensors(receiver), emitter)
    delete!(actuators(emitter), receiver)
end

function Rocket.unsubscribe!(
    emitter::AbstractEntity,
    actor::Rocket.Actor,
    subscription::Teardown,
)
    delete!(actuators(emitter), actor)
    unsubscribe!(subscription)
end

"""
    add!(first::AbstractEntity{T,S,E}, second; environment=false) where {T,S,E}

Adds `second` to `first`. If `environment` is `true`, the `AbstractEntity` created for `second` will be labeled as an environment. 
The Markov Blankets for both entities will be subscribed to each other.

# Arguments
- `first::AbstractEntity{T,S,E}`: The entity to which `second` will be added.
- `second`: The entity to be added to `first`.
- `environment=false`: A boolean indicating whether `second` should be instantiated as an environment.
"""
function add!(first::AbstractEntity{T,S,E}, second; environment = false) where {T,S,E}
    environment = environment ? IsEnvironment() : IsNotEnvironment()
    entity = create_entity(second, state_space(first), environment)
    add!(first, entity)
    return entity
end

function add!(
    first::AbstractEntity{T,S,E} where {T,E},
    second::AbstractEntity{O,S,P} where {O,P},
) where {S}
    subscribe!(first, second)
    subscribe!(second, first)
end

add!(first::AbstractEntity, second::AbstractEntity) =
    throw(MixedStateSpaceException(first, second))

"""
    is_subscribed(subject::AbstractEntity, target::AbstractEntity)

Check if `subject` is subscribed to `target`.

# Arguments
- `subject::AbstractEntity`: The entity that may be subscribed to `target`.
- `target::AbstractEntity`: The entity that may be subscribed to by `subject`.

# Returns
`true` if `subject` is subscribed to `target`, `false` otherwise.
"""
function is_subscribed(subject::AbstractEntity, target::AbstractEntity)
    return haskey(actuators(markov_blanket(target)), subject) &&
           haskey(sensors(markov_blanket(subject)), target)
end

function is_subscribed(subject::Rocket.Actor{Any}, target::AbstractEntity)
    return haskey(actuators(markov_blanket(target)), subject)
end

"""
    terminate!(entity::AbstractEntity)

Terminate an entity by setting its `is_terminated` flag to `true` and severing off all subscriptions to and from the entity.

# Arguments
- `entity::AbstractEntity`: The entity to terminate.

"""
function terminate!(entity::AbstractEntity)
    terminate!(properties(entity).terminated)
    for subscriber in subscribers(entity)
        unsubscribe!(entity, subscriber)
    end
    for subscribed_to in subscribed_to(entity)
        unsubscribe!(subscribed_to, entity)
    end
end

"""
    update!(e::AbstractEntity{T,ContinuousEntity,E}) where {T,E}

Update the state of the entity `e` based on its current state and the time elapsed since the last update. Acts as state transition funciton.

# Arguments
- `e::AbstractEntity{T,ContinuousEntity,E}`: The entity to update.
"""
function update!(e::AbstractEntity{T,ContinuousEntity,E}) where {T,E}
    update!(entity(e), elapsed_time(clock(e)))
    set_last_update!(clock(e), time(clock(e)))
end

update!(e::AbstractEntity{T,DiscreteEntity,E}) where {T,E} = update!(entity(e))

observe(subject::AbstractEntity, environment) = observe(entity(subject), environment)
observe(subject, emitter) = nothing

function act!(subject::AbstractEntity, actions::ObservationCollection)
    for observation in actions
        act!(subject, observation)
    end
end

act!(subject::AbstractEntity, action::Observation) =
    act!(subject, emitter(action), data(action))
act!(recipient::AbstractEntity, sender::AbstractEntity, action::Any) =
    act!(entity(recipient), entity(sender), action)
act!(recipient::AbstractEntity, sender::Any, action::Any) =
    act!(entity(recipient), sender, action)
act!(subject::AbstractEntity, action::Any) = nothing
act!(subject, recipient, action) = nothing


function conduct_action!(emitter::AbstractEntity, receiver::AbstractEntity, action::Any)
    actuator = get_actuator(emitter, receiver)
    send_action!(actuator, action)
end


set_clock!(entity::AbstractEntity, clock::Clock) = properties(entity).clock = clock

function add_timer!(
    entity::AbstractEntity{T,ContinuousEntity,E} where {T,E},
    emit_every_ms::Int;
    real_time_factor::Real = 1.0,
)
    @assert real_time_factor > 0.0
    c = Clock(real_time_factor, emit_every_ms)
    add_timer!(entity, c)
end

function add_timer!(entity::AbstractEntity{T,ContinuousEntity,E} where {T,E}, clock::Clock)
    actor = TimerActor(entity)
    subscribe!(clock, actor)
    set_clock!(entity, clock)
end

function animate_state end
function plot_state end
