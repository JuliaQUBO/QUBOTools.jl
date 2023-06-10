function name(model::AbstractModel)
    return get(metadata(model), "name", "")
end

function indices(model::AbstractModel)
    return collect(1:dimension(model))
end

function variables(model::AbstractModel{V,T}) where {V,T}
    return collect(variable_inv(model))
end

function variable_set(model::AbstractModel{V,T}) where {V,T}
    return Set{V}(variable_inv(model))
end

function variable_map(model::AbstractModel{V,T}, v::V) where {V,T}
    mapping = variable_map(model)

    if haskey(mapping, v)
        return mapping[v]
    else
        error("Variable '$v' does not belong to the model")

        return nothing
    end
end

function variable_inv(model::AbstractModel, i::Integer)
    mapping = variable_inv(model)

    if haskey(mapping, i)
        return mapping[i]
    else
        error("Variable index '$i' does not belong to the model")

        return nothing
    end
end

function warm_start(model::AbstractModel{V,T}, v::V) where {V,T}
    return get(start(model), v, nothing)
end

# ~*~ Model's Normal Forms ~*~ #
function form(
    model::AbstractModel{_,T},
    ::Type{F};
    domain = domain(model),
) where {_,T,X,F<:AbstractForm{X}}
    Φ = if F <: NormalForm{T}
        form(model)
    else
        F(form(model))
    end

    return cast(QUBOTools.domain(model) => domain, Φ)
end

# ~*~ Data queries ~*~ #
function state(model::AbstractModel, index::Integer)
    return state(solution(model), index)
end

function reads(model::AbstractModel)
    return reads(solution(model))
end

function reads(model::AbstractModel, index::Integer)
    return reads(solution(model), index)
end

function value(model::AbstractModel, index::Integer)
    return value(solution(model), index)
end

function value(model::AbstractModel, ψ::State{U}) where {U}
    return value(form(model), ψ)
end

# ~*~ Queries: sizes & density ~*~ #
dimension(model::AbstractModel) = dimension(form(model))
linear_size(model::AbstractModel) = linear_size(form(model))
quadratic_size(model::AbstractModel) = quadratic_size(form(model))

adjacency(model::AbstractModel)             = adjacency(form(model))
adjacency(model::AbstractModel, k::Integer) = adjacency(form(model), k)

# ~*~ I/O ~*~ #
function Base.copy!(target::X, source::Y) where {X<:AbstractModel,Y<:AbstractModel}
    return copy!(target, convert(X, source))
end

function Base.show(io::IO, model::AbstractModel)
    println(
        io,
        """
        $(name(model)) [$(sense(model)), $(domain(model))]
        ▷ Variables ……… $(dimension(model))  
        """,
    )

    if isempty(model)
        println(
            io,
            """
            The model is empty.
            """,
        )

        return nothing
    else
        println(
            io,
            """
            Density:
            ▷ Linear ……………… $(@sprintf("%0.2f", 100.0 * linear_density(model)))%
            ▷ Quadratic ……… $(@sprintf("%0.2f", 100.0 * quadratic_density(model)))%
            ▷ Total ………………… $(@sprintf("%0.2f", 100.0 * density(model)))%
            """,
        )
    end

    if isempty(solution(model))
        print(
            io,
            """
            There are no solutions available.
            """,
        )

        return nothing
    else
        ω = solution(model)
        n = length(ω)
        z = sense(model) === Min ? value(ω[begin]) : value(ω[end])

        print(
            io,
            """
            Solutions:
            ▷ Samples …………… $(n)
            ▷ Best value …… $(z)
            """,
        )
    end

    return nothing
end
