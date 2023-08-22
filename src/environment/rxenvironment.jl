using Rocket

export RxEnvironment, add!

struct RxEnvironment <: AbstractEnvironment
    entity
    observations::Rocket.RecentSubjectInstance
    actions::AbstractDict{AbstractEntity, Rocket.RecentSubjectInstance}
end

environment(environment::RxEnvironment) = environment.entity

function RxEnvironment(environment) 
    env = RxEnvironment(environment, RecentSubject(Any), Dict{AbstractEntity, Rocket.RecentSubjectInstance}())
    instantiate!(env)
    return env
end

function add!(environment::RxEnvironment, entity)
    entity = RxEntity(entity)
    __add!(environment, entity)
    return entity
end