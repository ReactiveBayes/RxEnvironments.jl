

abstract type AbstractEnvironment <: AbstractEntity end

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


function update! end
