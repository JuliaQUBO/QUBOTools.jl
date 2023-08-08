function read_model(path::AbstractString, fmt::QUBin)
    model = nothing

    HDF5.h5open(path, "r") do fp
        model = read_model(fp, fmt)
    end

    return model
end

function read_model(fp::HDF5.File, fmt::QUBin)
    model_form      = _parse_model_form(fp, fmt)
    model_variables = _parse_model_variables(fp, fmt)
    model_metadata  = _parse_model_metadata(fp, fmt)::Dict{String,Any}
    model_solution  = _parse_solution(fp, fmt)

    return Model(
        model_form,
        model_variables;
        metadata = model_metadata,
        solution = model_solution,
    )
end

function _parse_model_form(fp::HDF5.File, fmt::QUBin)
    n = read(fp["model"]["form"]["dimension"])

    li = read(fp["model"]["form"]["linear"]["i"])
    lv = read(fp["model"]["form"]["linear"]["v"])
    
    L = sparsevec(li, lv)

    qi = read(fp["model"]["form"]["quadratic"]["i"])
    qj = read(fp["model"]["form"]["quadratic"]["j"])
    qv = read(fp["model"]["form"]["quadratic"]["v"])

    Q = sparse(qi, qj, qv)

    α = read(fp["model"]["form"]["scale"])
    β = read(fp["model"]["form"]["offset"])

    s = sense(read(fp["model"]["form"]["sense"]))
    x = domain(read(fp["model"]["form"]["domain"]))

    return form(n, L, Q, α, β; sense = s, domain = x)
end

function _parse_solution(fp::HDF5.File, fmt::QUBin)
    sol_data     = _parse_solution_data(fp, fmt)::Vector{Sample{T,U}} where {T,U}
    sol_metadata = _parse_solution_metadata(fp, fmt)

    sol_sense  = sense(read(fp["solution"]["sense"]))
    sol_domain = domain(read(fp["solution"]["domain"]))

    return SampleSet{T,U}(
        sol_data,
        sol_metadata;
        sense  = sol_sense,
        domain = sol_domain,
    )
end

function _parse_solution_data(fp::HDF5.File, fmt::QUBin)
    ψ = read(fp["solution"]["data"]["state"])::Vector{U} where {U}
    λ = read(fp["solution"]["data"]["value"])::Vector{T} where {T}
    r = read(fp["solution"]["data"]["reads"])::Vector{Int}

    return Sample{T,U}[Sample{T,U}(ψ[i], λ[i], r[i]) for i = eachindex(ψ)]
end

function _parse_solution_metadata(fp::HDF5.File, fmt::QUBin)
    return JSON.parse(read(fp["solution"]["metadata"]))
end
