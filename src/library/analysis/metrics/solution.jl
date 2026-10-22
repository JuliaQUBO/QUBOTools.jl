function _solution_time_dict(sol::AbstractSolution)
    data = metadata(sol)
    data isa AbstractDict ||
        throw(ArgumentError("Solution metadata must be a dictionary"))

    if !haskey(data, "time")
        return nothing
    end

    time_data = data["time"]
    time_data isa AbstractDict ||
        throw(ArgumentError("Solution metadata 'time' entry must be a dictionary"))

    return time_data
end

function _solution_time_entry(time_data::AbstractDict, key::String)
    if !haskey(time_data, key)
        return nothing
    end

    val = time_data[key]
    val isa Real ||
        throw(ArgumentError("Solution metadata 'time.$(key)' must be a real number"))

    return Float64(val)
end

function total_time(sol::AbstractSolution)
    time_data = _solution_time_dict(sol)
    isnothing(time_data) && return NaN

    val = _solution_time_entry(time_data, "total")
    return isnothing(val) ? NaN : val
end

function effective_time(sol::AbstractSolution)
    time_data = _solution_time_dict(sol)
    isnothing(time_data) && return NaN

    val = _solution_time_entry(time_data, "effective")
    return isnothing(val) ? total_time(sol) : val
end

const _NON_IID_SAMPLING_REGIMES = Set{String}([
    "correlated",
    "selected",
    "repaired",
    "best_only",
    "postselected",
    "top_k",
    "filtered",
    "trajectory",
])

function _normalize_token(x::Union{Symbol,AbstractString})
    return replace(lowercase(strip(String(x))), '-' => '_', ' ' => '_')
end

function _non_iid_read_regime(sol::AbstractSolution)
    data = metadata(sol)
    data isa AbstractDict ||
        throw(ArgumentError("Solution metadata must be a dictionary"))

    for key in ("sampling_regime", "trial_semantics", "sample_selection", "selection")
        if haskey(data, key) && !isnothing(data[key])
            token = _normalize_token(string(data[key]))
            if token in _NON_IID_SAMPLING_REGIMES
                return token
            end
        end
    end

    for flag_key in ("independent_reads", "iid_reads")
        if haskey(data, flag_key) && data[flag_key] === false
            return "non_iid_reads"
        end
    end

    if haskey(data, "sampling") && data["sampling"] isa AbstractDict
        sampling = data["sampling"]
        for key in ("regime", "sampling_regime", "trial_semantics", "selection")
            if haskey(sampling, key) && !isnothing(sampling[key])
                token = _normalize_token(string(sampling[key]))
                if token in _NON_IID_SAMPLING_REGIMES
                    return token
                end
            end
        end
        for flag_key in ("independent_reads", "iid_reads")
            if haskey(sampling, flag_key) && sampling[flag_key] === false
                return "non_iid_reads"
            end
        end
    end

    return nothing
end

function _normalize_trial_unit(unit::Union{Symbol,AbstractString})
    token = _normalize_token(unit)
    if token in ("read", "reads")
        return :read
    elseif token in ("run", "runs", "batch")
        return :run
    elseif token == "trial"
        return :trial
    else
        throw(
            ArgumentError(
                "Unsupported `trial_unit = $(repr(unit))`; supported values are `:read` and `:run`",
            ),
        )
    end
end

function _resolve_trial_unit(
    sol::AbstractSolution,
    trial_unit::Union{Symbol,AbstractString,Nothing},
)
    regime = _non_iid_read_regime(sol)

    resolved = if !isnothing(trial_unit)
        _normalize_trial_unit(trial_unit)
    else
        data = metadata(sol)
        if haskey(data, "trial_unit") && !isnothing(data["trial_unit"])
            _normalize_trial_unit(string(data["trial_unit"]))
        else
            throw(
                ArgumentError(
                    "Ambiguous trial semantics for solution with $(isempty(sol) ? 0 : reads(sol)) reads: pass `trial_unit = :read` (independent reads) or `trial_unit = :run` (single solver run)",
                ),
            )
        end
    end

    if resolved === :read && !isnothing(regime)
        throw(
            ArgumentError(
                "Cannot apply IID per-read semantics (`trial_unit = :read`) to solution marked with sampling regime '$(regime)'; use `trial_unit = :run`",
            ),
        )
    end

    return resolved
