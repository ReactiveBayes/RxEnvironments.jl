using Rocket

export AbstractEntity, add!, act!, update!, observe

"""
    AbstractEntity

The AbstractEntity type supertypes all entities. It describes basic functionality all entities should have.
"""
abstract type AbstractEntity end

entity(entity::AbstractEntity) = entity.entity
observations(entity::AbstractEntity) = entity.observations
actions(entity::AbstractEntity) = entity.actions
actions(entity::AbstractEntity, recipient::Any) = entity.actions[recipient]
subscribed_entities(entity::AbstractEntity) = collect(keys(actions(entity)))

Rocket.next!(entity::AbstractEntity, recipient::AbstractEntity, action) =
    next!(actions(entity, recipient), action)
function Rocket.subscribe!(entity::AbstractEntity, observer::AbstractEntity)
    mbactor = MarkovBlanketActor(entity, observer)
    actions(entity)[observer] = RecentSubject(Any)
    subscription = subscribe!(actions(entity, observer), mbactor)
end

function Rocket.subscribe!(entity::AbstractEntity, observer::Rocket.Actor{Any})
    actions(entity)[observer] = RecentSubject(Any)
    subscription = subscribe!(actions(entity, observer), observer)
end


function __add!(first::AbstractEntity, second::AbstractEntity)
    subscribe!(first, second)
    subscribe!(second, first)
end

function update! end
function act! end
function observe end
observe(receiver, sender, stimulus) = stimulus
act!(subject::AbstractEntity, action::Message) = act!(subject, sender(action), data(action))
act!(recipient::AbstractEntity, sender::AbstractEntity, action::Any) =
    act!(entity(recipient), entity(sender), action)
act!(recipient::AbstractEntity, sender::Any, action::Any) =
    act!(entity(recipient), sender, action)

function inspect_observations(entity::AbstractEntity)
    actor = keep(Any)
    subscribe!(observations(entity), actor)
    return actor
end

function inspect_observations(entity::AbstractEntity, actor)
    subscribe!(observations(entity), actor)
    return actor
end

Base.show(io::IO, entity::AbstractEntity) = println(io, "AbstractEntity $(typeof(entity))")
