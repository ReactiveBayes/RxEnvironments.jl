abstract type AbstractObservation end

struct Observation{M,D} <: AbstractObservation
    emitter::M
    data::D
end

struct TimerMessage <: AbstractObservation end

emitter(message::Observation) = message.emitter
data(message::Observation) = message.data


struct ObservationCollection{N}
    observations::NTuple{N,Observation}
end

Base.length(::ObservationCollection{N}) where {N} = N
Base.iterate(collection::ObservationCollection) = iterate(collection.observations)
Base.iterate(collection::ObservationCollection, state) =
    iterate(collection.observations, state)
Base.filter(f, collection::ObservationCollection) = filter(f, collection.observations)

data(collection::ObservationCollection) = map(point -> data(point), collection.observations)
data(collection::ObservationCollection{1}) = data(collection.observations[1])


struct EmptyMessage <: AbstractObservation end

mutable struct Terminated
    terminated::Bool
end

is_terminated(terminated::Terminated) = terminated.terminated
terminate!(terminated::Terminated) = terminated.terminated = true
