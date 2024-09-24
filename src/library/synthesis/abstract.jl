function generate(problem::AbstractProblem)
    return generate(Random.GLOBAL_RNG, problem)
end

macro _deprecate_generate()
    return quote @warn("Depraction Warning: To use `generate`, please refer to `QUBOLib.jl`") end
end
