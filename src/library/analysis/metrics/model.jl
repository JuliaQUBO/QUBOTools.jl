function density(x)
    n = dimension(x)

    if n == 0
        return NaN
    else
        ls = linear_size(x)
        qs = quadratic_size(x)

        return (2 * qs + ls) / (n * n)
    end
end

function linear_density(x)
    n = dimension(x)

    if n == 0
        return NaN
    else
        ls = linear_size(x)

        return ls / n
    end
end

function quadratic_density(x)
    n = dimension(x)

    if n <= 1
        return NaN
    else
        qs = quadratic_size(x)

        return (2 * qs) / (n * (n - 1))
    end
end

const _COERCIVE_CLUSTER_SPAN_LIMIT = 512

struct _DyadicTerm
    m::BigInt
    e::Int
end

function _canonical_dyadic(m::BigInt, e::Int)
    iszero(m) && return nothing
    tz = trailing_zeros(m)
    return _DyadicTerm(m >> tz, e + tz)
end

function _dyadic_from_float(x::AbstractFloat, shift::Int = 0)
    iszero(x) && return nothing
    p = precision(x)
    ex = exponent(x)
    m_raw = if x isa BigFloat
        setprecision(() -> BigInt(ldexp(x, p - 1 - ex)), BigFloat, p)
    else
        BigInt(ldexp(x, p - 1 - ex))
    end
    return _canonical_dyadic(m_raw, ex - (p - 1) + shift)
end

_dyadic_lsb(t::_DyadicTerm) = t.e
_dyadic_msb(t::_DyadicTerm) = t.e + ndigits(abs(t.m), base = 2) - 1

function _dyadic_add(a::_DyadicTerm, b::_DyadicTerm)
    if a.e >= b.e
        return _canonical_dyadic((a.m << (a.e - b.e)) + b.m, b.e)
    else
        return _canonical_dyadic(a.m + (b.m << (b.e - a.e)), a.e)
    end
end

struct _FloatTermAccum
    terms::Vector{_DyadicTerm}
    has_nan::Bool
    pos_inf::Bool
    neg_inf::Bool
end

_FloatTermAccum() = _FloatTermAccum(_DyadicTerm[], false, false, false)

function _push_scaled_float!(acc::_FloatTermAccum, c::AbstractFloat, shift::Int)
    if isnan(c)
        return _FloatTermAccum(acc.terms, true, acc.pos_inf, acc.neg_inf)
    elseif isinf(c)
        return _FloatTermAccum(
            acc.terms,
            acc.has_nan,
            acc.pos_inf || (c > 0),
            acc.neg_inf || (c < 0),
        )
    elseif iszero(c)
        return acc
    else
        dt = _dyadic_from_float(c, shift)
        dt !== nothing && push!(acc.terms, dt)
        return acc
    end
end

function _reduce_dyadic_terms(
    terms::Vector{_DyadicTerm},
    min_gap::Int = _COERCIVE_CLUSTER_SPAN_LIMIT,
)
    isempty(terms) && return _DyadicTerm[]

    by_e = Dict{Int,BigInt}()
    for t in terms
        by_e[t.e] = get(by_e, t.e, zero(BigInt)) + t.m
    end

    work = _DyadicTerm[]
    sizehint!(work, length(by_e))
    for (e, m) in by_e
        dt = _canonical_dyadic(m, e)
        dt !== nothing && push!(work, dt)
    end

    while length(work) >= 2
        sort!(work; by = t -> (_dyadic_msb(t), t.e), rev = true)
        merged_any = false
        for i = 1:(length(work) - 1)
            a = work[i]
            b = work[i + 1]
            if _dyadic_lsb(a) - _dyadic_msb(b) <= min_gap
                c = _dyadic_add(a, b)
                deleteat!(work, (i, i + 1))
                c !== nothing && push!(work, c)
                merged_any = true
                break
            end
        end
        merged_any || break
    end

    sort!(work; by = t -> (_dyadic_msb(t), t.e), rev = true)
    return work
end

