function read_model(path::AbstractString, fmt::QUBin)
    return HDF5.h5open(path, "r") do fp
        return read_model(fp, fmt)
    end
end

function read_model(fp::HDF5.File, fmt::QUBin)
    form      = _parse_model_form(fp, fmt)
    variables = _parse_model_variables(fp, fmt)
    metadata  = _parse_model_metadata(fp, fmt)
    solution  = _parse_solution(fp, fmt)

    return _parse_model(form, variables; metadata, solution)
end

function read_solution(path::AbstractString, fmt::QUBin)
    return HDF5.h5open(path, "r") do fp
        return read_solution(fp, fmt)
    end
end

function read_solution(fp::HDF5.File, fmt::QUBin)
    return _parse_solution(fp, fmt)
end

function _parse_model(
    form::Form{T,SparseLinearForm{T},SparseQuadraticForm{T}},
    variable_map::VariableMap{V};
    metadata::Dict{String,Any},
    solution::SampleSet{T,U},
) where {V,T,U}
    return Model{V,T,U}(variable_map, form; metadata, solution)
end

function _parse_model_form(fp::HDF5.File, ::QUBin)
    n = read(fp["model"]["form"]["dimension"])

    li = read(fp["model"]["form"]["linear"]["i"])
    lv = read(fp["model"]["form"]["linear"]["v"])

    L = SparseLinearForm(sparsevec(li, lv))

    qi = read(fp["model"]["form"]["quadratic"]["i"])
    qj = read(fp["model"]["form"]["quadratic"]["j"])
    qv = read(fp["model"]["form"]["quadratic"]["v"])

    Q = SparseQuadraticForm(sparse(qi, qj, qv))

    α = read(fp["model"]["form"]["scale"])
    β = read(fp["model"]["form"]["offset"])

    sense = QUBOTools.sense(read(fp["model"]["form"]["sense"]))
    domain = QUBOTools.domain(read(fp["model"]["form"]["domain"]))

    return _parse_model_form(n, L, Q, α, β; sense, domain)
end

function _parse_model_form(
    n::Int,
    L::SparseLinearForm{T},
    Q::SparseQuadraticForm{T},
    α::T,
    β::T;
    sense::Sense,
    domain::Domain,
) where {T}
    return Form{T}(n, L, Q, α, β; sense, domain)
end

function _parse_model_variables(fp::HDF5.File, ::QUBin)
    variables = read(fp["model"]["variables"])

    return _parse_model_variables(variables)
end

function _parse_model_variables(variables::Vector{V}) where {V}
    return VariableMap{V}(variables)
end

function _parse_model_metadata(fp::HDF5.File, ::QUBin)
    return JSON.parse(read(fp["model"]["metadata"]))
end

function _parse_solution(fp::HDF5.File, fmt::QUBin)
    data     = _parse_solution_data(fp, fmt)
    metadata = _parse_solution_metadata(fp, fmt)

    sense  = QUBOTools.sense(read(fp["solution"]["sense"]))
    domain = QUBOTools.domain(read(fp["solution"]["domain"]))

    return _parse_solution(data, metadata; sense, domain)
end

function _parse_solution(
    data::Vector{Sample{T,U}},
    metadata::Dict{String,Any};
    sense::Sense,
    domain::Domain,
) where {T,U}
    return SampleSet{T,U}(data; metadata, sense, domain)
end

function _parse_solution_data(fp::HDF5.File, ::QUBin)
    ψ = read(fp["solution"]["data"]["state"])
    λ = read(fp["solution"]["data"]["value"])
    r = read(fp["solution"]["data"]["reads"])

    return _parse_solution_data(ψ, λ, r)
end

function _parse_solution_data(ψ::Matrix{U}, λ::Vector{T}, r::Vector{Int}) where {T,U}
    return Sample{T,U}[Sample{T,U}(ψ[i, :], λ[i], r[i]) for i in eachindex(λ)]
end

function _parse_solution_metadata(fp::HDF5.File, ::QUBin)
    return JSON.parse(read(fp["solution"]["metadata"]))
end
