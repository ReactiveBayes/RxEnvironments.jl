struct DiscreteEnvironment{T} <: AbstractEnvironment{T}
    entity::T
    markov_blanket::MarkovBlanket
    terminated::Terminated
end

function DiscreteEnvironment(environment)
    env = DiscreteEnvironment(environment, MarkovBlanket(), Terminated(false))
    instantiate!(env)
    return env
end

function Base.show(io::IO, env::DiscreteEnvironment)
    println(io, "Discrete RxEnvironment $(typeof(environment(env))).")
end

function update!(env::DiscreteEnvironment)
    update!(environment(env))
end
