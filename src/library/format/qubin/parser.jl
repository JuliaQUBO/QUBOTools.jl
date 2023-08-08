function read_model(fp::HDF5.File, fmt::QUBin)
    Φ    = _parse_form(fp, fmt)
    sol  = _parse_solution(fp, fmt)
    data = _parse_metadata(fp, fmt)

    return model
end

function _parse_form(fp::HDF5.File, fmt::QUBin)
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

    return NormalForm(
        n, L, Q, α, β;
        sense  = sense(read(fp["model"]["form"]["sense"])),
        domain = domain(read(fp["model"]["form"]["domain"])),
    )
end