using Exceptions

mutable struct NotSubscribedException <: Exception
    origin::Any
    recipient::Any
end
origin(e::NotSubscribedException) = e.origin
recipient(e::NotSubscribedException) = e.recipient

Base.showerror(io::IO, e::NotSubscribedException) =
    print(io, "Entity $(origin(e)) is not subscribed to $(recipient(e))")
