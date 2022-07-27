# ~*~ I/O ~*~ #
function Base.write(mod_io::IO, model::AMPL)
    N = BQPIO.domain_size(model)

    obj_terms = []

    for (i, l) in BQPIO.linear_terms(model)
        push!(obj_terms, "$(l)*x[$(i)]")
    end

    for ((i, j), q) in BQPIO.quadratic_terms(model)
        push!(obj_terms, "$(q)*x[$(i)]*x[$(j)]")
    end

    obj_expr = join(obj_terms, "+")

    print(
        mod_io,
        """
        var x {1..$(N)} binary;

        minimize objective:
            $(obj_expr);
        """
    )
end

BQPIO.infer_model_type(::Val{:mod}) = AMPL