using Rocket
export create_entity

mutable struct EntityActor{T,S,E} <: Rocket.Actor{Any}
    entity::AbstractEntity{T,S,E}
    subscription::Union{Nothing,Rocket.Teardown}
end

entity(actor::EntityActor) = actor.entity

function Rocket.on_next!(actor::EntityActor{T,S,IsEnvironment} where {T,S}, observation)
    subject = entity(actor)
    update!(subject)
    receive!(subject, observation)
    for listener in subscribers(subject)
        if emits(subject, listener, observation)
            action = what_to_send(listener, subject, observation)
            send!(listener, subject, action)
        end
    end
end

function Rocket.on_next!(actor::EntityActor{T,S,IsNotEnvironment} where {T,S}, observation)
    receive!(entity(actor), observation)
end

function terminate!(actor::EntityActor)
    teardown = actor.subscription
    unsubscribe!(teardown)
end

mutable struct EntityProperties{S,E}
    state_space::S
    is_environment::E
    terminated::Terminated
    clock::Clock
    timer::Union{Timer,Nothing}
    entity_actor::Union{EntityActor,Nothing}
end

EntityProperties(state_space::DiscreteEntity, is_environment; real_time_factor = 1.0) =
    EntityProperties(
        state_space,
        is_environment,
        Terminated(false),
        ManualClock(),
        nothing,
        nothing,
    )
EntityProperties(
    state_space::ContinuousEntity,
    is_environment;
    real_time_factor::Real = 1.0,
) = EntityProperties(
    state_space,
    is_environment,
    Terminated(false),
    WallClock(real_time_factor),
    nothing,
    nothing,
)

function terminate!(properties::EntityProperties)
    terminate!(properties.timer)
    terminate!(properties.entity_actor)
end

struct RxEntity{T,S,E} <: AbstractEntity{T,S,E}
    decorated::T
    markov_blanket::MarkovBlanket
    properties::EntityProperties{S,E}
end

function create_entity(
    entity;
    discrete::Bool = false,
    is_environment::Bool = false,
    real_time_factor = 1,
)
    state_space = discrete ? DiscreteEntity() : ContinuousEntity()
    is_environment = is_environment ? IsEnvironment() : IsNotEnvironment()
    return create_entity(entity, state_space, is_environment, real_time_factor)
end

function create_entity(entity, state_space, is_environment, real_time_factor::Real = 1)
    result = RxEntity(
        entity,
        MarkovBlanket(state_space),
        EntityProperties(state_space, is_environment; real_time_factor = real_time_factor),
    )
    entity_actor = EntityActor(result, nothing)
    entity_actor.subscription = subscribe!(observations(result), entity_actor)
    properties(result).entity_actor = entity_actor
    return result
end

function Base.:(==)(a::RxEntity, b::RxEntity)
    return a.decorated == b.decorated
end

function Base.show(io::IO, entity::RxEntity{T,ContinuousEntity,E} where {T,E})
    print(io, "Continuous RxEntity{", typeof(decorated(entity)), "}")
end

function Base.show(io::IO, entity::RxEntity{T,DiscreteEntity,E} where {T,E})
    print(io, "Discrete RxEntity{", typeof(decorated(entity)), "}")
end
