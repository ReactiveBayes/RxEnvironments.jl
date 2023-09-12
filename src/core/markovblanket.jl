using Rocket
using Dictionaries
import Dictionaries: Dictionary

struct Actuator
    emissions::Rocket.RecentSubjectInstance
end

Actuator() = Actuator(RecentSubject(Any))

emission_channel(actuator::Actuator) = actuator.emissions
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
    next!(observations(receiver(actor)), Observation(emitter(actor), stimulus))
Rocket.on_error!(actor::SensorActor, error) = @error(
    "Error in SensorActor for entity $(receiver(actor))",
    exception = (error, catch_backtrace())
)
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

struct Observations{T}
    state_space::T
    buffer::AbstractDictionary{Any,Union{Observation,Nothing}}
    target::Rocket.RecentSubjectInstance
end

Observations(state_space::DiscreteEntity) = Observations(
    state_space,
    Dictionary{Any,Union{Observation,Nothing}}(),
    RecentSubject(ObservationCollection),
)
Observations(state_space::ContinuousEntity) = Observations(
    state_space,
    Dictionary{Any,Union{Observation,Nothing}}(),
    RecentSubject(AbstractObservation),
)
target(observations::Observations) = observations.target
function clear_buffer!(observations::Observations)
    for (key, value) in pairs(observations.buffer)
        observations.buffer[key] = nothing
    end
end

Rocket.subscribe!(observations::Observations, actor::Rocket.Actor{T} where {T}) =
    subscribe!(target(observations), actor)
Rocket.subscribe!(observations::Observations, actor::F where {F<:AbstractActorFactory}) =
    subscribe!(target(observations) |> map(Any, (x) -> data(x)), actor)

Rocket.next!(
    observations::Observations{ContinuousEntity},
    observation::AbstractObservation,
) = next!(target(observations), observation)

function Rocket.next!(observations::Observations{DiscreteEntity}, observation::Observation)
    observations.buffer[emitter(observation)] = observation
    if sum(values(observations.buffer) .== nothing) == 0
        next!(target(observations), ObservationCollection(Tuple(observations.buffer)))
        clear_buffer!(observations)
    end
end

struct MarkovBlanket{T}
    actuators::AbstractDictionary{Any,Actuator}
    sensors::AbstractDictionary{Any,Sensor}
    observations::Observations{T}
end

MarkovBlanket(state_space) = MarkovBlanket(
    Dictionary{Any,Actuator}(),
    Dictionary{Any,Sensor}(),
    Observations(state_space),
)

actuators(markov_blanket::MarkovBlanket) = markov_blanket.actuators
sensors(markov_blanket::MarkovBlanket) = markov_blanket.sensors
observations(markov_blanket::MarkovBlanket) = markov_blanket.observations

function get_actuator(markov_blanket::MarkovBlanket, agent)
    if !haskey(actuators(markov_blanket), agent)
        throw(NotSubscribedException(markov_blanket, agent))
    end
    return actuators(markov_blanket)[agent]
end

add_to_state!(entity, to_add) = nothing

function add_sensor!(
    markov_blanket::MarkovBlanket{DiscreteEntity},
    emitter::AbstractEntity,
    receiver::AbstractEntity,
)
    sensor = Sensor(emitter, receiver)
    insert!(sensors(markov_blanket), emitter, sensor)
    insert!(observations(markov_blanket).buffer, emitter, nothing)
end

function add_sensor!(
    markov_blanket::MarkovBlanket{ContinuousEntity},
    emitter::AbstractEntity,
    receiver::AbstractEntity,
)
    sensor = Sensor(emitter, receiver)
    insert!(sensors(markov_blanket), emitter, sensor)
end
