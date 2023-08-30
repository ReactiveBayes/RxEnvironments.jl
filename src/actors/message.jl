using Rocket

struct Observation{M,D}
    emitter::M
    data::D
end

emitter(message::Observation) = message.emitter
data(message::Observation) = message.data


struct TimerMessage end

struct EmptyMessage end