function _exact_float_clusters(
    acc::_FloatTermAccum,
    min_gap::Int = _COERCIVE_CLUSTER_SPAN_LIMIT,
)
    if acc.has_nan || (acc.pos_inf && acc.neg_inf)
        return (:nan, _DyadicTerm[])
    elseif acc.pos_inf
        return (:pos_inf, _DyadicTerm[])
    elseif acc.neg_inf
        return (:neg_inf, _DyadicTerm[])
    elseif isempty(acc.terms)
        return (:finite, _DyadicTerm[])
    else
        return (:finite, _reduce_dyadic_terms(acc.terms, min_gap))
    end
end

function _eval_float_accum(::Type{H}, acc::_FloatTermAccum, ambient_bf_prec::Int) where {H}
    target_prec = H === BigFloat ? ambient_bf_prec : max(256, precision(H) + 64)
    min_gap = max(_COERCIVE_CLUSTER_SPAN_LIMIT, 2 * target_prec + 256)
    status, clusters = _exact_float_clusters(acc, min_gap)
    if status === :nan
        return H === BigFloat ? setprecision(() -> BigFloat(NaN), BigFloat, ambient_bf_prec) : convert(H, NaN)
    elseif status === :pos_inf
        return H === BigFloat ? setprecision(() -> BigFloat(Inf), BigFloat, ambient_bf_prec) : convert(H, Inf)
    elseif status === :neg_inf
        return H === BigFloat ? setprecision(() -> BigFloat(-Inf), BigFloat, ambient_bf_prec) : convert(H, -Inf)
    elseif isempty(clusters)
        return H === BigFloat ? setprecision(() -> zero(BigFloat), BigFloat, ambient_bf_prec) : zero(H)
    else
        c1 = clusters[1]
        c1_bits = ndigits(abs(c1.m), base = 2)
        work_prec = max(256, c1_bits, target_prec) + 64
        adjusted = setprecision(BigFloat, work_prec) do
            base = ldexp(BigFloat(c1.m), c1.e)
            if length(clusters) >= 2
                return clusters[2].m > 0 ? nextfloat(base) : prevfloat(base)
            else
                return base
            end
        end
        if H === BigFloat
            return setprecision(() -> BigFloat(adjusted), BigFloat, ambient_bf_prec)
        else
            return convert(H, adjusted)
        end
    end
end

function _float_accum_abs_le_atol(acc::_FloatTermAccum, atol::Real)
    status, clusters = _exact_float_clusters(acc, _COERCIVE_CLUSTER_SPAN_LIMIT)
    status === :nan && return false
    isinf(atol) && return true
    (status === :pos_inf || status === :neg_inf) && return false
    isempty(clusters) && return true
    iszero(atol) && return false

    s1 = sign(clusters[1].m)
    diff_terms = _DyadicTerm[]
    sizehint!(diff_terms, length(clusters) + 1)

    if atol isa Rational
        atol_rat = Rational{BigInt}(atol)
        p = numerator(atol_rat)
        q = denominator(atol_rat)
        for t in clusters
            dt = _canonical_dyadic(s1 * q * t.m, t.e)
            dt !== nothing && push!(diff_terms, dt)
        end
        dt_p = _canonical_dyadic(-p, 0)
        dt_p !== nothing && push!(diff_terms, dt_p)
    elseif atol isa Integer
        p = BigInt(atol)
        for t in clusters
            push!(diff_terms, _DyadicTerm(s1 * t.m, t.e))
        end
        dt_p = _canonical_dyadic(-p, 0)
        dt_p !== nothing && push!(diff_terms, dt_p)
    elseif atol isa AbstractFloat
        for t in clusters
            push!(diff_terms, _DyadicTerm(s1 * t.m, t.e))
        end
        dt_a = _dyadic_from_float(atol)
        dt_a !== nothing && push!(diff_terms, _DyadicTerm(-dt_a.m, dt_a.e))
    else
        return _float_accum_abs_le_atol(acc, Rational{BigInt}(atol))
    end

    diff_reduced = _reduce_dyadic_terms(diff_terms, _COERCIVE_CLUSTER_SPAN_LIMIT)
    return isempty(diff_reduced) || diff_reduced[1].m < 0
end