end

function _normalize_cost_boundary(boundary::Union{Symbol,AbstractString})
    token = _normalize_token(boundary)
    if token in ("effective", "backend_effective", "backend")
        return :effective
    elseif token in ("total", "solver_wall", "wall")
        return :total
    elseif token in ("complete", "end_to_end", "caller_supplied")
        return :complete
    elseif token == "unspecified"
        return :unspecified
    else
        throw(
            ArgumentError(
                "Unsupported `cost_boundary = $(repr(boundary))`; supported values are `:effective`, `:total`, and `:complete`",
            ),
        )
    end
end

function _normalize_repetition_mode(mode::Union{Symbol,AbstractString})
    token = _normalize_token(mode)
    if token in ("integer", "operational", "discrete")
        return :integer
    elseif token in ("continuous_floor_one", "floor_one")
        return :continuous_floor_one
    elseif token in ("continuous", "relaxed")
        return :continuous
    else
        throw(
            ArgumentError(
                "Unsupported `repetition_mode = $(repr(mode))`; supported values are `:integer`, `:continuous_floor_one`, and `:continuous`",
            ),
        )
    end
end

function _validate_positive_duration(t::Real, label::AbstractString)
    val = Float64(t)
    (isfinite(val) && val > 0.0) || throw(
        ArgumentError("$(label) must be finite and strictly positive; got $(repr(t))"),
    )
    return val
end

function _validate_target_probability(s::Real)
    val = Float64(s)
    (isfinite(val) && 0.0 < val < 1.0) || throw(
        ArgumentError(
            "Target success probability `s` must be finite and satisfy `0 < s < 1`; got $(repr(s))",
        ),
    )
    return val
end

function _validate_trial_probability(p::Real)
    val = Float64(p)
    (isfinite(val) && 0.0 <= val <= 1.0) || throw(
        ArgumentError(
            "Trial success probability `p` must be finite and satisfy `0 <= p <= 1`; got $(repr(p))",
        ),
    )
    return val
end

function _extract_boundary_batch_time(
    sol::AbstractSolution,
    boundary::Symbol;
    batch_time::Union{Real,Nothing} = nothing,
)
    if !isnothing(batch_time)
        return _validate_positive_duration(batch_time, "batch_time")
    end

    time_data = _solution_time_dict(sol)

    if boundary === :effective
        isnothing(time_data) && throw(
            ArgumentError(
                "Solution metadata is missing 'time.effective' required by `cost_boundary = :effective`",
            ),
        )
        val = _solution_time_entry(time_data, "effective")
        isnothing(val) && throw(
            ArgumentError(
                "Solution metadata is missing 'time.effective' required by `cost_boundary = :effective` (refusing to silently substitute 'time.total')",
            ),
        )
        return _validate_positive_duration(val, "metadata[\"time\"][\"effective\"]")
    elseif boundary === :total
        isnothing(time_data) && throw(
            ArgumentError(
                "Solution metadata is missing 'time.total' required by `cost_boundary = :total`",
            ),
        )
        val = _solution_time_entry(time_data, "total")
        isnothing(val) && throw(
            ArgumentError(
                "Solution metadata is missing 'time.total' required by `cost_boundary = :total` (refusing to silently substitute 'time.effective')",
            ),
        )
        return _validate_positive_duration(val, "metadata[\"time\"][\"total\"]")
    elseif boundary === :complete
        if !isnothing(time_data)
            val = _solution_time_entry(time_data, "complete")
            if !isnothing(val)
                return _validate_positive_duration(val, "metadata[\"time\"][\"complete\"]")
            end
        end
        throw(
            ArgumentError(
                "`cost_boundary = :complete` requires caller-supplied `trial_time` or `batch_time` (or `metadata[\"time\"][\"complete\"]`); backend or solver timing is never silently relabeled as complete cost",
            ),
        )
    else
        throw(ArgumentError("Unsupported cost boundary `$(repr(boundary))` for solution timing"))
    end
end

