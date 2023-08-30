struct Observation{M,D}
    emitter::M
    data::D
end

emitter(message::Observation) = message.emitter
data(message::Observation) = message.data


struct TimerMessage end

struct EmptyMessage end

mutable struct Terminated
    terminated::Bool
end

is_terminated(terminated::Terminated) = terminated.terminated
terminate!(terminated::Terminated) = terminated.terminated = true
