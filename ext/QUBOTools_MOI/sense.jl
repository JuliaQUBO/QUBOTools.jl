function QUBOTools.sense(s::MOI.OptimizationSense)
    if s === MOI.MIN_SENSE
        return QUBOTools.sense(:min)
    elseif s === MOI.MAX_SENSE
        return QUBOTools.sense(:max)
    else
        error("Invalid sense for QUBO: '$sense'")

        return nothing
    end
end
