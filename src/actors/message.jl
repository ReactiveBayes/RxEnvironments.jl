struct Message
    sender
    data::Any
end

sender(message::Message) = message.sender
data(message::Message) = message.data