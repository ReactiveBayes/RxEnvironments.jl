

abstract type AbstractEnvironment{T} <: AbstractEntity{T} end

environment(environment::AbstractEnvironment) = environment.entity

function instantiate!(environment::AbstractEnvironment)
    environmentactor = EnvironmentActor(environment)
    subscribe!(observations(environment), environmentactor)
end


function add!(environment::AbstractEnvironment, entity)
    entity = RxEntity(entity)
    __add!(environment, entity)
    return entity
end

add!(environment::AbstractEnvironment, entity::AbstractEntity) = __add!(environment, entity)

function update! end
