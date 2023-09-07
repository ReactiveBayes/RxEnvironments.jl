using Rocket

mutable struct EntityProperties{S}
    state_space::S
    terminated::Terminated
    clock::Union{Clock,Nothing}
end

EntityProperties(state_space) = EntityProperties(state_space, Terminated(false), nothing)

struct EntityActor{S,E} <: Rocket.Actor{Any}
    entity::AbstractEntity{T,S,E} where {T}
end

entity(actor::EntityActor) = actor.entity

function Rocket.on_next!(actor::EntityActor{S,IsEnvironment} where {S}, observation)
    subject = entity(actor)
    update!(subject)
    receive!(subject, observation)
    for listener in subscribers(subject)
        send!(listener, subject)
    end
end

function Rocket.on_next!(actor::EntityActor{S,IsNotEnvironment} where {S}, observation)
    receive!(entity(actor), observation)
end

struct RxEntity{T,S,E} <: AbstractEntity{T,S,E}
    decorated::T
    markov_blanket::MarkovBlanket
    properties::EntityProperties{S}
    is_environment::E
end

function create_entity(entity; discrete::Bool = false, is_environment::Bool = false)
    state_space = discrete ? DiscreteEntity() : ContinuousEntity()
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
    return a.decorated == b.decorated
end
