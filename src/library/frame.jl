sense(s::Sense) = s    

function sense(s::Symbol)
    if s === :min
        return Min
    elseif s === :max
        return Max
    else
        error("Invalid sense '$s', options are ':min' and ':max'")

        return nothing
    end
end

sense(s::AbstractString) = sense(Symbol(s))

function Symbol(s::Sense)
    if s === Min
        return :min
    elseif s === Max
        return :max
    else
        error("Invalid sense '$s', options are 'Min' and 'Max'")

        return nothing
    end
end

String(s::Sense) = String(Symbol(s))

domain(x::Domain) = x

function domain(x::Symbol)
    if x === :bool
        return BoolDomain
    elseif x === :spin
        return SpinDomain
    else
        error("Invalid domain '$x', options are ':bool' and ':spin'")

        return nothing
    end
end

domain(s::AbstractString) = domain(Symbol(s))

function Symbol(x::Domain)
    if x === BoolDomain
        return :bool
    elseif x === SpinDomain
        return :spin
    else
        error("Invalid domain '$x', options are 'BoolDomain' and 'SpinDomain'")

        return nothing
    end
end

String(x::Domain) = String(Symbol(x))

function sense(frame::Frame)
    return frame.sense
end

function domain(frame::Frame)
    return frame.domain
end

@doc raw"""
    cast((s,t)::Route{Frame}, obj::Any)
"""
function cast((s,t)::Route{Frame}, obj::Any)
    return cast(sense(s) => sense(t), cast(domain(s) => domain(t), obj))
end
