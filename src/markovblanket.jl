using Rocket
using Dictionaries

struct Actuator
    subject::Rocket.RecentSubjectInstance
end

Actuator() = Actuator(RecentSubject(Any))

emission_channel(actuator::Actuator) = actuator.subject
send_action!(actuator::Actuator, action) = next!(emission_channel(actuator), action)

Rocket.subscribe!(actuator::Actuator, actor::Rocket.Actor{T} where {T}) =
    subscribe!(emission_channel(actuator), actor)

struct SensorActor <: Rocket.Actor{Any}
    emitter::AbstractEntity
    receiver::AbstractEntity
end

emitter(actor::SensorActor) = actor.emitter
receiver(actor::SensorActor) = actor.receiver

Rocket.on_next!(actor::SensorActor, stimulus) =
    receive_observation!(receiver(actor), Observation(emitter(actor), stimulus))
Rocket.on_error!(actor::SensorActor, error) = println("Error in SensorActor: $error")
Rocket.on_complete!(actor::SensorActor) = println("SensorActor completed")

struct Sensor
    actor::SensorActor
    subscription::Teardown
end

Sensor(entity::AbstractEntity, emitter::AbstractEntity) =
    Sensor(SensorActor(entity, emitter))
Sensor(actor::SensorActor) =
    Sensor(actor, subscribe!(get_actuator(emitter(actor), receiver(actor)), actor))
Rocket.unsubscribe!(sensor::Sensor) = Rocket.unsubscribe!(sensor.subscription)

struct MarkovBlanket
    actuators::Dictionary{Any,Actuator}
    sensors::Dictionary{Any,Sensor}
    observations::Rocket.RecentSubjectInstance
end

MarkovBlanket() = MarkovBlanket(
    Dictionaries.Dictionary{Any,Actuator}(),
    Dictionaries.Dictionary{Any,Sensor}(),
    RecentSubject(Any),
)

actuators(markov_blanket::MarkovBlanket) = markov_blanket.actuators
sensors(markov_blanket::MarkovBlanket) = markov_blanket.sensors
observations(markov_blanket::MarkovBlanket) = markov_blanket.observations

function get_actuator(markov_blanket::MarkovBlanket, agent::AbstractEntity)
    if !haskey(actuators(markov_blanket), agent)
        throw(NotSubscribedException(markov_blanket, agent))
    end
    return actuators(markov_blanket)[agent]
end

function Rocket.subscribe!(emitter::AbstractEntity, receiver::AbstractEntity)
    actuator = Actuator()
    insert!(actuators(markov_blanket(emitter)), receiver, actuator)
    sensor = Sensor(emitter, receiver)
    insert!(sensors(markov_blanket(receiver)), emitter, sensor)
end

function Rocket.subscribe!(emitter::AbstractEntity, receiver::Rocket.Actor{T} where {T})
    actuator = Actuator()
    insert!(actuators(emitter), receiver, actuator)
    return subscribe!(actuator, receiver)
end

function Rocket.unsubscribe!(emitter::AbstractEntity, receiver::AbstractEntity)
    Rocket.unsubscribe!(sensors(receiver)[emitter])
    delete!(sensors(receiver), emitter)
    delete!(actuators(emitter), receiver)
end

function Rocket.unsubscribe!(emitter::AbstractEntity, subscription::Teardown)
    @warn "Deleting from actuator list not possible for Actors, unsubscription will still be processed."
    unsubscribe!(subscription)
end

function conduct_action!(emitter::AbstractEntity, receiver::AbstractEntity, action::Any)
    actuator = get_actuator(emitter, receiver)
    send_action!(actuator, action)
end


function receive_observation!(entity::AbstractEntity, observation::Observation)
    next!(observations(entity), observation)
end
