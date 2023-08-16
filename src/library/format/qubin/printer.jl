function write_model(
    path::AbstractString,
    model::M,
    fmt::QUBin,
) where {V,T,U,M<:AbstractModel{V,T,U}}
    HDF5.h5open(path, "w") do fp
        write_model(fp, model, fmt)
    end

    return nothing
end

function write_model(
    fp::HDF5.File,
    model::M,
    fmt::QUBin,
) where {V,T,U,M<:AbstractModel{V,T,U}}
    _write_model(fp, model, fmt)
    _write_solution(fp, model, fmt)

    return nothing
end

function write_solution(path::AbstractString, sol::S, fmt::QUBin) where {S<:AbstractSolution}
    HDF5.h5open(path, "w") do fp
        write_solution(fp, sol, fmt)
    end

    return nothing
end

function write_solution(fp::HDF5.File, sol::S, fmt::QUBin) where {S<:AbstractSolution}
    _write_solution(fp, sol, fmt)

    return nothing
end

function _write_model(
    fp::HDF5.File,
    model::M,
    fmt::QUBin,
) where {V,T,U,M<:AbstractModel{V,T,U}}
    HDF5.create_group(fp, "model")

    _write_model_variables(fp, model, fmt)
    _write_model_form(fp, model, fmt)
    _write_model_metadata(fp, model, fmt)

    return nothing
end

function _write_model_variables(
    fp::HDF5.File,
    model::M,
    ::QUBin,
) where {V,T,U,M<:AbstractModel{V,T,U}}
    fp["model"]["variables"] = variables(model)

    return nothing
end

function _write_model_form(
    fp::HDF5.File,
    model::M,
    ::QUBin,
) where {V,T,U,M<:AbstractModel{V,T,U}}
    HDF5.create_group(fp["model"], "form")

    n, L, Q, α, β, s, x = QUBOTools.form(model, QUBOTools.SparseForm{T})

    fp["model"]["form"]["dimension"] = n

    HDF5.create_group(fp["model"]["form"], "linear")

    li, lv = findnz(L)

    write(HDF5.create_dataset(fp["model"]["form"]["linear"], "i", Int, size(li)), li)
    write(HDF5.create_dataset(fp["model"]["form"]["linear"], "v", T, size(lv)), lv)

    HDF5.create_group(fp["model"]["form"], "quadratic")

    qi, qj, qv = findnz(Q)

    write(HDF5.create_dataset(fp["model"]["form"]["quadratic"], "i", Int, size(qi)), qi)
    write(HDF5.create_dataset(fp["model"]["form"]["quadratic"], "j", Int, size(qj)), qj)
    write(HDF5.create_dataset(fp["model"]["form"]["quadratic"], "v", T, size(qv)), qv)

    fp["model"]["form"]["scale"]  = α
    fp["model"]["form"]["offset"] = β

    fp["model"]["form"]["sense"]  = String(s)
    fp["model"]["form"]["domain"] = String(x)

    return nothing
end


function _write_model_metadata(
    fp::HDF5.File,
    model::M,
    ::QUBin,
) where {V,T,U,M<:AbstractModel{V,T,U}}
    fp["model"]["metadata"] = JSON.json(QUBOTools.metadata(model))

    return nothing
end

function _write_solution(
    fp::HDF5.File,
    model::M,
    fmt::QUBin,
) where {V,T,U,M<:AbstractModel{V,T,U}}
    HDF5.create_group(fp, "solution")

    sol = QUBOTools.solution(model)

    _write_solution_data(fp, sol, fmt)

    fp["solution"]["sense"]  = String(sense(sol))
    fp["solution"]["domain"] = String(domain(sol))

    _write_solution_metadata(fp, sol, fmt)

    return nothing
end

function _write_solution_data(
    fp::HDF5.File,
    sol::AbstractSolution{T,U},
    ::QUBin,
) where {T,U}
    HDF5.create_group(fp["solution"], "data")

    if isempty(sol)
        ψ = zeros(U, 0, 0)
        λ = zeros(T, 0)
        r = zeros(Int, 0)
    else
        ψ = state.(sol) |> stack
        λ = value.(sol)
        r = reads.(sol)
    end

    write(HDF5.create_dataset(fp["solution"]["data"], "state", U, size(ψ)), ψ)
    write(HDF5.create_dataset(fp["solution"]["data"], "value", T, size(λ)), λ)
    write(HDF5.create_dataset(fp["solution"]["data"], "reads", Int, size(r)), r)

    return nothing
end

function _write_solution_metadata(
    fp::HDF5.File,
    sol::AbstractSolution{T,U},
    ::QUBin,
) where {T,U}
    fp["solution"]["metadata"] = JSON.json(QUBOTools.metadata(sol))

    return nothing
end