function _empirical_read_counts(solution::AbstractSolution, λ::Real)
    isnan(λ) && throw(ArgumentError("Target threshold `λ` cannot be NaN"))

    total_reads = 0
    successful_reads = 0

    for sample in solution
        k = reads(sample)
        k >= 0 || throw(ArgumentError("Sample read count must be non-negative; got $(k)"))
        val = value(sample)
        isnan(val) && throw(ArgumentError("Sample objective value cannot be NaN"))

        total_reads += k

        if sense(solution) === Min
            if val <= λ
                successful_reads += k
            end
        else # sense(solution) === Max
            if val >= λ
                successful_reads += k
            end
        end
    end

    return (trials = total_reads, successes = successful_reads)
end

function _empirical_trial_counts(
    solution::AbstractSolution,
    λ::Real,
    trial_unit::Symbol,
)
    isempty(solution) && throw(
        ArgumentError("Cannot estimate empirical success probability from an empty solution"),
    )

    counts = _empirical_read_counts(solution, λ)
    counts.trials > 0 || throw(
        ArgumentError("Cannot estimate empirical success probability when total reads is zero"),
    )

    if trial_unit === :read
        regime = _non_iid_read_regime(solution)
        if !isnothing(regime)
            throw(
                ArgumentError(
                    "Cannot apply IID per-read semantics (`trial_unit = :read`) to solution marked with sampling regime '$(regime)'; use `trial_unit = :run`",
                ),
            )
        end
        return counts
    elseif trial_unit === :run
        return (trials = 1, successes = counts.successes > 0 ? 1 : 0)
    else
        throw(ArgumentError("Unsupported `trial_unit = $(repr(trial_unit))`"))
    end
end

function success_rate(
    solution::AbstractSolution{T,U},
    λ::Real;
    trial_unit::Union{Symbol,AbstractString} = :read,
) where {T,U}
    unit = _normalize_trial_unit(trial_unit)
    if unit === :read
        regime = _non_iid_read_regime(solution)
        if !isnothing(regime)
            throw(
                ArgumentError(
                    "Cannot compute per-read `success_rate` (`trial_unit = :read`) on solution marked with sampling regime '$(regime)'; pass `trial_unit = :run`",
                ),
            )
        end
    end

    if isempty(solution)
        return NaN
    end

    counts = _empirical_read_counts(solution, λ)
    if counts.trials == 0
        return NaN
    elseif unit === :read
        return counts.successes / counts.trials
    elseif unit === :run
        return counts.successes > 0 ? 1.0 : 0.0
    else
        throw(ArgumentError("Unsupported `trial_unit = $(repr(trial_unit))`"))
    end
end

function success_rate(
    solutions::AbstractVector{<:AbstractSolution},
    λ::Real;
    trial_unit::Union{Symbol,AbstractString} = :run,
)
    isempty(solutions) && return NaN
    unit = _normalize_trial_unit(trial_unit)

    total_trials = 0
    total_successes = 0

    for sol in solutions
        isempty(sol) && return NaN
        counts = _empirical_read_counts(sol, λ)
        counts.trials == 0 && return NaN

        if unit === :run
            total_trials += 1
            total_successes += counts.successes > 0 ? 1 : 0
        elseif unit === :read
            regime = _non_iid_read_regime(sol)
            if !isnothing(regime)
                throw(
                    ArgumentError(
                        "Cannot compute per-read `success_rate` (`trial_unit = :read`) on solution marked with sampling regime '$(regime)'; pass `trial_unit = :run`",
                    ),
                )
            end
            total_trials += counts.trials
            total_successes += counts.successes
        else
            throw(ArgumentError("Unsupported `trial_unit = $(repr(trial_unit))`"))
        end
    end

    return total_successes / total_trials
end

