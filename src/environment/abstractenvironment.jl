

abstract type AbstractEnvironment <: AbstractEntity end

function instantiate!(environment::AbstractEnvironment)
    environmentactor = EnvironmentActor(environment)
    subscribe!(observations(environment), environmentactor)
end

function update!(environment::AbstractEnvironment) 
    t = time()
    update!(environment, t)
end