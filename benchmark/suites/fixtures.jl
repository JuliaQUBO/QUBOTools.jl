const MOI = MathOptInterface
const QUBOTools_MOI = let ext = Base.get_extension(QUBOTools, :QUBOTools_MOI)
    isnothing(ext) &&
        error("QUBOTools_MOI extension is not loaded; add MathOptInterface to the benchmark environment.")

    ext
end
const QUBOModel = QUBOTools_MOI.QUBOModel
const SQF{T} = MOI.ScalarQuadraticFunction{T}
const SQT{T} = MOI.ScalarQuadraticTerm{T}
const SAT{T} = MOI.ScalarAffineTerm{T}

function benchmark_seed(label::String, n::Int; quadratic_density::Float64)
    state = UInt32(0x811c9dc5)

    for part in (label, string(n), bitstring(quadratic_density))
        for byte in codeunits(part)
            state = (state ⊻ UInt32(byte)) * UInt32(0x01000193)
        end
    end

    return state
end

function benchmark_qubo_data(label::String, n::Int; quadratic_density::Float64)
    rng = MersenneTwister(benchmark_seed(label, n; quadratic_density))
    variables = [Symbol("x", i) for i in 1:n]

    linear = Dict{Symbol,Float64}(variable => randn(rng) for variable in variables)
    quadratic = Dict{Tuple{Symbol,Symbol},Float64}()

    for i in 1:(n - 1), j in (i + 1):n
        if rand(rng) < quadratic_density
            quadratic[(variables[i], variables[j])] = randn(rng)
        end
    end

    return (; rng, variables, linear, quadratic)
end

function benchmark_fixture(label::String, n::Int; quadratic_density::Float64)
    data = benchmark_qubo_data(label, n; quadratic_density)

    model = QUBOTools.Model(
        data.linear,
        data.quadratic;
        scale = 1.0,
        offset = -1.0,
        sense = :max,
        domain = :spin,
    )

    psi = [rand(data.rng, Bool) ? 1 : -1 for _ in 1:QUBOTools.dimension(model)]

    return (
        label = label,
        linear = data.linear,
        quadratic = data.quadratic,
        model = model,
        psi = psi,
        dense_form = QUBOTools.form(model, Matrix),
        sparse_form = QUBOTools.form(model, SparseMatrixCSC),
        dict_form = QUBOTools.form(model, Dict),
    )
end

# Issue #56 was reported on the boolean/QUBO conversion path coming from ToQUBO,
# so this benchmark fixture intentionally exercises the ZeroOne parser route.
function benchmark_bool_moi_model(
    variables::Vector{Symbol},
    linear::Dict{Symbol,Float64},
    quadratic::Dict{Tuple{Symbol,Symbol},Float64};
    offset::Float64 = -1.0,
    sense::MOI.OptimizationSense = MOI.MIN_SENSE,
)
    moi_model = QUBOModel{Float64,MOI.ZeroOne}()
    moi_variables = MOI.add_variables(moi_model, length(variables))
    variable_map = Dict{Symbol,MOI.VariableIndex}(
        variable => moi_variables[i] for (i, variable) in enumerate(variables)
    )

    affine_terms = SAT{Float64}[]
    quadratic_terms = SQT{Float64}[]
    sizehint!(affine_terms, length(linear))
    sizehint!(quadratic_terms, length(quadratic))

    for variable in variables
        push!(affine_terms, SAT{Float64}(linear[variable], variable_map[variable]))
    end

    for ((u, v), q) in quadratic
        push!(quadratic_terms, SQT{Float64}(q, variable_map[u], variable_map[v]))
    end

    MOI.set(
        moi_model,
        MOI.ObjectiveFunction{SQF{Float64}}(),
        SQF{Float64}(quadratic_terms, affine_terms, offset),
    )
    MOI.set(moi_model, MOI.ObjectiveSense(), sense)

    return moi_model
end

function benchmark_constructor_fixture(label::String, n::Int; quadratic_density::Float64)
    data = benchmark_qubo_data(label, n; quadratic_density)
    bool_moi_model = benchmark_bool_moi_model(data.variables, data.linear, data.quadratic)

    return (
        label = label,
        linear = data.linear,
        quadratic = data.quadratic,
        bool_moi_model = bool_moi_model,
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
