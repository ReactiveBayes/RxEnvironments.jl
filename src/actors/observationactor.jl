struct ObservationActor <: Rocket.Actor{Any}
    entity
    environment
end

rxenvironment(actor::ObservationActor) = actor.environment
rxentity(actor::ObservationActor) = actor.entity
environment(actor::ObservationActor) = environment(rxenvironment(actor))
entity(actor::ObservationActor) = entity(rxentity(actor))

function Rocket.on_next!(actor::ObservationActor, observation)
    observation = observe(environment(actor), entity(actor))
    next!(observation_subject(rxentity(actor)), observation)
end