using Rocket

struct RxEntity <: AbstractEntity
    entity::Any
    observations::Rocket.RecentSubjectInstance
    actions::AbstractDict{Any,Rocket.RecentSubjectInstance}
end

function RxEntity(entity)
    return RxEntity(entity, RecentSubject(Any), Dict{Any,Rocket.RecentSubjectInstance}())
end
