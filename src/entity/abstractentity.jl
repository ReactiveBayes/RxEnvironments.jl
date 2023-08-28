using Rocket

export AbstractEntity, add!, act!, update!, observe, is_subscribed, subscribed_entities, subscribed_to

"""
    AbstractEntity

The AbstractEntity type supertypes all entities. It describes basic functionality all entities should have.
"""
abstract type AbstractEntity end

entity(entity::AbstractEntity) = entity.entity
observations(entity::AbstractEntity) = observations(markov_blanket(entity))
actuators(entity::AbstractEntity) = actuators(markov_blanket(entity))
sensors(entity::AbstractEntity) = sensors(markov_blanket(entity))
subscribed_entities(entity::AbstractEntity) = collect(keys(actuators(entity)))
subscribed_to(entity::AbstractEntity) = collect(keys(sensors(entity)))
markov_blanket(entity::AbstractEntity) = entity.markov_blanket
get_actuator(emitter::AbstractEntity, recipient::AbstractEntity) = get_actuator(markov_blanket(emitter), recipient)

function __add!(first::AbstractEntity, second::AbstractEntity)
    subscribe!(first, second)
    subscribe!(second, first)
end

function update! end
function act! end
function observe end
function state end

observe(subject::AbstractEntity, environment) = observe(entity(subject), environment)
observe(subject, environment) = state(environment)

act!(subject::AbstractEntity, action::Observation) = act!(subject, emitter(action), data(action))
act!(recipient::AbstractEntity, sender::AbstractEntity, action::Any) =
    act!(entity(recipient), entity(sender), action)
act!(recipient::AbstractEntity, sender::Any, action::Any) =
    act!(entity(recipient), sender, action)

state(subject::AbstractEntity) = state(entity(subject))

function inspect_observations(entity::AbstractEntity, actor)
    subscribe!(observations(entity), actor)
    return actor
end

Base.show(io::IO, entity::AbstractEntity) = println(io, "AbstractEntity $(typeof(entity))")


function is_subscribed(subject::AbstractEntity, target::AbstractEntity)
    return haskey(actuators(markov_blanket(target)), subject) && haskey(sensors(markov_blanket(subject)), target)
end

function is_subscribed(subject::Rocket.Actor{Any}, target::AbstractEntity)
    return haskey(actuators(markov_blanket(target)), subject)
end