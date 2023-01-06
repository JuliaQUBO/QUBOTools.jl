Sense(s::Sense)    = s
Sense(s::Symbol)   = Sense(Val(s))
Sense(::Val{:min}) = Min
Sense(::Val{:max}) = Max

Base.Broadcast.broadcastable(s::Sense) = Ref(s)

struct MinSense <: Sense end

const Min = MinSense()

Base.show(io::IO, ::MinSense) = print(io, "Min")

struct MaxSense <: Sense end

const Max = MaxSense()

Base.show(io::IO, ::MaxSense) = print(io, "Max")
