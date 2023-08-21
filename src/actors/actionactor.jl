using Rocket

struct ActionActor <: Rocket.Actor{Any}
    entity
    environment
end

rxenvironment(a::ActionActor) = a.environment
rxentity(a::ActionActor) = a.entity
environment(a::ActionActor) = environment(rxenvironment(a))
entity(a::ActionActor) = entity(rxentity(a))


function Rocket.on_next!(actor::ActionActor, action)
    update!(environment(actor))
    act!(environment(actor), entity(actor), action)
    next!(rxenvironment(actor), action)
end

