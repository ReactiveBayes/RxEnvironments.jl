struct DiscreteEnvironment{T} <: AbstractEnvironment{T}
    entity::T
    markov_blanket::MarkovBlanket
end

function DiscreteEnvironment(environment)
    env = DiscreteEnvironment(environment, MarkovBlanket())
    instantiate!(env)
    return env
end

function Base.show(io::IO, env::DiscreteEnvironment)
    println(io, "Discrete RxEnvironment $(typeof(environment(env))).")
end

function update!(env::DiscreteEnvironment)
    update!(environment(env))
end
