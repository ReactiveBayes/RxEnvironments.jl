using Rocket
using Dictionaries
import Dictionaries: Dictionary

struct Actuator{T}
    emissions::Rocket.RecentSubjectInstance{T,Subject{T,AsapScheduler,AsapScheduler}}
end

Actuator() = Actuator(RecentSubject(Any))
Actuator(agent) = Actuator(RecentSubject(action_type(agent)))

emission_channel(actuator::Actuator) = actuator.emissions
send_action!(actuator::Actuator, action) = next!(emission_channel(actuator), action)

Rocket.subscribe!(actuator::Actuator, actor::Rocket.Actor{T} where {T}) =
    subscribe!(emission_channel(actuator), actor)

struct SensorActor{E,R} <: Rocket.Actor{Any} where {E<:AbstractEntity,R<:AbstractEntity}
    emitter::E
    receiver::R
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

struct Sensor{E,R}
    actor::SensorActor{E,R}
    subscription::Teardown
end

Sensor(entity::AbstractEntity, emitter::AbstractEntity) =
    Sensor(SensorActor(entity, emitter))
Sensor(actor::SensorActor) =
    Sensor(actor, subscribe!(get_actuator(emitter(actor), receiver(actor)), actor))
Rocket.unsubscribe!(sensor::Sensor) = Rocket.unsubscribe!(sensor.subscription)

struct Observations{S,T}
    state_space::S
    buffer::Dict{Any,Union{Observation,Nothing}}
    target::Rocket.RecentSubjectInstance{T,Subject{T,AsapScheduler,AsapScheduler}}
end

subject(observations::Observations) = observations.target

Observations(state_space::DiscreteEntity) = Observations(
    state_space,
    Dict{Any,Union{Observation,Nothing}}(),
    RecentSubject(ObservationCollection),
)
Observations(state_space::ContinuousEntity) = Observations(
    state_space,
    Dict{Any,Union{Observation,Nothing}}(),
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
    observations::Observations{ContinuousEntity,<:T},
    observation::T,
) where {T<:AbstractObservation} = next!(target(observations), observation)

function Rocket.next!(observations::Observations{DiscreteEntity}, observation::Observation)
    observations.buffer[emitter(observation)] = observation
    if all(values(observations.buffer) .!= nothing)
        obs = collect(values(observations.buffer))
        clear_buffer!(observations)
        next!(target(observations), ObservationCollection(Tuple(obs)))
    end
end

struct MarkovBlanket{S,T}
    actuators::Dict{Any,Actuator{T}}
    sensors::Dict{Any,Sensor}
    observations::Observations{S}
end

MarkovBlanket(state_space, T) = MarkovBlanket(
    Dict{Any,Actuator{T}}(),
    Dict{Any,Sensor}(),
    Observations(state_space),
)

actuators(markov_blanket::MarkovBlanket) = markov_blanket.actuators
sensors(markov_blanket::MarkovBlanket) = markov_blanket.sensors
observations(markov_blanket::MarkovBlanket{DiscreteEntity}) =
    markov_blanket.observations::Observations{DiscreteEntity,ObservationCollection}
observations(markov_blanket::MarkovBlanket{ContinuousEntity}) =
    markov_blanket.observations::Observations{ContinuousEntity,AbstractObservation}

function get_actuator(markov_blanket::MarkovBlanket, agent)
    actuator_dictionary = actuators(markov_blanket)
    return actuator_dictionary[agent]
end

add_to_state!(entity, to_add) = nothing

function add_sensor!(
    markov_blanket::MarkovBlanket{DiscreteEntity},
    emitter::AbstractEntity,
    receiver::AbstractEntity,
)
    sensor = Sensor(emitter, receiver)
    sensors(markov_blanket)[emitter] = sensor
    observations(markov_blanket).buffer[emitter] = nothing
end

function add_sensor!(
    markov_blanket::MarkovBlanket{ContinuousEntity},
    emitter::AbstractEntity,
    receiver::AbstractEntity,
)
    sensor = Sensor(emitter, receiver)
    sensors(markov_blanket)[emitter] = sensor
end

Base.show(io::IO, markov_blanket::MarkovBlanket{S}) where {S} =
    print(io, "MarkovBlanket{$S}")
