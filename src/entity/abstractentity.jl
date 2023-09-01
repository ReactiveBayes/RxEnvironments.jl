using Rocket

export AbstractEntity,
    add!,
    act!,
    update!,
    observe,
    is_subscribed,
    subscribers,
    subscribed_to,
    terminate!,
    is_terminated

"""
    AbstractEntity{T}

The AbstractEntity type supertypes all entities. It describes basic functionality all entities should have. It is assumed that every 
entity has a markov blanket, which has actuators and sensors. The AbstractEntity also has a field that describes whether or not the
entity is terminated. 
"""
abstract type AbstractEntity{T} end

entity(entity::AbstractEntity) = entity.entity
observations(entity::AbstractEntity) = observations(markov_blanket(entity))
actuators(entity::AbstractEntity) = actuators(markov_blanket(entity))
sensors(entity::AbstractEntity) = sensors(markov_blanket(entity))
subscribers(entity::AbstractEntity) = collect(keys(actuators(entity)))
subscribed_to(entity::AbstractEntity) = collect(keys(sensors(entity)))
markov_blanket(entity::AbstractEntity) = entity.markov_blanket
get_actuator(emitter::AbstractEntity, recipient::AbstractEntity) =
    get_actuator(markov_blanket(emitter), recipient)
is_terminated(entity::AbstractEntity) = is_terminated(entity.terminated)

"""


"""
function add!(first::AbstractEntity, second::AbstractEntity)
    subscribe!(first, second)
    subscribe!(second, first)
end

function update! end

function terminate!(entity::AbstractEntity)
    terminate!(entity.terminated)
    for subscriber in subscribers(entity)
        unsubscribe!(entity, subscriber)
    end
    for subscribed_to in subscribed_to(entity)
        unsubscribe!(subscribed_to, entity)
    end
end

observe(subject::AbstractEntity, environment) = observe(entity(subject), environment)

act!(subject::AbstractEntity, action::Observation) =
    act!(subject, emitter(action), data(action))
act!(recipient::AbstractEntity, sender::AbstractEntity, action::Any) =
    act!(entity(recipient), entity(sender), action)
act!(recipient::AbstractEntity, sender::Any, action::Any) =
    act!(entity(recipient), sender, action)


function subscribe_to_observations!(entity::AbstractEntity, actor)
    subscribe!(observations(entity), actor)
    return actor
end

Base.show(io::IO, entity::AbstractEntity) = println(io, "AbstractEntity $(typeof(entity))")


function is_subscribed(subject::AbstractEntity, target::AbstractEntity)
    return haskey(actuators(markov_blanket(target)), subject) &&
           haskey(sensors(markov_blanket(subject)), target)
end

function is_subscribed(subject::Rocket.Actor{Any}, target::AbstractEntity)
    return haskey(actuators(markov_blanket(target)), subject)
end

function add_timer!(entity::AbstractEntity, emit_every_ms; real_time_factor::Real=1.0)
    @assert real_time_factor > 0.0
    c = Clock(real_time_factor, emit_every_ms)
    add_timer!(entity, c)
end

function add_timer!(entity::AbstractEntity, clock::Clock)
    actor = TimerActor(entity)
    subscribe!(timer(clock), actor)
end
