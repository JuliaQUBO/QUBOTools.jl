function write_model(
    path::AbstractString,
    model::M,
    fmt::QUBin{S},
) where {S,V,T,U,M<:AbstractModel{V,T,U}}
    HDF5.h5open(path, "w") do fp
        write_model(fp, model, fmt)
    end

    return nothing
end

function write_model(
    fp::HDF5.File,
    model::M,
    fmt::QUBin{S},
) where {S,V,T,U,M<:AbstractModel{V,T,U}}
    _write_model(fp, model, fmt)

    _write_solution(fp, model, fmt)

    return nothing
end

function _write_model(
    fp::HDF5.File,
    model::M,
    fmt::QUBin{S},
) where {S,V,T,U,M<:AbstractModel{V,T,U}}
    create_group(fp, "model")

    _write_model_form(fp, model, fmt)

    return nothing
end

function _write_model_form(
    fp::HDF5.File,
    model::M,
    fmt::QUBin{S},
) where {S,V,T,U,M<:AbstractModel{V,T,U}}
    create_group(fp["model"], "form")

    n, L, Q, α, β = QUBOTools.form(model, QUBOTools.SparseForm{T}; domain = domain(fmt))

    fp["model"]["form"]["dimension"] = n

    create_group(fp["model"]["form"], "linear")

    li, lv = findnz(L)

    write(create_dataset(fp["model"]["form"]["linear"], "i", Int, size(li)), li)
    write(create_dataset(fp["model"]["form"]["linear"], "v", T, size(lv)), lv)

    create_group(fp["model"]["form"], "quadratic")

    qi, qj, qv = findnz(Q)

    write(create_dataset(fp["model"]["form"]["quadratic"], "i", Int, size(qi)), qi)
    write(create_dataset(fp["model"]["form"]["quadratic"], "j", Int, size(qj)), qj)
    write(create_dataset(fp["model"]["form"]["quadratic"], "v", T, size(qv)), qv)

    fp["model"]["form"]["scale"]  = α
    fp["model"]["form"]["offset"] = β

    return nothing
end


function _write_model_metadata(
    fp::HDF5.File,
    model::M,
    ::QUBin{S},
) where {S,V,T,U,M<:AbstractModel{V,T,U}}
    fp["model"]["metadata"] = JSON.json(QUBOTools.metadata(model))

    return nothing
end

function _write_solution(
    fp::HDF5.File,
    model::M,
    fmt::QUBin{S},
) where {S,V,T,U,M<:AbstractModel{V,T,U}}
    create_group(fp, "solution")

    sol = QUBOTools.solution(model; domain = domain(fmt))

    _write_solution_data(fp, sol, fmt)

    _write_solution_metadata(fp, sol, fmt)

    return nothing
end

function _write_solution_data(
    fp::HDF5.File,
    sol::AbstractSolution{T,U},
    ::QUBin{S},
) where {S,T,U}
    create_group(fp["solution"], "data")

    if isempty(sol)
        ψ = zeros(U, 0, 0)
        λ = zeros(T, 0)
        r = zeros(Int, 0)
    else
        ψ = state.(sol) |> stack
        λ = value.(sol)
        r = reads.(sol)
    end

    write(create_dataset(fp["solution"], "state", U, size(ψ)), ψ)
    write(create_dataset(fp["solution"], "value", T, size(λ)), λ)
    write(create_dataset(fp["solution"], "reads", Int, size(r)), r)

    return nothing
end

function _write_solution_metadata(
    fp::HDF5.File,
    sol::AbstractSolution{T,U},
    ::QUBin{S},
) where {S,T,U}
    fp["solution"]["metadata"] = JSON.json(QUBOTools.metadata(sol))

    return nothing
end
