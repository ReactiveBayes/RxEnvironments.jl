using Rocket

struct RxEntity <: AbstractEntity
    entity::Any
    observations::Rocket.RecentSubjectInstance
    actions::AbstractDict{AbstractEntity, Rocket.RecentSubjectInstance}
end

function RxEntity(entity)
    return RxEntity(entity, RecentSubject(Any), Dict{AbstractEntity, Rocket.RecentSubjectInstance}())
end 