function _float_accum_sign_above_atol(acc::_FloatTermAccum, atol::Real)
    status, clusters = _exact_float_clusters(acc, _COERCIVE_CLUSTER_SPAN_LIMIT)
    status === :nan && return nothing
    isinf(atol) && return 0
    status === :pos_inf && return 1
    status === :neg_inf && return -1
    isempty(clusters) && return 0
    s1 = Int(sign(clusters[1].m))
    iszero(atol) && return s1
    return _float_accum_abs_le_atol(acc, atol) ? 0 : s1
end

function _float_accum_strictly_dominates_l1(
    field_acc::_FloatTermAccum,
    l1_acc::_FloatTermAccum,
    atol::Real,
)
    f_status, f_clusters = _exact_float_clusters(field_acc, _COERCIVE_CLUSTER_SPAN_LIMIT)
    l1_status, l1_clusters = _exact_float_clusters(l1_acc, _COERCIVE_CLUSTER_SPAN_LIMIT)
    (f_status === :nan || l1_status === :nan) && return false
    isinf(atol) && return false
    l1_status === :pos_inf && return false
    (f_status === :pos_inf || f_status === :neg_inf) && return true
    isempty(f_clusters) && return false

    s1 = sign(f_clusters[1].m)
    diff_terms = _DyadicTerm[]
    sizehint!(diff_terms, length(f_clusters) + length(l1_clusters) + 1)

    if atol isa Rational
        atol_rat = Rational{BigInt}(atol)
        p = numerator(atol_rat)
        q = denominator(atol_rat)
        for t in f_clusters
            dt = _canonical_dyadic(s1 * q * t.m, t.e)
            dt !== nothing && push!(diff_terms, dt)
        end
        for t in l1_clusters
            dt = _canonical_dyadic(-q * t.m, t.e)
            dt !== nothing && push!(diff_terms, dt)
        end
        dt_p = _canonical_dyadic(-p, 0)
        dt_p !== nothing && push!(diff_terms, dt_p)
    elseif atol isa Integer
        p = BigInt(atol)
        for t in f_clusters
            push!(diff_terms, _DyadicTerm(s1 * t.m, t.e))
        end
        for t in l1_clusters
            push!(diff_terms, _DyadicTerm(-t.m, t.e))
        end
        dt_p = _canonical_dyadic(-p, 0)
        dt_p !== nothing && push!(diff_terms, dt_p)
    elseif atol isa AbstractFloat
        for t in f_clusters
            push!(diff_terms, _DyadicTerm(s1 * t.m, t.e))
        end
        for t in l1_clusters
            push!(diff_terms, _DyadicTerm(-t.m, t.e))
        end
        dt_a = _dyadic_from_float(atol)
        dt_a !== nothing && push!(diff_terms, _DyadicTerm(-dt_a.m, dt_a.e))
    else
        return _float_accum_strictly_dominates_l1(field_acc, l1_acc, Rational{BigInt}(atol))
    end

    diff_reduced = _reduce_dyadic_terms(diff_terms, _COERCIVE_CLUSTER_SPAN_LIMIT)
    return !isempty(diff_reduced) && diff_reduced[1].m > 0
end

function _form_float_field_accums(Φ::AbstractForm{T}) where {T<:AbstractFloat}
    n = dimension(Φ)
    field_acc = [_FloatTermAccum() for _ = 1:n]
    l1_acc = [_FloatTermAccum() for _ = 1:n]
    is_bool = domain(Φ) === BoolDomain
    lin_shift = is_bool ? -1 : 0
    quad_shift = is_bool ? -2 : 0

    for (i, v) in linear_terms(Φ)
        field_acc[i] = _push_scaled_float!(field_acc[i], v, lin_shift)
    end

    for ((i, j), v) in quadratic_terms(Φ)
        if is_bool
            field_acc[i] = _push_scaled_float!(field_acc[i], v, quad_shift)
            field_acc[j] = _push_scaled_float!(field_acc[j], v, quad_shift)
        end
        abs_v = abs(v)
        l1_acc[i] = _push_scaled_float!(l1_acc[i], abs_v, quad_shift)
        l1_acc[j] = _push_scaled_float!(l1_acc[j], abs_v, quad_shift)
    end

    return field_acc, l1_acc
end

