using Rocket

Base.@kwdef struct RxEntity{O, T} <: AbstractEntity
    entity::Any
    observation_subject = RecentSubject(O)
    action_subject = RecentSubject(T)
end

entity(entity::RxEntity) = entity.entity
action_subject(entity::RxEntity) = entity.action_subject
observation_subject(entity::RxEntity) = entity.observation_subject
Rocket.next!(entity::RxEntity, entry) = next!(action_subject(entity), entry)
Rocket.subscribe!(entity::RxEntity, observer) = subscribe!(observation_subject(entity), observer)

function RxEntity(entity, environment)
    obs_type = observation_type(entity)
    action_type = observation_type(environment)
    return RxEntity{obs_type, action_type}(entity, RecentSubject(obs_type), RecentSubject(action_type))
end