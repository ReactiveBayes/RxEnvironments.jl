struct Message
    sender::Any
    data::Any
end

sender(message::Message) = message.sender
data(message::Message) = message.data


struct EmptyMessage end
