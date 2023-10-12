using Rocket

struct IsEnvironment end
struct IsNotEnvironment end

struct DiscreteEntity end
struct ContinuousEntity end

export AbstractEntity,
    add!,
    send!,
    update!,
    receive!,
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

decorated(entity::AbstractEntity) = entity.decorated
markov_blanket(entity::AbstractEntity) = entity.markov_blanket
properties(entity::AbstractEntity) = entity.properties
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

get_actuator(emitter::AbstractEntity, recipient) =
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
    add_to_state!(decorated(emitter), decorated(receiver))
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

Update the state of the entity `e` based on its current state and the time elapsed since the last update. Acts as state transition function.

# Arguments
- `e::AbstractEntity{T,ContinuousEntity,E}`: The entity to update.
"""
function update!(e::AbstractEntity{T,ContinuousEntity,E}) where {T,E}
    c = clock(e)
    update!(decorated(e), elapsed_time(c))
    set_last_update!(c, time(c))
end

update!(e::AbstractEntity{T,DiscreteEntity,E}) where {T,E} = update!(decorated(e))

"""
    send!(recipient::AbstractEntity, emitter::AbstractEntity, action::Any)

Send an action from `emitter` to `recipient`.
"""
function send!(
    recipient::Union{AbstractEntity,Rocket.Actor},
    emitter::AbstractEntity,
    action::Any,
)
    actuator = get_actuator(emitter, recipient)
    send_action!(actuator, action)
end

"""
    send!(recipient::AbstractEntity, emitter::AbstractEntity)

Send an action from `emitter` to `recipient`. Should use the state of `emitter` to determine the action to send.

See also: [`RxEnvironments.receive!`](@ref)
"""
function send!(recipient::AbstractEntity, emitter::AbstractEntity)
    action = send!(decorated(recipient), decorated(emitter))
    send!(recipient, emitter, action)
end

function send!(recipient::Rocket.Actor{Any}, emitter::AbstractEntity)
    action = send!(recipient, decorated(emitter))
    send!(recipient, emitter, action)
end

send!(recipient, emitter::AbstractEntity) = send!(recipient, decorated(emitter))
send!(recipient, emitter) = nothing
send!(recipient, emitter, received_data) = send!(recipient, emitter)

function receive!(recipient::AbstractEntity, observations::ObservationCollection)
    for observation in observations
        receive!(recipient, observation)
    end
end

"""
    receive!(recipient::AbstractEntity, emitter::AbstractEntity, observation::Any)

Receive an observation from `emitter` and update the state of `recipient` accordingly.

See also: [`RxEnvironments.send!`](@ref)
"""
receive!(recipient::AbstractEntity, observation::Observation) =
    receive!(recipient, emitter(observation), data(observation))
receive!(recipient::AbstractEntity, emitter::AbstractEntity, observation::Any) =
    receive!(decorated(recipient), decorated(emitter), observation)
receive!(recipient::AbstractEntity, observation::Any) = nothing
receive!(recipient, emitter, observation) = nothing

emits(subject::AbstractEntity, listener::AbstractEntity, observation::TimerMessage) =
    emits(decorated(subject), decorated(listener), observation)
emits(subject::AbstractEntity, listener::AbstractEntity, observation::Observation) =
    emits(decorated(subject), decorated(listener), data(observation))

"""
    emits(subject, listener, observation)

Determines if an entity of the type of `subject` should emit an observation to an entity of the type of `listener` when presented with an obervation of type `observation`.
Users should implement this function for their own entity and observation types to handle the logic of when to emit observations to which entities. By default, this function returns `true`.
"""
emits(subject, listener, observation::Any) = true


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
