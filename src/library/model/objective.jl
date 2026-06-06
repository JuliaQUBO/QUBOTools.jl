@doc raw"""
    ObjectiveBreakdown

Structured objective evaluation for a state.

Fields:

- `state`: state vector in the evaluated model or form domain;
- `raw_value`: linear plus quadratic value before scale and offset;
- `scaled_value`: `scale * raw_value`;
- `offset_adjusted_value`: `scale * (raw_value + offset)`, matching [`value`](@ref);
- `scale`, `offset`, `sense`, and `domain`: frame data used for evaluation.
"""
struct ObjectiveBreakdown{T<:Real,U<:Integer}
    state::Vector{U}
    raw_value::T
    scaled_value::T
    offset_adjusted_value::T
    scale::T
    offset::T
    sense::Sense
    domain::Domain
end

function ObjectiveBreakdown(
    state::AbstractVector{U},
    raw_value::R,
    scaled_value::S,
    offset_adjusted_value::A,
    scale::C,
    offset::O,
    sense::Sense,
    domain::Domain,
) where {U<:Integer,R<:Real,S<:Real,A<:Real,C<:Real,O<:Real}
    T = promote_type(R, S, A, C, O)

    return ObjectiveBreakdown{T,U}(
        collect(state),
        raw_value,
        scaled_value,
        offset_adjusted_value,
        scale,
        offset,
        sense,
        domain,
    )
end

value(breakdown::ObjectiveBreakdown) = breakdown.offset_adjusted_value

@doc raw"""
    ObjectiveMismatch

Detailed record for one stored sample value that does not match model
evaluation.
"""
struct ObjectiveMismatch{T<:Real,U<:Integer}
    index::Int
    state::Vector{U}
    stored_value::T
    evaluated_value::T
    difference::T
end

function ObjectiveMismatch(
    index::Integer,
    state::AbstractVector{U},
    stored_value::S,
    evaluated_value::E,
) where {U<:Integer,S<:Real,E<:Real}
    T = promote_type(S, E)

    return ObjectiveMismatch{T,U}(
        Int(index),
        collect(state),
        stored_value,
        evaluated_value,
        stored_value - evaluated_value,
    )
end

function objective_breakdown(
    model::AbstractModel,
    sample::AbstractSample;
    kws...,
)
    return objective_breakdown(model, state(sample); kws...)
end

function objective_breakdown(
    model::AbstractModel,
    i::Integer;
    kws...,
)
    return objective_breakdown(model, state(model, i); kws...)
end

function objective_breakdown(
    model::AbstractModel,
    state;
    variables = nothing,
)
    psi = _objective_state(model, state; variables)

    return objective_breakdown(form(model), psi)
end

function objective_breakdown(
    form::AbstractForm,
    state::State;
    variables = nothing,
)
    if !isnothing(variables)
        solution_error("State projection by variables requires model variable metadata")
    end

    _objective_validate_state_length(form, state)
    _objective_validate_state_domain(state, domain(form))

    raw_value = _objective_raw_value(state, form)
    alpha = scale(form)
    beta = offset(form)
    scaled_value = alpha * raw_value
    offset_adjusted_value = alpha * (raw_value + beta)

    return ObjectiveBreakdown(
        state,
        raw_value,
        scaled_value,
        offset_adjusted_value,
        alpha,
        beta,
        sense(form),
        domain(form),
    )
end

function annotate_objectives!(
    sol::AbstractSolution,
    model::AbstractModel;
    label::Union{Symbol,AbstractString} = :objective,
    variables = nothing,
)
    label = String(label)
    isempty(label) && solution_error("Objective annotation label cannot be empty")

    rows = [
        _objective_annotation_row(
            i,
            _objective_breakdown(model, sol, sample; variables),
        ) for (i, sample) in enumerate(sol)
    ]

    objectives = get!(metadata(sol), "objectives") do
        Dict{String,Any}()
    end

    objectives isa AbstractDict ||
        solution_error("SampleSet metadata entry 'objectives' must be a dictionary")

    objectives[label] = [_objective_metadata_row(row) for row in rows]

    return rows
