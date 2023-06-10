function sense(s::Symbol)
    if s === :min
        return Min
    elseif s === :max
        return Max
    else
        error("Invalid sense '$s', options are ':min' and ':max'")
    end
end

function domain(s::Symbol)
    if s === :bool
        return BoolDomain
    elseif s === :spin
        return SpinDomain
    else
        error("Invalid domain '$s', options are ':bool' and ':spin'")
    end
end

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