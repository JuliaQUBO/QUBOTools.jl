function write_model(io::IO, model::AbstractModel{V}, fmt::MiniZinc) where {V<:Integer}
    _print_metadata(io, model, fmt)
    _print_domain(io, model, fmt)
    _print_variables(io, model, fmt)
    _print_objective(io, model, fmt)
    _print_sense(io, model, fmt)

    return nothing
end

function _print_metadata(io::IO, model::AbstractModel, ::MiniZinc)
    for (k, v) in metadata(model)
        println(io, "% $(k) : $(JSON.json(v))")
    end

    return nothing
end

function _print_domain(io::IO, model::AbstractModel, ::MiniZinc)
    X = domain(model)

    if X === BoolDomain
        println(io, "set of int: Domain = {0,1};")
    elseif X === SpinDomain
        println(io, "set of int: Domain = {-1,1};")
    else
        error("Invalid domain '$(X)'")
    end

    return nothing
end

function _print_variables(io::IO, model::AbstractModel, ::MiniZinc)
    for i = indices(model)
        k = variable(model, i)
        
        println(io, "var Domain: x$(k);")
    end

    return nothing
end

function _print_objective(io::IO, model::AbstractModel, ::MiniZinc)
    objective_terms = String[]

    println(io, "float: scale = $(scale(model));")
    println(io, "float: offset = $(offset(model));")

    for (i, v) in linear_terms(model)
        xi = "x$(variable(model, i))"

        push!(objective_terms, "$(v)*$(xi)")
    end

    for ((i, j), v) in quadratic_terms(model)
        xi = "x$(variable(model, i))"
        xj = "x$(variable(model, j))"

        push!(objective_terms, "$(v)*$(xi)*$(xj)")
    end

    if !isempty(objective_terms)
        objective_expr = join(objective_terms, " + ")

        println(io, "var float: objective = scale * ($(objective_expr) + offset);") 
    else
        println(io, "var float: objective = scale * offset;")
    end

    return nothing
end

function _print_sense(io::IO, model::AbstractModel, ::MiniZinc)
    s = sense(model)

    if s === Min
        println(io, "solve minimize objective;")
    elseif s === Max
        println(io, "solve maximize objective;")
    else
        error("Invalid sense '$(s)'")
    end

    return nothing
end