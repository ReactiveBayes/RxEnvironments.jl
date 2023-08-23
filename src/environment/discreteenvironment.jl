struct DiscreteEnvironment <: AbstractEnvironment
    entity::Any
    observations::Rocket.RecentSubjectInstance
    actions::AbstractDict{Any,Rocket.RecentSubjectInstance}
end

function DiscreteEnvironment(environment)
    env = DiscreteEnvironment(
        environment,
        RecentSubject(Any),
        Dict{Any,Rocket.RecentSubjectInstance}(),
    )
    instantiate!(env)
    return env
end

function Base.show(io::IO, env::DiscreteEnvironment)
    println(io, "Discrete RxEnvironment $(typeof(environment(env))).")
    println(io, "Subscribed entities: $(keys(env.actions))")
end

function update!(env::DiscreteEnvironment)
    update!(environment(env))
end