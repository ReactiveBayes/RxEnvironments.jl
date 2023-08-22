using Rocket

struct EnvironmentActor <: Rocket.Actor{Any}
    environment::Any
end

rxenvironment(a::EnvironmentActor) = a.environment
environment(a::EnvironmentActor) = environment(rxenvironment(a))


function Rocket.on_next!(actor::EnvironmentActor, action)
    update!(rxenvironment(actor))
    act!(rxenvironment(actor), action)
    # TODO now emits to all entities subscribed to it, but is not necessarily always the case. 
    # For example what if we have an environment that influences another environment? Then we would need to emit to this other environment exactly once and not enter an infinite loop.
    for (recipient, action_subject) in actions(rxenvironment(actor))
        next!(action_subject, nothing)
    end
end
