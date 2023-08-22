using Rocket

export RxEnvironment, add!

struct RxEnvironment <: AbstractEnvironment
    entity::Any
    observations::Rocket.RecentSubjectInstance
    actions::AbstractDict{AbstractEntity,Rocket.RecentSubjectInstance}
    start_time::Float64
    real_time_factor::Float64
end

environment(environment::RxEnvironment) = environment.entity

function RxEnvironment(environment; real_time_factor = 1.0)
    env = RxEnvironment(
        environment,
        RecentSubject(Any),
        Dict{AbstractEntity,Rocket.RecentSubjectInstance}(),
        time(),
        real_time_factor,
    )
    instantiate!(env)
    return env
end

function add!(environment::RxEnvironment, entity)
    entity = RxEntity(entity)
    __add!(environment, entity)
    return entity
end
