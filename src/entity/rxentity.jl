using Rocket

struct RxEntity{T} <: AbstractEntity{T}
    entity::T
    markov_blanket::MarkovBlanket
end

function RxEntity(entity)
    return RxEntity(entity, MarkovBlanket())
end

function Base.:(==)(a::RxEntity, b::RxEntity)
    return a.entity == b.entity
end
