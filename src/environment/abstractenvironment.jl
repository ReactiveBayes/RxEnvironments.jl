

abstract type AbstractEnvironment <: AbstractEntity end

start_time(environment::AbstractEnvironment) = environment.start_time
real_time_factor(environment::AbstractEnvironment) = environment.real_time_factor

function instantiate!(environment::AbstractEnvironment)
    environmentactor = EnvironmentActor(environment)
    subscribe!(observations(environment), environmentactor)
end

function update!(env::AbstractEnvironment) 
    update!(environment(env), time(env))
end

function Base.time(environment::AbstractEnvironment)
    return (time() - start_time(environment)) * real_time_factor(environment)
end