end

function objective_value_mismatches(
    model::AbstractModel,
    sol::AbstractSolution;
    atol::Real = 0,
    rtol::Real = sqrt(eps(Float64)),
    variables = nothing,
)
    mismatches = ObjectiveMismatch[]

    for (i, sample) in enumerate(sol)
        breakdown = _objective_breakdown(model, sol, sample; variables)
        stored_value = _objective_stored_value(model, sol, sample)
        evaluated_value = value(breakdown)

        if !isapprox(stored_value, evaluated_value; atol, rtol)
            push!(
                mismatches,
                ObjectiveMismatch(i, breakdown.state, stored_value, evaluated_value),
            )
        end
    end

    return mismatches
end

function verify_objective_values(
    model::AbstractModel,
    sol::AbstractSolution;
    kws...,
)
    return isempty(objective_value_mismatches(model, sol; kws...))
end

function _objective_breakdown(
    model::AbstractModel,
    sol::AbstractSolution,
    sample::AbstractSample;
    variables = nothing,
)
    psi = _objective_state(model, state(sample); variables)
    psi = cast((domain(sol) => domain(model)), psi)

    return objective_breakdown(model, psi)
end

function _objective_raw_value(state::State, form::AbstractForm)
    return value(state, data(linear_form(form))) + value(state, data(quadratic_form(form)))
end

function _objective_state(
    model::AbstractModel,
    state::AbstractVector{<:Integer};
    variables = nothing,
)
    if isnothing(variables)
        _objective_validate_state_length(model, state)

        return collect(state)
    end

    length(state) == length(variables) ||
        solution_error("State length must match the provided variable order")

    positions = Dict{Any,Int}(variable => i for (i, variable) in enumerate(variables))

    return [
        begin
            variable_i = variable(model, i)

            haskey(positions, variable_i) ||
                solution_error("State projection is missing variable '$(variable_i)'")

            state[positions[variable_i]]
        end for i in indices(model)
    ]
end

function _objective_state(
    model::AbstractModel,
    state::AbstractDict;
    variables = nothing,
)
    if !isnothing(variables)
        solution_error("Dictionary states are projected by their keys, not by variables")
    end

    psi = Int[]
    sizehint!(psi, dimension(model))

    for i in indices(model)
        variable_i = variable(model, i)

        haskey(state, variable_i) ||
            solution_error("State assignment is missing variable '$(variable_i)'")

        value_i = state[variable_i]
        value_i isa Integer ||
            solution_error("State assignment for variable '$(variable_i)' must be integer")

        push!(psi, Int(value_i))
    end

    return psi
end

function _objective_validate_state_length(src, state::AbstractVector)
    length(state) == dimension(src) ||
        solution_error("State length $(length(state)) does not match dimension $(dimension(src))")

    return nothing
end

function _objective_validate_state_domain(state::AbstractVector, domain::Domain)
    if domain === BoolDomain
        all(value -> value == 0 || value == 1, state) ||
            solution_error("BoolDomain states must contain only 0 and 1")
    elseif domain === SpinDomain
        all(value -> value == -1 || value == 1, state) ||
            solution_error("SpinDomain states must contain only -1 and 1")
    end

    return nothing
end

function _objective_stored_value(
    model::AbstractModel,
    sol::AbstractSolution,
    sample::AbstractSample,
)
    stored_value = value(sample)

    if sense(sol) !== sense(model)
        stored_value = -stored_value
    end

    return stored_value
end

function _objective_annotation_row(index::Integer, breakdown::ObjectiveBreakdown)
    return (
        rank = Int(index),
        state = breakdown.state,
        raw_value = breakdown.raw_value,
        scaled_value = breakdown.scaled_value,
        offset_adjusted_value = breakdown.offset_adjusted_value,
        scale = breakdown.scale,
        offset = breakdown.offset,
        sense = String(breakdown.sense),
        domain = String(breakdown.domain),
    )
end

function _objective_metadata_row(row::NamedTuple)
    return Dict{String,Any}(String(key) => getproperty(row, key) for key in keys(row))
end
