function benchmark_seed(label::String, n::Int; quadratic_density::Float64)
    state = UInt32(0x811c9dc5)

    for part in (label, string(n), bitstring(quadratic_density))
        for byte in codeunits(part)
            state = (state ⊻ UInt32(byte)) * UInt32(0x01000193)
        end
    end

    return state
end

function benchmark_fixture(label::String, n::Int; quadratic_density::Float64)
    rng = MersenneTwister(benchmark_seed(label, n; quadratic_density))
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

function benchmark_constructor_fixture(label::String, n::Int; quadratic_density::Float64)
    rng = MersenneTwister(benchmark_seed(label, n; quadratic_density))
    variables = [Symbol("x", i) for i in 1:n]

    linear = Dict{Symbol,Float64}(variable => randn(rng) for variable in variables)
    quadratic = Dict{Tuple{Symbol,Symbol},Float64}()

    for i in 1:(n - 1), j in (i + 1):n
        if rand(rng) < quadratic_density
            quadratic[(variables[i], variables[j])] = randn(rng)
        end
    end

    return (
        label = label,
        linear = linear,
        quadratic = quadratic,
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

function benchmark_constructor_fixtures()
    return (
        benchmark_constructor_fixture("n=128", 128; quadratic_density = 0.08),
        benchmark_constructor_fixture("n=384", 384; quadratic_density = 0.03),
        benchmark_constructor_fixture("n=2048", 2048; quadratic_density = 0.01),
    )
end
