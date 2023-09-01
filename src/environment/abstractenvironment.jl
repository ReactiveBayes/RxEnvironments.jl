

abstract type AbstractEnvironment{T} <: AbstractEntity{T} end

environment(environment::AbstractEnvironment) = environment.entity

function instantiate!(environment::AbstractEnvironment)
    environmentactor = EnvironmentActor(environment)
    subscribe!(observations(environment), environmentactor)
end


function add!(environment::AbstractEntity, entity)
    entity = RxEntity(entity)
    add!(environment, entity)
    return entity
end

"""
    RxEnvironments.update!()

Updates the environment in the absence of any observations coming through the Markov Blanket. In a `TimedEnvironment` this will also take
the `elapsed_time` as an argument in order to calcualte the state transition for the required time.
"""
function update! end
