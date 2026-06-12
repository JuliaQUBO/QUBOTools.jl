@doc raw"""
    Form{T,LF,LQ}
"""
struct Form{T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}} <: AbstractForm{T}
    n::Int
    L::LF
    Q::QF
    α::T
    β::T

    frame::Frame
end

function Form{T}(
    n::Integer,
    L::LF,
    Q::QF,
    α::T                         = one(T),
    β::T                         = zero(T);
    sense::Union{Sense,Symbol}   = :min,
    domain::Union{Domain,Symbol} = :bool,
) where {T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    frame = Frame(sense, domain)

    return Form{T,LF,QF}(n, L, Q, α, β, frame)
end

function Form{T,LF,QF}(
    n::Integer,
    L::LF,
    Q::QF,
    α::T                         = one(T),
    β::T                         = zero(T);
    sense::Union{Sense,Symbol}   = :min,
    domain::Union{Domain,Symbol} = :bool,
) where {T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    frame = Frame(sense, domain)

    return Form{T,LF,QF}(n, L, Q, α, β, frame)
end

function Form{T,LF,QF}(
    Φ::F,
) where {T,S,F<:AbstractForm{S},LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    n = dimension(Φ)

    return Form{T,LF,QF}(
        n,
        LF(n, linear_form(Φ)),
        QF(n, quadratic_form(Φ)),
        convert(T, scale(Φ)),
        convert(T, offset(Φ));
        sense  = sense(Φ),
        domain = domain(Φ),
    )
end

function Base.copy(
    Φ::Form{T,LF,QF},
) where {T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    return Form{T,LF,QF}(
        dimension(Φ),
        copy(linear_form(Φ)),
        copy(quadratic_form(Φ)),
        scale(Φ),
        offset(Φ);
        sense  = sense(Φ),
        domain = domain(Φ),
    )
end

function fix_variables(
    Φ::F,
    fix::AbstractDict{<:Integer},
) where {T,F<:AbstractForm{T}}
    n = dimension(Φ)
    fixed = _fix_variables_normalize(fix, domain(Φ), n, T)
    index_map = _fix_variables_index_map(n, fixed)
    m = length(index_map)

    LF = typeof(linear_form(Φ))
    QF = typeof(quadratic_form(Φ))
    l = LF(m, linear_size(Φ))
    q = QF(m, quadratic_size(Φ))
    offset_delta = zero(T)

    for (i, v) in linear_terms(Φ)
        if haskey(fixed, i)
            offset_delta += v * fixed[i]
        else
            ii = index_map[i]

            l[ii] = l[ii] + v
        end
    end

    for ((i, j), v) in quadratic_terms(Φ)
        fixed_i = haskey(fixed, i)
        fixed_j = haskey(fixed, j)

        if fixed_i && fixed_j
            offset_delta += v * fixed[i] * fixed[j]
        elseif fixed_i
            jj = index_map[j]

            l[jj] = l[jj] + v * fixed[i]
        elseif fixed_j
            ii = index_map[i]

            l[ii] = l[ii] + v * fixed[j]
        else
            ii = index_map[i]
            jj = index_map[j]

            if ii < jj
                q[ii, jj] = q[ii, jj] + v
            else
                q[jj, ii] = q[jj, ii] + v
            end
        end
    end

    Φ_reduced = Form{T,LF,QF}(
        m,
        l,
        q,
        scale(Φ),
        offset(Φ) + offset_delta;
        sense  = sense(Φ),
        domain = domain(Φ),
    )

    return Φ_reduced, offset_delta, index_map
end

function fix_variables(fix::AbstractVector{<:Integer}, Φ::AbstractForm)
    throw(
        ArgumentError(
            "fix_variables now expects fix_variables(Φ, fix::AbstractDict) " *
            "with a fixed value for each variable",
        ),
    )
end

function lift_state(
    state_reduced::AbstractVector,
    fix::AbstractDict{<:Integer},
    index_map::AbstractDict{<:Integer,<:Integer},
    n::Integer,
)
    n >= 0 || throw(ArgumentError("state dimension must be nonnegative"))

    fixed = Dict{Int,valtype(fix)}(Int(i) => v for (i, v) in fix)
    map = Dict{Int,Int}(Int(i) => Int(j) for (i, j) in index_map)
    m = length(state_reduced)

    _lift_state_validate(fixed, map, Int(n), m)

    U = promote_type(eltype(state_reduced), valtype(fix))
    state = Vector{U}(undef, Int(n))

    for i in 1:Int(n)
        if haskey(fixed, i)
            state[i] = fixed[i]
        else
            state[i] = state_reduced[map[i]]
        end
    end

    return state
end

function _fix_variables_normalize(
    fix::AbstractDict{<:Integer},
    domain::Domain,
    n::Integer,
    ::Type{T},
) where {T}
    fixed = sizehint!(Dict{Int,T}(), length(fix))

    for (i, v) in fix
        1 <= i <= n || throw(ArgumentError("fixed variable index $i is out of range 1:$n"))

        _fix_variables_validate_value(domain, v)

        fixed[Int(i)] = convert(T, v)
    end

    return fixed
end

function _fix_variables_validate_value(domain::Domain, value)
    if domain === BoolDomain
        value == 0 || value == 1 ||
            throw(ArgumentError("boolean fixed value $value is not in {0, 1}"))
    elseif domain === SpinDomain
        value == -1 || value == 1 ||
            throw(ArgumentError("spin fixed value $value is not in {-1, 1}"))
    else
        throw(ArgumentError("unsupported domain $domain"))
    end

    return nothing
end

function _fix_variables_index_map(n::Integer, fixed::AbstractDict)
    index_map = sizehint!(Dict{Int,Int}(), n - length(fixed))
    j = 0

    for i in 1:n
        haskey(fixed, i) && continue

        j += 1
        index_map[i] = j
    end

    return index_map
end

function _lift_state_validate(
    fixed::AbstractDict{Int},
    index_map::AbstractDict{Int,Int},
    n::Integer,
    m::Integer,
)
    seen = Set{Int}()

    for i in keys(fixed)
        1 <= i <= n || throw(ArgumentError("fixed variable index $i is out of range 1:$n"))
    end

    length(index_map) == m ||
        throw(ArgumentError("reduced state length $m does not match index map length $(length(index_map))"))

    for (i, j) in index_map
        1 <= i <= n || throw(ArgumentError("index_map key $i is out of range 1:$n"))
        !haskey(fixed, i) || throw(ArgumentError("index_map contains fixed variable $i"))
        1 <= j <= m || throw(ArgumentError("reduced variable index $j is out of range 1:$m"))
        j ∉ seen || throw(ArgumentError("index_map contains duplicate reduced index $j"))

        push!(seen, j)
    end

    length(fixed) + length(index_map) == n ||
        throw(ArgumentError("fix and index_map must cover exactly $n variables"))

    return nothing
end

dimension(Φ::Form)      = Φ.n
linear_form(Φ::Form)    = Φ.L
quadratic_form(Φ::Form) = Φ.Q
scale(Φ::Form)          = Φ.α
offset(Φ::Form)         = Φ.β
frame(Φ::Form)          = Φ.frame

function cast(
    (s, t)::Route{S},
    Φ::Form{T,LF,QF},
) where {S<:Sense,T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    @assert s === sense(Φ)

    if s === t
        return Φ # no-op
    else
        n = dimension(Φ)
        L = linear_form(Φ)
        Q = quadratic_form(Φ)
        α = scale(Φ)
        β = -offset(Φ)

        l = LF(n, linear_size(L))
        q = QF(n, quadratic_size(Q))

        for (i, v) in linear_terms(L)
            l[i] = -v
        end

        for ((i, j), v) in quadratic_terms(Q)
            q[i, j] = -v
        end

        return Form{T,LF,QF}(n, l, q, α, β; sense = t, domain = domain(Φ))
    end
end

function cast(
    (s, t)::Route{D},
    Φ::Form{T,LF,QF},
) where {D<:Domain,T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    @assert s === domain(Φ)

    if s === t
        return Φ # no-op
    elseif s === 𝔹 && t === 𝕊
        n = dimension(Φ)
        L = linear_form(Φ)
        Q = quadratic_form(Φ)
        α = scale(Φ)
        β = offset(Φ)

        h = LF(n, linear_size(L))
        J = QF(n, quadratic_size(Q))

        for (i, v) in linear_terms(L)
            h[i] += v / 2
            β    += v / 2
        end

        for ((i, j), v) in quadratic_terms(Q)
            J[i, j] += v / 4
            h[i]    += v / 4
            h[j]    += v / 4
            β       += v / 4
        end

        return Form{T,LF,QF}(n, h, J, α, β; sense = sense(Φ), domain = t)
    elseif s === 𝕊 && t === 𝔹
        n = dimension(Φ)
        h = linear_form(Φ)
        J = quadratic_form(Φ)
        α = scale(Φ)
        β = offset(Φ)

        L = LF(n, linear_size(h))
        Q = QF(n, quadratic_size(J))

        for (i, v) in linear_terms(h)
            L[i] += 2v
            β    -= v
        end

        for ((i, j), v) in quadratic_terms(J)
            Q[i, j] += 4v
            L[i]    -= 2v
            L[j]    -= 2v
            β       += v
        end

        return Form{T,LF,QF}(n, L, Q, α, β; sense = sense(Φ), domain = t)
    else
        casting_error((s => t), Φ)
    end
end

function Form{T,LF,QF}(
    n::Integer,
    L::Any,
    Q::Any,
    α::T = one(T),
    β::T = zero(T);
    sense::Union{Sense,Symbol} = :min,
    domain::Union{Domain,Symbol} = :bool,
) where {T,LF,QF}
    return Form{T,LF,QF}(n, LF(L), QF(Q), α, β; sense, domain)
end
