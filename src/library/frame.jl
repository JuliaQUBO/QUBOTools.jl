sense(s::Sense) = s

function sense(s::Symbol)
    if s === :min
        return Min
    elseif s === :max
        return Max
    else
        error("Invalid sense '$s', options are ':min' and ':max'")
    end
end

sense(s::AbstractString) = sense(Symbol(s))

function Base.Symbol(s::Sense)
    if s === Min
        return :min
    elseif s === Max
        return :max
    else
        error("Invalid sense '$s', options are 'Min' and 'Max'")
    end
end

Base.String(s::Sense) = String(Symbol(s))

domain(x::Domain) = x

function domain(x::Symbol)
    if x === :bool
        return BoolDomain
    elseif x === :spin
        return SpinDomain
    else
        error("Invalid domain '$x', options are ':bool' and ':spin'")
    end
end

domain(s::AbstractString) = domain(Symbol(s))

function Base.Symbol(x::Domain)
    if x === BoolDomain
        return :bool
    elseif x === SpinDomain
        return :spin
    else
        error("Invalid domain '$x', options are 'BoolDomain' and 'SpinDomain'")
    end
end

Base.String(x::Domain) = String(Symbol(x))

function sense(obj::Any)
    return sense(frame(obj))
end

function sense(frame::Frame)
    return frame.sense
end

function domain(obj)
    return domain(frame(obj))
end

function domain(frame::Frame)
    return frame.domain
end

@doc raw"""
    cast((s,t)::Route{Frame}, item::Any)
"""
function cast((s, t)::Route{Frame}, item::Any)
    return cast((sense(s) => sense(t)), cast((domain(s) => domain(t)), item))
end
