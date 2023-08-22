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
actions(entity::AbstractEntity, recipient::AbstractEntity) = entity.actions[recipient]

Rocket.next!(entity::AbstractEntity, recipient::AbstractEntity, action) =
    next!(actions(entity, recipient), action)
Rocket.subscribe!(entity::AbstractEntity, observer::MarkovBlanketActor) =
    subscribe!(observations(entity), observer)
function Rocket.subscribe!(entity::AbstractEntity, observer::AbstractEntity)
    mbactor = MarkovBlanketActor(entity, observer)
    actions(entity)[observer] = RecentSubject(Any)
    subscription = subscribe!(actions(entity, observer), mbactor)
end

function __add!(first::AbstractEntity, second::AbstractEntity)
    subscribe!(first, second)
    subscribe!(second, first)
end

function update! end
function act! end
function observe end
observe(receiver, sender, stimulus) = stimulus
act!(subject::AbstractEntity, action::Message) =
    act!(entity(subject), entity(sender(action)), data(action))
