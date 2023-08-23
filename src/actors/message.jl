using Rocket

struct Message{M, D}
    sender::M
    data::D
end

sender(message::Message) = message.sender
data(message::Message) = message.data


struct EmptyMessage end
