struct Observation{M,D}
    emitter::M
    data::D
end

struct TimerMessage end

const AbstractObservation = Union{Observation, TimerMessage}

emitter(message::Observation) = message.emitter
data(message::Observation) = message.data


struct ObservationCollection{N}
    observations::NTuple{N, Observation}
end

Base.iterate(collection::ObservationCollection) = iterate(collection.observations)
Base.iterate(collection::ObservationCollection, state) = iterate(collection.observations, state)


struct EmptyMessage end

mutable struct Terminated
    terminated::Bool
end

is_terminated(terminated::Terminated) = terminated.terminated
terminate!(terminated::Terminated) = terminated.terminated = true
