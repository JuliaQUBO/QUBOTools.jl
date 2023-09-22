function Base.isempty(model::AbstractModel)
    return iszero(dimension(model))
end

function indices(model::AbstractModel)
    return collect(1:dimension(model))
end

function hasindex(model::AbstractModel, i::Integer)
    return 1 <= i <= dimension(model)
end

function variable(model::AbstractModel{V}, i::Integer) where {V}
    if hasindex(model, i)
        mapping = variables(model)::AbstractVector{V}

        return mapping[i]
    else
        error("Variable with index '$i' does not belong to the model")

        return nothing
    end
end

function hasvariable(model::AbstractModel{V}, v::V) where {V}
    return v ∈ variables(model)
end

# ~*~ Model's Normal Forms ~*~ #
function form(
    model::AbstractModel{V,T,U},
    ::Type{F};
    domain = domain(model),
) where {V,T,U,X,F<:AbstractForm{X}}
    Φ = form(model)

    if !(Φ isa F)
        return cast((QUBOTools.domain(model) => domain), Φ)
    else
        return cast((QUBOTools.domain(model) => domain), F(Φ))
    end
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

# Queries: Dimensions
dimension(model::AbstractModel)      = dimension(form(model))
linear_size(model::AbstractModel)    = linear_size(form(model))
quadratic_size(model::AbstractModel) = quadratic_size(form(model))

# Queries: Topology
topology(model::AbstractModel)             = topology(form(model))
topology(model::AbstractModel, k::Integer) = adjacency(form(model), k)

# Queries: Metadata
function id(model::AbstractModel)
    return get(metadata(model), "id", nothing)
end

function description(model::AbstractModel)
    return get(metadata(model), "description", nothing)
end

# ~*~ I/O ~*~ #
function Base.copy!(target::X, source::Y) where {X<:AbstractModel,Y<:AbstractModel}
    return copy!(target, convert(X, source))
end

function Base.show(io::IO, model::AbstractModel)
    if isempty(model)
        println(
            io,
            """
            QUBOTools Model [$(sense(model)), $(domain(model))]

            The model is empty.
            """,
        )

        return nothing
    else
        println(
            io,
            """
            QUBOTools Model [$(sense(model)), $(domain(model))]
            ▷ Variables ……… $(dimension(model))  

            Density:
            ▷ Linear ……………… $(Printf.@sprintf("%6.2f", 100.0 * linear_density(model)))%
            ▷ Quadratic ……… $(Printf.@sprintf("%6.2f", 100.0 * quadratic_density(model)))%
            ▷ Total ………………… $(Printf.@sprintf("%6.2f", 100.0 * density(model)))%
            """,
        )
    end

    if isempty(start(model))
        print(
            io,
            """
            There are no warm-start values.
            """
        )
    else
        print(
            io,
            """
            Warm-start:
            ▷ Sites ………………… $(length(start(model)))/$(dimension(model))
            """
        )
    end

    println(io)

    if isempty(solution(model))
        print(
            io,
            """
            There are no solutions available.
            """,
        )
    else
        sol = solution(model)
        n = length(sol)
        z = sense(model) === Min ? value(sol[begin]) : value(sol[end])

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

function layout(model::AbstractModel)
    g = QUBOTools.topology(model)
    P = NetworkLayout.layout(NetworkLayout.Shell(; Ptype = Float64), g)

    return Layout(g, P)
end
