function benchmark_fixture(label::String, n::Int; quadratic_density::Float64)
    rng = MersenneTwister(hash(label))
    variables = [Symbol("x", i) for i in 1:n]

    linear = Dict{Symbol,Float64}(variable => randn(rng) for variable in variables)
    quadratic = Dict{Tuple{Symbol,Symbol},Float64}()

    for i in 1:(n - 1), j in (i + 1):n
        if rand(rng) < quadratic_density
            quadratic[(variables[i], variables[j])] = randn(rng)
        end
    end

    model = QUBOTools.Model(
        linear,
        quadratic;
        scale = 1.0,
        offset = -1.0,
        sense = :max,
        domain = :spin,
    )

    psi = [rand(rng, Bool) ? 1 : -1 for _ in 1:QUBOTools.dimension(model)]

    return (
        label = label,
        linear = linear,
        quadratic = quadratic,
        model = model,
        psi = psi,
        dense_form = QUBOTools.form(model, Matrix),
        sparse_form = QUBOTools.form(model, SparseMatrixCSC),
        dict_form = QUBOTools.form(model, Dict),
    )
end

function repeat_last(f::F, repeats::Int) where {F}
    result = f()

    for _ in 2:repeats
        result = f()
    end

    return result
end

function repeat_sum(f::F, repeats::Int) where {F}
    total = zero(Float64)

    for _ in 1:repeats
        total += f()
    end

    return total
end

function benchmark_fixtures()
    return (
        benchmark_fixture("n=128", 128; quadratic_density = 0.08),
        benchmark_fixture("n=384", 384; quadratic_density = 0.03),
    )
end