function _interior_repetitions(
    p::Float64,
    s::Float64;
    trials::Union{Int,Nothing} = nothing,
    successes::Union{Int,Nothing} = nothing,
)
    return setprecision(BigFloat, 256) do
        log_q_bf = if !isnothing(trials) && !isnothing(successes)
            failures = trials - successes
            if successes <= failures
                log1p(-(BigFloat(successes) / BigFloat(trials)))
            else
                log(BigFloat(failures) / BigFloat(trials))
            end
        else
            log1p(-BigFloat(p))
        end

        r_bf = log1p(-BigFloat(s)) / log_q_bf
        kr_bf = round(r_bf)

        if isfinite(kr_bf) &&
           kr_bf >= 1 &&
           kr_bf <= 1074 &&
           abs(r_bf - kr_bf) <= BigFloat(2)^(-200)
            ki = Int(kr_bf)
            q_rat = if !isnothing(trials) && !isnothing(successes)
                BigInt(trials - successes) // BigInt(trials)
            else
                1 - Rational{BigInt}(p)
            end
            s_comp = 1 - Rational{BigInt}(s)
            if ki > 1 && q_rat^(ki - 1) <= s_comp
                ki -= 1
            elseif q_rat^ki > s_comp
                ki += 1
            end
            if q_rat^ki == s_comp
                return (Float64(ki), Float64(ki))
            else
                return (Float64(r_bf), Float64(ki))
            end
        end

        k_bf = max(BigFloat(1), ceil(r_bf))
        return (Float64(r_bf), Float64(k_bf))
    end
end

function _build_ttt_estimate(
    trial_time::Float64,
    batch_time::Float64,
    p::Float64,
    s::Float64;
    trials::Union{Int,Nothing},
    successes::Union{Int,Nothing},
    trial_unit::Symbol,
    cost_boundary::Symbol,
    probability_source::Symbol,
    repetition_mode::Symbol,
)
    has_counts = !isnothing(trials) && !isnothing(successes)
    is_zero_prob = has_counts ? iszero(successes) : iszero(p)
    is_unit_prob = has_counts ? (successes == trials) : isone(p)

    if is_zero_prob
        status =
            probability_source === :known ? :known_zero_probability :
            :empirical_zero_successes
        return TimeToTargetEstimate(
            Inf,
            Inf,
            Inf,
            Inf,
            Inf,
            Inf,
            trial_time,
            batch_time,
            s,
            0.0,
            trials,
            successes,
            trial_unit,
            cost_boundary,
            probability_source,
            repetition_mode,
            status,
        )
    elseif is_unit_prob
        status =
            probability_source === :known ? :known_unit_probability :
            :empirical_all_succeeded
        continuous_reps = 0.0
        operational_reps = 1.0
        continuous_ttt = 0.0
        operational_ttt = trial_time
        reps = repetition_mode === :continuous ? continuous_reps : operational_reps
        ttt_val = repetition_mode === :continuous ? continuous_ttt : operational_ttt

        return TimeToTargetEstimate(
            ttt_val,
            operational_ttt,
            continuous_ttt,
            reps,
            operational_reps,
            continuous_reps,
            trial_time,
            batch_time,
            s,
            1.0,
            trials,
            successes,
            trial_unit,
            cost_boundary,
            probability_source,
            repetition_mode,
            status,
        )
    else
        status =
            probability_source === :known ? :known_interior_probability :
            :empirical_interior_probability
        continuous_reps, operational_reps =
            _interior_repetitions(p, s; trials = trials, successes = successes)
        continuous_ttt = trial_time * continuous_reps
        operational_ttt = trial_time * operational_reps

        reps = if repetition_mode === :integer
            operational_reps
        elseif repetition_mode === :continuous_floor_one
            max(1.0, continuous_reps)
        else
            continuous_reps
        end
        ttt_val = trial_time * reps

        return TimeToTargetEstimate(
            ttt_val,
            operational_ttt,
            continuous_ttt,
            reps,
            operational_reps,
            continuous_reps,
            trial_time,
            batch_time,
            s,
            p,
            trials,
            successes,
            trial_unit,
            cost_boundary,
            probability_source,
            repetition_mode,
            status,
        )
    end
end

function time_to_target_estimate(
    trial_time::Real,
    p::Real,
    s::Real = 0.99;
    cost_boundary::Union{Symbol,AbstractString} = :unspecified,
    repetition_mode::Union{Symbol,AbstractString} = :integer,
    trial_unit::Union{Symbol,AbstractString} = :trial,
)
    t_val = _validate_positive_duration(trial_time, "trial_time")
    p_val = _validate_trial_probability(p)
    s_val = _validate_target_probability(s)
    boundary = _normalize_cost_boundary(cost_boundary)
    rep_mode = _normalize_repetition_mode(repetition_mode)
    unit = _normalize_trial_unit(trial_unit)

    return _build_ttt_estimate(
        t_val,
        t_val,
        p_val,
        s_val;
        trials = nothing,
        successes = nothing,
        trial_unit = unit,
        cost_boundary = boundary,
        probability_source = :known,
        repetition_mode = rep_mode,
    )
