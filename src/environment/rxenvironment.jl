using Rocket

export RxEnvironment, add!

Base.@kwdef struct RxEnvironment{T} <: AbstractEnvironment
    entities::Vector{AbstractEntity}
    action_subject = RecentSubject(T)
    environment::Any
end

entities(env::RxEnvironment) = env.entities
subject(env::RxEnvironment) = env.action_subject
environment(env::RxEnvironment) = env.environment
Rocket.next!(env::RxEnvironment, entry) = next!(subject(env), entry)

function RxEnvironment(environment) 
    obs_type = observation_type(environment)
    RxEnvironment{obs_type}(AbstractActor[], RecentSubject(obs_type), environment)
end


function add!(env::RxEnvironment, entity)
    entity = RxEntity(entity, environment(env))
    add!(env, entity)
    return entity
end

function add!(env::RxEnvironment, entity::RxEntity)
    push!(entities(env), entity)
    add_subscription_loop!(env, entity)
end
