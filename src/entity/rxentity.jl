using Rocket

struct RxEntity{T} <: AbstractEntity{T}
    entity::T
    markov_blanket::MarkovBlanket
    terminated::Terminated
end

function RxEntity(entity)
    return RxEntity(entity, MarkovBlanket(), Terminated(false))
end

function Base.:(==)(a::RxEntity, b::RxEntity)
    return a.entity == b.entity
end
