function generate(problem::AbstractProblem)
    return generate(Random.GLOBAL_RNG, problem)
end