end

function time_to_target_estimate(
    trial_time::Real;
    successes::Integer,
    trials::Integer,
    s::Real = 0.99,
    cost_boundary::Union{Symbol,AbstractString} = :unspecified,
    repetition_mode::Union{Symbol,AbstractString} = :integer,
    trial_unit::Union{Symbol,AbstractString} = :trial,
    batch_time::Union{Real,Nothing} = nothing,
)
    t_val = _validate_positive_duration(trial_time, "trial_time")
    trials >= 1 || throw(ArgumentError("`trials` must be at least 1; got $(trials)"))
    (0 <= successes <= trials) || throw(
        ArgumentError(
            "`successes` must satisfy `0 <= successes <= trials`; got successes=$(successes), trials=$(trials)",
        ),
    )
    s_val = _validate_target_probability(s)
    boundary = _normalize_cost_boundary(cost_boundary)
    rep_mode = _normalize_repetition_mode(repetition_mode)
    unit = _normalize_trial_unit(trial_unit)
    b_val =
        isnothing(batch_time) ? t_val * Int(trials) :
        _validate_positive_duration(batch_time, "batch_time")
    p_val = Int(successes) / Int(trials)

    return _build_ttt_estimate(
        t_val,
        b_val,
        p_val,
        s_val;
        trials = Int(trials),
        successes = Int(successes),
        trial_unit = unit,
        cost_boundary = boundary,
        probability_source = :empirical,
        repetition_mode = rep_mode,
    )
end

function time_to_target_estimate(
    solution::AbstractSolution,
    λ::Real,
    s::Real = 0.99;
    trial_unit::Union{Symbol,AbstractString,Nothing} = nothing,
    cost_boundary::Union{Symbol,AbstractString} = :effective,
    trial_time::Union{Real,Nothing} = nothing,
    batch_time::Union{Real,Nothing} = nothing,
    repetition_mode::Union{Symbol,AbstractString} = :integer,
)
    unit = _resolve_trial_unit(solution, trial_unit)
    boundary = _normalize_cost_boundary(cost_boundary)
    rep_mode = _normalize_repetition_mode(repetition_mode)
    s_val = _validate_target_probability(s)
    counts = _empirical_trial_counts(solution, λ, unit)

    t_val, b_val = if !isnothing(trial_time)
        t_checked = _validate_positive_duration(trial_time, "trial_time")
        b_checked =
            isnothing(batch_time) ? t_checked * counts.trials :
            _validate_positive_duration(batch_time, "batch_time")
        (t_checked, b_checked)
    else
        b_checked = _extract_boundary_batch_time(solution, boundary; batch_time)
        (b_checked / counts.trials, b_checked)
    end

    p_val = counts.successes / counts.trials

    return _build_ttt_estimate(
        t_val,
        b_val,
        p_val,
        s_val;
        trials = counts.trials,
        successes = counts.successes,
        trial_unit = unit,
        cost_boundary = boundary,
        probability_source = :empirical,
        repetition_mode = rep_mode,
    )
end

function time_to_target_estimate(
    solutions::AbstractVector{<:AbstractSolution},
    λ::Real,
    s::Real = 0.99;
    trial_unit::Union{Symbol,AbstractString} = :run,
    cost_boundary::Union{Symbol,AbstractString} = :effective,
    trial_time::Union{Real,Nothing} = nothing,
    batch_time::Union{Real,Nothing} = nothing,
    repetition_mode::Union{Symbol,AbstractString} = :integer,
)
    isempty(solutions) && throw(
        ArgumentError("Cannot estimate time-to-target from an empty vector of solutions"),
    )
    unit = _normalize_trial_unit(trial_unit)
    boundary = _normalize_cost_boundary(cost_boundary)
    rep_mode = _normalize_repetition_mode(repetition_mode)
    s_val = _validate_target_probability(s)

    total_trials = 0
    total_successes = 0

    for sol in solutions
        counts = _empirical_trial_counts(sol, λ, unit)
        total_trials += counts.trials
        total_successes += counts.successes
    end

    t_val, b_val = if !isnothing(trial_time)
        t_checked = _validate_positive_duration(trial_time, "trial_time")
        b_checked =
            isnothing(batch_time) ? t_checked * total_trials :
            _validate_positive_duration(batch_time, "batch_time")
        (t_checked, b_checked)
    elseif !isnothing(batch_time)
        b_checked = _validate_positive_duration(batch_time, "batch_time")
        (b_checked / total_trials, b_checked)
    else
        b_sum = sum(sol -> _extract_boundary_batch_time(sol, boundary), solutions)
        (b_sum / total_trials, b_sum)
    end

    p_val = total_successes / total_trials

    return _build_ttt_estimate(
        t_val,
        b_val,
        p_val,
        s_val;
        trials = total_trials,
        successes = total_successes,
        trial_unit = unit,
        cost_boundary = boundary,
        probability_source = :empirical,
        repetition_mode = rep_mode,
    )