_coercive_accum_type(::Type{<:Integer}) = BigInt
_coercive_accum_type(::Type{<:Rational}) = Rational{BigInt}
_coercive_accum_type(::Type{T}) where {T} = typeof(zero(T) + zero(T))

function _form_exact_quad_field_sums(Φ::AbstractForm{T}) where {T}
    n = dimension(Φ)
    A = _coercive_accum_type(T)
    field4 = zeros(A, n)
    l1_4 = zeros(A, n)
    is_bool = domain(Φ) === BoolDomain
    lin_mult = is_bool ? convert(A, 2) : convert(A, 4)
    quad_mult = is_bool ? convert(A, 1) : convert(A, 4)

    for (i, v) in linear_terms(Φ)
        field4[i] += lin_mult * convert(A, v)
    end

    for ((i, j), v) in quadratic_terms(Φ)
        v_acc = convert(A, v)
        if is_bool
            field4[i] += v_acc
            field4[j] += v_acc
        end
        abs_q4 = quad_mult * abs(v_acc)
        l1_4[i] += abs_q4
        l1_4[j] += abs_q4
    end

    return field4, l1_4
end

_quarter_to_field(::Type{H}, f4::BigInt) where {H} = convert(H, f4 // 4)
_quarter_to_field(::Type{H}, f4::Rational{BigInt}) where {H} = convert(H, f4 / 4)
_quarter_to_field(::Type{H}, f4) where {H} = convert(H, f4 / 4)

function _quarter_abs_le_atol(::Type{H}, f4::BigInt, atol::Real) where {H}
    iszero(atol) && return iszero(f4)
    isinf(atol) && return true
    return abs(f4 // 4) <= Rational{BigInt}(atol)
end

function _quarter_abs_le_atol(::Type{H}, f4::Rational{BigInt}, atol::Real) where {H}
    iszero(atol) && return iszero(f4)
    isinf(atol) && return true
    return abs(f4 / 4) <= Rational{BigInt}(atol)
end

function _quarter_abs_le_atol(::Type{H}, f4, atol::Real) where {H}
    return abs(_quarter_to_field(H, f4)) <= atol
end

function _quarter_sign_above_atol(::Type{H}, f4::BigInt, atol::Real) where {H}
    isinf(atol) && return 0
    iszero(f4) && return 0
    iszero(atol) && return Int(sign(f4))
    return _quarter_abs_le_atol(H, f4, atol) ? 0 : Int(sign(f4))
end

function _quarter_sign_above_atol(::Type{H}, f4::Rational{BigInt}, atol::Real) where {H}
    isinf(atol) && return 0
    iszero(f4) && return 0
    iszero(atol) && return Int(sign(f4))
    return _quarter_abs_le_atol(H, f4, atol) ? 0 : Int(sign(f4))
end

function _quarter_sign_above_atol(::Type{H}, f4, atol::Real) where {H}
    val = _quarter_to_field(H, f4)
    isnan(val) && return nothing
    isinf(atol) && return 0
    abs(val) <= atol && return 0
    return val > 0 ? 1 : -1
end

function _quarter_strictly_dominates_l1(::Type{H}, f4::BigInt, l1_4::BigInt, atol::Real) where {H}
    isinf(atol) && return false
    diff4 = abs(f4) - l1_4
    iszero(atol) && return diff4 > 0
    return (diff4 // 4) > Rational{BigInt}(atol)
end

function _quarter_strictly_dominates_l1(
    ::Type{H},
    f4::Rational{BigInt},
    l1_4::Rational{BigInt},
    atol::Real,
) where {H}
    isinf(atol) && return false
    diff4 = abs(f4) - l1_4
    iszero(atol) && return diff4 > 0
    return (diff4 / 4) > Rational{BigInt}(atol)
end

function _quarter_strictly_dominates_l1(::Type{H}, f4, l1_4, atol::Real) where {H}
    isinf(atol) && return false
    return abs(_quarter_to_field(H, f4)) > _quarter_to_field(H, l1_4) + atol
end

function coercive_fields(Φ::AbstractForm{T}) where {T}
    n = dimension(Φ)
    H = typeof(zero(T) / 4)
    out = Vector{H}(undef, n)

    if T <: AbstractFloat
        ambient_prec = precision(BigFloat)
        field_acc, _ = _form_float_field_accums(Φ)
        for i = 1:n
            out[i] = _eval_float_accum(H, field_acc[i], ambient_prec)
        end
    else
        field4, _ = _form_exact_quad_field_sums(Φ)
        for i = 1:n
            out[i] = _quarter_to_field(H, field4[i])
        end
    end

    return out
end

coercive_fields(model::AbstractModel) = coercive_fields(form(model))

function _abs_field_bigfloat(acc::_FloatTermAccum)
    status, clusters = _exact_float_clusters(acc, _COERCIVE_CLUSTER_SPAN_LIMIT)
    status === :nan && return BigFloat(NaN)
    (status === :pos_inf || status === :neg_inf) && return BigFloat(Inf)
    isempty(clusters) && return zero(BigFloat)
    s1 = sign(clusters[1].m)
    c1 = clusters[1]
    base = ldexp(BigFloat(s1 * c1.m), c1.e)
    if length(clusters) >= 2
        c2 = clusters[2]
        base += ldexp(BigFloat(s1 * c2.m), c2.e)
    end
    return base
end

function _row_lp_norm_bigfloat(vals::Vector{BigFloat}, p::Real)
    isempty(vals) && return zero(BigFloat)
    any(isnan, vals) && return BigFloat(NaN)
    any(isinf, vals) && return BigFloat(Inf)

    max_v = maximum(vals)
    iszero(max_v) && return zero(BigFloat)
    isinf(p) && return max_v
    if p == 1
        s = zero(BigFloat)
        for v in vals
            s += v
        end
        return s
    elseif p == 2
        s = zero(BigFloat)
        for v in vals
            r = v / max_v
            s += r * r
        end
        return max_v * sqrt(s)
    else
        p_bf = BigFloat(p)
        s = zero(BigFloat)
        for v in vals
            s += (v / max_v)^p_bf
        end
        return max_v * (s^(inv(p_bf)))
    end
end

function _coercive_ratios_and_active_mask(Φ::AbstractForm{T}; norm::Real = 2) where {T}
    (norm > 0 && !isnan(norm)) ||
        throw(ArgumentError("norm must be positive; got $norm"))

    n = dimension(Φ)
    ratios = zeros(Float64, n)
    active = falses(n)
    n == 0 && return ratios, active

    ambient_prec = precision(BigFloat)
    work_prec = max(256, ambient_prec + 64)
    is_bool = domain(Φ) === BoolDomain

    setprecision(BigFloat, work_prec) do
        row_couplings = [BigFloat[] for _ = 1:n]
        for ((i, j), v) in quadratic_terms(Φ)
            v_bf = if v isa AbstractFloat && !(v isa BigFloat) && !isnan(v) && !isinf(v) && !iszero(v)
                dt = _dyadic_from_float(abs(v), is_bool ? -2 : 0)
                dt === nothing ? zero(BigFloat) : ldexp(BigFloat(dt.m), dt.e)
            elseif v isa BigFloat && !isnan(v) && !isinf(v) && !iszero(v)
                dt = _dyadic_from_float(abs(v), is_bool ? -2 : 0)
                dt === nothing ? zero(BigFloat) : ldexp(BigFloat(dt.m), dt.e)
            else
                c_bf = abs(BigFloat(v))
                is_bool ? ldexp(c_bf, -2) : c_bf
            end
            if !iszero(v_bf) || isnan(v_bf)
                push!(row_couplings[i], v_bf)
                push!(row_couplings[j], v_bf)
            end
        end

        abs_h_vec = Vector{BigFloat}(undef, n)
        if T <: AbstractFloat
            field_acc, _ = _form_float_field_accums(Φ)
            for i = 1:n
                abs_h_vec[i] = _abs_field_bigfloat(field_acc[i])
            end
        else
            field4, _ = _form_exact_quad_field_sums(Φ)
            for i = 1:n
                abs_h_vec[i] = abs(BigFloat(field4[i])) / 4
            end
        end

        for i = 1:n
            abs_h = abs_h_vec[i]
            j_norm = _row_lp_norm_bigfloat(row_couplings[i], norm)
            if isnan(abs_h) || isnan(j_norm)
                ratios[i] = NaN
                active[i] = !isempty(row_couplings[i])
            elseif iszero(j_norm)
                ratios[i] = iszero(abs_h) ? 0.0 : Inf
                active[i] = false
            else
                ratios[i] = Float64(abs_h / j_norm)
                active[i] = true
            end
        end
    end

    return ratios, active
end

function coercive_field_ratios(Φ::AbstractForm; norm::Real = 2)::Vector{Float64}
    ratios, _ = _coercive_ratios_and_active_mask(Φ; norm)
    return ratios
end

coercive_field_ratios(model::AbstractModel; norm::Real = 2) =
    coercive_field_ratios(form(model); norm)

function coercive_field_ratio(Φ::AbstractForm; norm::Real = 2)::Float64
    ratios, active = _coercive_ratios_and_active_mask(Φ; norm)
     k = count(active)
    k == 0 && return NaN

    return setprecision(BigFloat, 256) do
        s = zero(BigFloat)
        for i in eachindex(ratios)
            if active[i]
                r = ratios[i]
                isnan(r) && return NaN
                isinf(r) && return Inf
                s += BigFloat(r)
            end
        end
        return Float64(s / k)
    end
end

coercive_field_ratio(model::AbstractModel; norm::Real = 2) =
    coercive_field_ratio(form(model); norm)

function is_gauge_invariant(Φ::AbstractForm{T}; atol::Real = 0.0)::Bool where {T}
    (atol >= 0 && !isnan(atol)) ||
        throw(ArgumentError("atol must be nonnegative; got $atol"))
    n = dimension(Φ)
    n == 0 && return true

    if T <: AbstractFloat
        field_acc, _ = _form_float_field_accums(Φ)
        for i = 1:n
            _float_accum_abs_le_atol(field_acc[i], atol) || return false
        end
        return true
    else
        H = typeof(zero(T) / 4)
        field4, _ = _form_exact_quad_field_sums(Φ)
        for i = 1:n
            _quarter_abs_le_atol(H, field4[i], atol) || return false
        end
        return true
    end
end

is_gauge_invariant(model::AbstractModel; atol::Real = 0.0)::Bool =
    is_gauge_invariant(form(model); atol)

function zero_field_fraction(Φ::AbstractForm{T}; atol::Real = 0.0)::Float64 where {T}
    (atol >= 0 && !isnan(atol)) ||
        throw(ArgumentError("atol must be nonnegative; got $atol"))
    n = dimension(Φ)
    n == 0 && return NaN

    zero_count = 0
    if T <: AbstractFloat
        field_acc, _ = _form_float_field_accums(Φ)
        for i = 1:n
            if _float_accum_abs_le_atol(field_acc[i], atol)
                zero_count += 1
            end
        end
    else
        H = typeof(zero(T) / 4)
        field4, _ = _form_exact_quad_field_sums(Φ)
        for i = 1:n
            if _quarter_abs_le_atol(H, field4[i], atol)
                zero_count += 1
            end
        end
    end

    return zero_count / n
end

zero_field_fraction(model::AbstractModel; atol::Real = 0.0)::Float64 =
    zero_field_fraction(form(model); atol)

function trivial_dominance_fraction(Φ::AbstractForm{T}; atol::Real = 0.0)::Float64 where {T}
    (atol >= 0 && !isnan(atol)) ||
        throw(ArgumentError("atol must be nonnegative; got $atol"))
    n = dimension(Φ)
    n == 0 && return NaN

    dom_count = 0
    if T <: AbstractFloat
        field_acc, l1_acc = _form_float_field_accums(Φ)
        for i = 1:n
            if _float_accum_strictly_dominates_l1(field_acc[i], l1_acc[i], atol)
                dom_count += 1
            end
        end
    else
        H = typeof(zero(T) / 4)
        field4, l1_4 = _form_exact_quad_field_sums(Φ)
        for i = 1:n
            if _quarter_strictly_dominates_l1(H, field4[i], l1_4[i], atol)
                dom_count += 1
            end
        end
    end

    return dom_count / n
end

trivial_dominance_fraction(model::AbstractModel; atol::Real = 0.0)::Float64 =
    trivial_dominance_fraction(form(model); atol)

function _convert_checked_coeff(::Type{T}, val_big::BigInt, context::AbstractString) where {T<:Integer}
    if T !== BigInt && (val_big < BigInt(typemin(T)) || val_big > BigInt(typemax(T)))
        throw(
            ArgumentError(
                "cannot represent $context $val_big in integer coefficient type $T",
            ),
        )
    end
    return convert(T, val_big)
end

function gauge_invariant_qubo(
    Φ::Form{T,LF,QF};
    keep_offset::Bool = true,
) where {T,LF<:AbstractLinearForm{T},QF<:AbstractQuadraticForm{T}}
    n = dimension(Φ)
    q_new = copy(quadratic_form(Φ))
    is_bool = domain(Φ) === BoolDomain

    if is_bool
        l_new = LF(n, n)
        if T <: AbstractFloat
            ambient_prec = precision(BigFloat)
            neg_half_acc = [_FloatTermAccum() for _ = 1:n]
            for ((i, j), v) in quadratic_terms(Φ)
                neg_half_acc[i] = _push_scaled_float!(neg_half_acc[i], -v, -1)
                neg_half_acc[j] = _push_scaled_float!(neg_half_acc[j], -v, -1)
            end
            for i = 1:n
                c_i = _eval_float_accum(T, neg_half_acc[i], ambient_prec)
                if !iszero(c_i)
                    l_new[i] = c_i
                end
            end
        else
            A = _coercive_accum_type(T)
            row_sums = zeros(A, n)
            for ((i, j), v) in quadratic_terms(Φ)
                v_acc = convert(A, v)
                row_sums[i] += v_acc
                row_sums[j] += v_acc
            end
            for i = 1:n
                q_i = row_sums[i]
                iszero(q_i) && continue
                c_i = if T <: Integer
                    iseven(q_i) || throw(
                        ArgumentError(
                            "cannot represent half-integer gauge-invariant linear coefficient -($q_i)/2 for variable $i in integer form type $(typeof(Φ))",
                        ),
                    )
                    _convert_checked_coeff(T, -div(q_i, 2), "gauge-invariant linear coefficient")
                else
                    convert(T, -(q_i / 2))
                end
                if !iszero(c_i)
                    l_new[i] = c_i
                end
            end
        end

        β_new = keep_offset ? offset(Φ) : zero(T)
        return Form{T,LF,QF}(n, l_new, q_new, scale(Φ), β_new; sense = sense(Φ), domain = domain(Φ))
    else
        l_new = LF(n, 0)
        β_new = if keep_offset
            offset(Φ)
        elseif T <: AbstractFloat
            ambient_prec = precision(BigFloat)
            neg_quad_sum = _FloatTermAccum()
            for (_, v) in quadratic_terms(Φ)
                neg_quad_sum = _push_scaled_float!(neg_quad_sum, -v, 0)
            end
            _eval_float_accum(T, neg_quad_sum, ambient_prec)
        else
            A = _coercive_accum_type(T)
            q_total = zero(A)
            for (_, v) in quadratic_terms(Φ)
                q_total += convert(A, v)
            end
            if T <: Integer
                _convert_checked_coeff(T, -q_total, "gauge-invariant spin offset")
            else
                convert(T, -q_total)
            end
        end

        return Form{T,LF,QF}(n, l_new, q_new, scale(Φ), β_new; sense = sense(Φ), domain = domain(Φ))
    end
end

function gauge_invariant_qubo(
    Φ::AbstractForm{T};
    keep_offset::Bool = true,
) where {T}
    return gauge_invariant_qubo(SparseForm{T}(Φ); keep_offset)
end

function gauge_invariant_qubo(
    model::Model{V,T,U};
    keep_offset::Bool = true,
) where {V,T,U}
    new_form = gauge_invariant_qubo(form(model); keep_offset)
    empty_sol = SampleSet{T,U}(; sense = sense(model), domain = domain(model))
    return Model{V,T,U,typeof(new_form)}(
        copy(model.variable_map),
        new_form,
        deepcopy(metadata(model)),
        empty_sol,
        deepcopy(model.start),
    )
end
