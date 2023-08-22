using Rocket

struct MarkovBlanketActor{E,R} <: Rocket.Actor{Any}
    emitter::E
    recipient::R
end

rxemitter(actor::MarkovBlanketActor) = actor.emitter
rxrecipient(actor::MarkovBlanketActor) = actor.recipient
emitter(actor::MarkovBlanketActor) = entity(rxemitter(actor))
recipient(actor::MarkovBlanketActor) = entity(rxrecipient(actor))

function Rocket.on_next!(actor::MarkovBlanketActor, stimulus)
    observation = observe(recipient(actor), emitter(actor), stimulus)
    next!(observations(rxrecipient(actor)), Message(rxemitter(actor), observation))
end