end

function time_to_target_estimate(
    model::AbstractModel,
    λ::Real,
    s::Real = 0.99;
    kws...,
)
    return time_to_target_estimate(solution(model), λ, s; kws...)
end

function time_to_target(
    solution::AbstractSolution{T,U},
    λ::Real,
    s::Real = 0.99;
    trial_unit::Union{Symbol,AbstractString,Nothing} = nothing,
    cost_boundary::Union{Symbol,AbstractString} = :effective,
    trial_time::Union{Real,Nothing} = nothing,
    batch_time::Union{Real,Nothing} = nothing,
    repetition_mode::Union{Symbol,AbstractString} = :continuous_floor_one,
) where {T,U}
    s_val = _validate_target_probability(s)
    data = metadata(solution)
    data isa AbstractDict ||
        throw(ArgumentError("Solution metadata must be a dictionary"))

    has_explicit_semantics =
        !isnothing(trial_unit) ||
        (haskey(data, "trial_unit") && !isnothing(data["trial_unit"])) ||
        !isnothing(trial_time) ||
        !isnothing(batch_time) ||
        _normalize_cost_boundary(cost_boundary) !== :effective

    if has_explicit_semantics
        return time_to_target_estimate(
            solution,
            λ,
            s_val;
            trial_unit,
            cost_boundary,
            trial_time,
            batch_time,
            repetition_mode,
        ).ttt
    end

    regime = _non_iid_read_regime(solution)
    if !isnothing(regime)
        throw(
            ArgumentError(
                "Cannot infer IID read semantics for solution marked with sampling regime '$(regime)'; pass `trial_unit = :run` explicitly",
            ),
        )
    end

    Base.depwarn(
        "`time_to_target(solution, λ, s)` without `trial_unit` mixes batch timing with per-read success rate and is deprecated; pass `trial_unit = :read` or `trial_unit = :run`, or use `time_to_target_estimate`.",
        :time_to_target,
    )

    if isempty(solution)
        return NaN
    end

    t = effective_time(solution)
    p = success_rate(solution, λ; trial_unit = :read)

    if isnan(t) || isnan(p)
        return NaN
    end

    return time_to_target(t, p, s_val; repetition_mode)
end

function time_to_target(
    solutions::AbstractVector{<:AbstractSolution},
    λ::Real,
    s::Real = 0.99;
    trial_unit::Union{Symbol,AbstractString} = :run,
    cost_boundary::Union{Symbol,AbstractString} = :effective,
    trial_time::Union{Real,Nothing} = nothing,
    batch_time::Union{Real,Nothing} = nothing,
    repetition_mode::Union{Symbol,AbstractString} = :continuous_floor_one,
)
    return time_to_target_estimate(
        solutions,
        λ,
        s;
        trial_unit,
        cost_boundary,
        trial_time,
        batch_time,
        repetition_mode,
    ).ttt
end

function time_to_target(
    t::Real,
    p::Real,
    s::Real = 0.99;
    repetition_mode::Union{Symbol,AbstractString} = :continuous_floor_one,
)
    return time_to_target_estimate(t, p, s; repetition_mode).ttt
end

function hamming_distance(ψ::State{U}, φ::State{U}) where {U}
    @assert length(ψ) == length(φ)

    d = 0

    for i in eachindex(ψ)
        if ψ[i] != φ[i]
            d += 1
        end
    end

    return d
end
