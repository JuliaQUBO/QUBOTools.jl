function write_model(io::IO, model::AbstractModel, fmt::MiniZinc)
    data = Dict{Symbol,Any}(
        :dimension           => dimension(model),
        :linear_terms        => linear_terms(model),
        :quadratic_terms     => quadratic_terms(model),
        :variable_inv        => variable_inv(model),
        :scale               => scale(model),
        :offset              => offset(model),
        :sense               => sense(model),
        :domain              => domain(model),
        :metadata            => metadata(model),
        # MiniZinc-specific:
        :mzn_variables       => Dict{Int,String}(),
        :mzn_objective_terms => String[],
        :mzn_objective_expr  => "0",
    )

    _print_metadata(io, data, fmt)
    _print_domain(io, data, fmt)
    _print_variables!(io, data, fmt)
    _print_objective!(io, data, fmt)

    return nothing
end

function _print_metadata(io::IO, data::Dict{Symbol,Any}, ::MiniZinc)
    for (k, v) in data[:metadata]
        println(io, "% $(k) : $(JSON.json(v))")
    end

    return nothing
end

function _print_domain(io::IO, data::Dict{Symbol,Any}, ::MiniZinc)
    if data[:domain] === BoolDomain
        println(io, "set of int: Domain = {0,1};")
    elseif data[:domain] === SpinDomain
        println(io, "set of int: Domain = {-1,1};")
    else
        error("Invalid domain '$(data[:domain])'")
    end

    return nothing
end

function _print_variables!(io::IO, data::Dict{Symbol,Any}, ::MiniZinc)
    for i = 1:data[:dimension]
        k = data[:variable_inv][i]

        data[:mzn_variables][k] = "x$(k)"
        
        println(io, "var Domain: $(data[:mzn_variables][k]);")
    end

    return nothing
end

function _print_objective!(io::IO, data::Dict{Symbol,Any}, ::MiniZinc)
    println(io, "float: scale = $(data[:scale]);")
    println(io, "float: offset = $(data[:offset]);")

    for (i, v) in data[:linear_terms]
        xi = data[:mzn_variables][data[:variable_inv][i]]

        push!(data[:mzn_objective_terms], "$(v)*$(xi)")
    end

    for ((i, j), v) in data[:quadratic_terms]
        xi = data[:mzn_variables][data[:variable_inv][i]]
        xj = data[:mzn_variables][data[:variable_inv][j]]

        push!(data[:mzn_objective_terms], "$(v)*$(xi)*$(xj)")
    end

    if !isempty(data[:mzn_objective_terms])
        data[:mzn_objective_expr] = join(data[:mzn_objective_terms], " + ")
    end

    println(io, "var float: objective = scale * ($(data[:mzn_objective_expr]) + offset);")

    if data[:sense] === Min
        println(io, "solve minimize objective;")
    elseif data[:sense] === Max
        println(io, "solve maximize objective;")
    else
        error("Invalid sense '$(data[:sense])'")
    end

    return nothing
end
