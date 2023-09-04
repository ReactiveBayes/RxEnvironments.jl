using Rocket

mutable struct EntityProperties{T}
    state_space::T
    terminated::Terminated
    clock::Union{Clock,Nothing}
end

EntityProperties(state_space) = EntityProperties(state_space, Terminated(false), nothing)

struct EntityActor{S,E} <: Rocket.Actor{Any}
    entity::AbstractEntity{T,S,E} where {T}
end

entity(actor::EntityActor) = actor.entity

function Rocket.on_next!(actor::EntityActor{S,IsEnvironment} where {S}, action)
    update!(entity(actor))
    act!(entity(actor), action)
    for (target, actuator) in pairs(actuators(entity(actor)))
        observation = observe(target, entity(entity(actor)))
        send_action!(actuator, observation)
    end
end

function Rocket.on_next!(actor::EntityActor{S,IsNotEnvironment} where {S}, action)
    act!(entity(actor), action)
end

struct RxEntity{T,S,E} <: AbstractEntity{T,S,E}
    entity::T
    markov_blanket::MarkovBlanket
    properties::EntityProperties{S}
    is_environment::E
end

properties(entity::RxEntity) = entity.properties

function create_entity(entity; state_space::Bool = true, is_environment::Bool = false)
    state_space = state_space ? ContinuousEntity() : DiscreteEntity()
    is_environment = is_environment ? IsEnvironment() : IsNotEnvironment()
    return create_entity(entity, state_space, is_environment)
end

function create_entity(entity, state_space, is_environment)
    result = RxEntity(
        entity,
        MarkovBlanket(state_space),
        EntityProperties(state_space),
        is_environment,
    )
    entity_actor = EntityActor(result)
    subscribe_to_observations!(result, entity_actor)
    return result
end

function Base.:(==)(a::RxEntity, b::RxEntity)
    return a.entity == b.entity
end
