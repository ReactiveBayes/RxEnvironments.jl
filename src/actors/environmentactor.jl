using Rocket

struct EnvironmentActor <: Rocket.Actor{Any}
    environment
end

rxenvironment(a::EnvironmentActor) = a.environment
environment(a::EnvironmentActor) = environment(rxenvironment(a))


function Rocket.on_next!(actor::EnvironmentActor, action)
    update!(environment(actor))
    act!(rxenvironment(actor), action)
    # TODO now emits to all entities subscribed to it, but is not necessarily always the case.
    for (recipient, action_subject) in actions(rxenvironment(actor))
        next!(action_subject, nothing)
    end
end

