const _REPORT_FORMAT = "QUBOTools.report"
const _REPORT_VERSION = 1

_json_finite(::Nothing) = nothing
_json_finite(x::Bool) = x
_json_finite(x::Integer) = Int(x)
_json_finite(x::Real) = isfinite(x) ? Float64(x) : nothing

function _json_sanitize(x::Nothing)
    return nothing
end

function _json_sanitize(x::Bool)
    return x
end

function _json_sanitize(x::Integer)
    return x
end

function _json_sanitize(x::Real)
    return _json_finite(x)
end

function _json_sanitize(x::Union{Symbol,AbstractString})
    return String(x)
end

function _json_sanitize(x::Union{VersionNumber,Type})
    return string(x)
end

function _json_sanitize(x::Union{Sense,Domain})
    return String(x)
end

function _json_sanitize(x::AbstractDict)
    return Dict{String,Any}(string(k) => _json_sanitize(v) for (k, v) in x)
end

function _json_sanitize(x::Union{AbstractVector,Tuple,AbstractSet})
    return Any[_json_sanitize(v) for v in x]
end

function _json_sanitize(x::NamedTuple)
    return Dict{String,Any}(String(k) => _json_sanitize(getproperty(x, k)) for k in keys(x))
end

function _json_sanitize(bd::ObjectiveBreakdown)
    return _serialize_objective_breakdown(bd)
end

function _json_sanitize(mismatch::ObjectiveMismatch)
    return _serialize_objective_mismatch(mismatch)
end

function _json_sanitize(est::TimeToTargetEstimate)
    return _serialize_ttt_estimate(est)
end

function _json_sanitize(x)
    T = typeof(x)
    if isstructtype(T) && fieldcount(T) > 0
        return Dict{String,Any}(
            String(fname) => _json_sanitize(getfield(x, fname)) for fname in fieldnames(T)
        )
    end
    return string(x)
end

function _serialize_objective_breakdown(bd::ObjectiveBreakdown)
    return Dict{String,Any}(
        "state" => collect(Int, bd.state),
        "raw_value" => _json_finite(bd.raw_value),
        "scaled_value" => _json_finite(bd.scaled_value),
        "offset_adjusted_value" => _json_finite(bd.offset_adjusted_value),
        "scale" => _json_finite(bd.scale),
        "offset" => _json_finite(bd.offset),
        "sense" => String(bd.sense),
        "domain" => String(bd.domain),
    )
end

function _serialize_objective_mismatch(mismatch::ObjectiveMismatch)
    return Dict{String,Any}(
        "index" => mismatch.index,
        "state" => collect(Int, mismatch.state),
        "stored_value" => _json_finite(mismatch.stored_value),
        "evaluated_value" => _json_finite(mismatch.evaluated_value),
        "difference" => _json_finite(mismatch.difference),
    )
end

function _serialize_ttt_estimate(est::TimeToTargetEstimate)
    return Dict{String,Any}(
        "ttt" => _json_finite(est.ttt),
        "operational_ttt" => _json_finite(est.operational_ttt),
        "continuous_ttt" => _json_finite(est.continuous_ttt),
        "repetitions" => _json_finite(est.repetitions),
        "operational_repetitions" => _json_finite(est.operational_repetitions),
        "continuous_repetitions" => _json_finite(est.continuous_repetitions),
        "trial_time" => _json_finite(est.trial_time),
        "batch_time" => _json_finite(est.batch_time),
        "target_probability" => _json_finite(est.target_probability),
        "success_probability" => _json_finite(est.success_probability),
        "trials" => est.trials,
        "successes" => est.successes,
        "trial_unit" => String(est.trial_unit),
        "cost_boundary" => String(est.cost_boundary),
        "probability_source" => String(est.probability_source),
        "repetition_mode" => String(est.repetition_mode),
        "status" => String(est.status),
    )
end

function _coefficient_stats(values::AbstractVector{<:Real})
    if isempty(values)
        return Dict{String,Any}(
            "count" => 0,
            "min" => nothing,
            "max" => nothing,
            "min_abs" => nothing,
            "max_abs" => nothing,
            "mean" => nothing,
            "mean_abs" => nothing,
            "std" => nothing,
            "dynamic_range" => nothing,
        )
    end

    fvals = Float64[Float64(v) for v in values]
    abs_vals = abs.(fvals)
    min_abs = minimum(abs_vals)
    max_abs = maximum(abs_vals)
    dyn_range = min_abs > 0.0 ? _json_finite(max_abs / min_abs) : nothing

    return Dict{String,Any}(
        "count" => length(fvals),
        "min" => _json_finite(minimum(fvals)),
        "max" => _json_finite(maximum(fvals)),
        "min_abs" => _json_finite(min_abs),
        "max_abs" => _json_finite(max_abs),
        "mean" => _json_finite(mean(fvals)),
        "mean_abs" => _json_finite(mean(abs_vals)),
        "std" => length(fvals) >= 2 ? _json_finite(std(fvals)) : nothing,
        "dynamic_range" => dyn_range,
    )
end

function _report_model_section(model::AbstractModel)
    lin_vals = Float64[Float64(v) for (_, v) in linear_terms(model) if !iszero(v)]
    quad_vals = Float64[Float64(v) for (_, v) in quadratic_terms(model) if !iszero(v)]
    all_vals = vcat(lin_vals, quad_vals)

    ls = linear_size(model)
    qs = quadratic_size(model)

    return Dict{String,Any}(
        "dimension" => dimension(model),
        "variables" => string.(variables(model)),
        "sense" => String(sense(model)),
        "domain" => String(domain(model)),
        "scale" => _json_finite(scale(model)),
        "offset" => _json_finite(offset(model)),
        "linear_size" => ls,
        "quadratic_size" => qs,
        "term_count" => ls + qs,
        "density" => Dict{String,Any}(
            "total" => _json_finite(density(model)),
            "linear" => _json_finite(linear_density(model)),
            "quadratic" => _json_finite(quadratic_density(model)),
        ),
        "coefficients" => Dict{String,Any}(
            "linear" => _coefficient_stats(lin_vals),
            "quadratic" => _coefficient_stats(quad_vals),
            "all" => _coefficient_stats(all_vals),
        ),
        "metadata" => _json_sanitize(metadata(model)),
    )
end

function _has_boundary_time(sol::AbstractSolution, boundary::Symbol)
    data = metadata(sol)
    data isa AbstractDict || return false
    haskey(data, "time") || return false
    time_data = data["time"]
    time_data isa AbstractDict || return false

    key = if boundary === :effective
        "effective"
    elseif boundary === :total
        "total"
    elseif boundary === :complete
        "complete"
    else
        return false
    end

    return haskey(time_data, key) && !isnothing(time_data[key])
end

function _report_energies(sol::AbstractSolution)
    isempty(sol) && return nothing

    vals = Float64[Float64(value(s)) for s in sol]
    mults = Int[reads(s) for s in sol]
    tot_reads = sum(mults)

    weighted_mean = if tot_reads > 0
        sum(v * r for (v, r) in zip(vals, mults)) / tot_reads
    else
        mean(vals)
    end

    return Dict{String,Any}(
        "best" => _json_finite(first(vals)),
        "min" => _json_finite(minimum(vals)),
        "max" => _json_finite(maximum(vals)),
        "mean" => _json_finite(weighted_mean),
    )
end

function _report_best_sample(
    model::AbstractModel,
    sol::AbstractSolution;
    bit_order::Symbol,
)
    isempty(sol) && return nothing

    best = first(sol)
    bd = _objective_breakdown(model, sol, best)

    return Dict{String,Any}(
        "state" => collect(Int, state(best)),
        "state_string" => _samples_state_string(best, domain(sol); bit_order),
        "value" => _json_finite(value(best)),
        "reads" => reads(best),
        "probability" => _json_finite(_samples_probability(reads(best), reads(sol))),
        "objective_breakdown" => _serialize_objective_breakdown(bd),
    )
end

function _report_solution_metrics(
    sol::AbstractSolution,
    λ::Union{Real,Nothing},
    s::Real;
    trial_unit::Union{Symbol,AbstractString,Nothing},
    cost_boundary::Union{Symbol,AbstractString},
    trial_time::Union{Real,Nothing},
    batch_time::Union{Real,Nothing},
    repetition_mode::Union{Symbol,AbstractString},
)
    s_val = _validate_target_probability(s)
    boundary = _normalize_cost_boundary(cost_boundary)
    rep_mode = _normalize_repetition_mode(repetition_mode)

    if !isnothing(trial_unit)
        _normalize_trial_unit(trial_unit)
    end
    if !isnothing(trial_time)
        _validate_positive_duration(trial_time, "trial_time")
    end
    if !isnothing(batch_time)
        _validate_positive_duration(batch_time, "batch_time")
    end

    if isnothing(λ) || isempty(sol)
        return Dict{String,Any}(
            "target_threshold" => isnothing(λ) ? nothing : _json_finite(Float64(λ)),
            "target_probability" => _json_finite(s_val),
            "trial_unit" => isnothing(trial_unit) ? nothing : String(_normalize_trial_unit(trial_unit)),
            "cost_boundary" => String(boundary),
            "success_rate" => nothing,
            "ttt" => nothing,
            "time_to_target" => nothing,
            "status" => isempty(sol) ? "empty_solution" : "threshold_not_provided",
        )
    end

    λ_val = Float64(λ)
    isfinite(λ_val) || throw(ArgumentError("Target threshold `λ` must be finite; got $(λ)"))

    data = metadata(sol)
    has_declared_unit =
        !isnothing(trial_unit) ||
        (data isa AbstractDict && haskey(data, "trial_unit") && !isnothing(data["trial_unit"]))

    if !has_declared_unit
        if !isnothing(trial_time) || !isnothing(batch_time) || boundary !== :effective
            time_to_target_estimate(
                sol,
                λ_val,
                s_val;
                trial_unit,
                cost_boundary = boundary,
                trial_time,
                batch_time,
                repetition_mode = rep_mode,
            )
        end

        run_sr = success_rate(sol, λ_val; trial_unit = :run)
        read_sr =
            isnothing(_non_iid_read_regime(sol)) ?
            success_rate(sol, λ_val; trial_unit = :read) : nothing

        return Dict{String,Any}(
            "target_threshold" => _json_finite(λ_val),
            "target_probability" => _json_finite(s_val),
            "trial_unit" => nothing,
            "cost_boundary" => String(boundary),
            "success_rate" => nothing,
            "read_success_rate" => _json_finite(read_sr),
            "run_success_rate" => _json_finite(run_sr),
            "ttt" => nothing,
            "time_to_target" => nothing,
            "status" => "trial_unit_required",
        )
    end

    unit = _resolve_trial_unit(sol, trial_unit)
    counts = _empirical_trial_counts(sol, λ_val, unit)
    sr = counts.successes / counts.trials

    has_timing =
        !isnothing(trial_time) ||
        !isnothing(batch_time) ||
        _has_boundary_time(sol, boundary)

    if !has_timing && boundary === :effective
        return Dict{String,Any}(
            "target_threshold" => _json_finite(λ_val),
            "target_probability" => _json_finite(s_val),
            "trial_unit" => String(unit),
            "cost_boundary" => String(boundary),
            "trials" => counts.trials,
            "successes" => counts.successes,
            "success_rate" => _json_finite(sr),
            "ttt" => nothing,
            "time_to_target" => nothing,
            "status" => "missing_timing_metadata",
        )
    end

    est = time_to_target_estimate(
        sol,
        λ_val,
        s_val;
        trial_unit = unit,
        cost_boundary = boundary,
        trial_time,
        batch_time,
        repetition_mode = rep_mode,
    )

    return Dict{String,Any}(
        "target_threshold" => _json_finite(λ_val),
        "target_probability" => _json_finite(s_val),
        "trial_unit" => String(unit),
        "cost_boundary" => String(boundary),
        "trials" => counts.trials,
        "successes" => counts.successes,
        "success_rate" => _json_finite(sr),
        "ttt" => _json_finite(est.ttt),
        "time_to_target" => _serialize_ttt_estimate(est),
        "status" => String(est.status),
    )
end

function _report_solution_section(
    model::AbstractModel,
    sol::Union{AbstractSolution,Nothing};
    λ::Union{Real,Nothing},
    s::Real,
    trial_unit::Union{Symbol,AbstractString,Nothing},
    cost_boundary::Union{Symbol,AbstractString},
    trial_time::Union{Real,Nothing},
    batch_time::Union{Real,Nothing},
    repetition_mode::Union{Symbol,AbstractString},
    include_samples::Bool,
    bit_order::Symbol,
    include_probability::Bool,
)
    if isnothing(sol)
        _validate_target_probability(s)
        _normalize_cost_boundary(cost_boundary)
        _normalize_repetition_mode(repetition_mode)
        if !isnothing(trial_unit)
            _normalize_trial_unit(trial_unit)
        end
        if !isnothing(trial_time)
            _validate_positive_duration(trial_time, "trial_time")
        end
        if !isnothing(batch_time)
            _validate_positive_duration(batch_time, "batch_time")
        end

        return Dict{String,Any}(
            "present" => false,
            "sample_count" => 0,
            "total_reads" => 0,
            "sense" => String(sense(model)),
            "domain" => String(domain(model)),
            "metadata" => Dict{String,Any}(),
            "samples_metadata" => nothing,
            "timing" => Dict{String,Any}(
                "effective_time" => nothing,
                "total_time" => nothing,
            ),
            "energies" => nothing,
            "best_sample" => nothing,
            "objective_values_verified" => true,
            "objective_mismatch_count" => 0,
            "metrics" => Dict{String,Any}(
                "target_threshold" => isnothing(λ) ? nothing : _json_finite(Float64(λ)),
                "target_probability" => _json_finite(Float64(s)),
                "trial_unit" => isnothing(trial_unit) ? nothing : String(_normalize_trial_unit(trial_unit)),
                "cost_boundary" => String(_normalize_cost_boundary(cost_boundary)),
                "success_rate" => nothing,
                "ttt" => nothing,
                "time_to_target" => nothing,
                "status" => "empty_solution",
            ),
            "samples" => include_samples ? Any[] : nothing,
        )
    end

    sol_meta = metadata(sol)
    sol_meta isa AbstractDict ||
        throw(ArgumentError("Solution metadata must be a dictionary"))

    t_eff = _json_finite(effective_time(sol))
    t_tot = _json_finite(total_time(sol))

    columns = _samples_columns(; include_probability)
    samples_meta = _json_sanitize(
        _samples_file_metadata(sol; columns, bit_order, model),
    )

    best_sample_dict = _report_best_sample(model, sol; bit_order)
    mismatches = isempty(sol) ? ObjectiveMismatch[] : objective_value_mismatches(model, sol)

    metrics_dict = _report_solution_metrics(
        sol,
        λ,
        s;
        trial_unit,
        cost_boundary,
        trial_time,
        batch_time,
        repetition_mode,
    )

    samples_list = if include_samples
        table_rows = sampleset_table(sol; bit_order, include_probability)
        [
            begin
                row_dict = _json_sanitize(row)
                sample_i = sol[row.rank]
                row_dict["objective_breakdown"] = _serialize_objective_breakdown(
                    _objective_breakdown(model, sol, sample_i),
                )
                row_dict
            end for row in table_rows
        ]
    else
        nothing
    end

    return Dict{String,Any}(
        "present" => !isempty(sol) || !isempty(sol_meta),
        "sample_count" => length(sol),
        "total_reads" => isempty(sol) ? 0 : reads(sol),
        "sense" => String(sense(sol)),
        "domain" => String(domain(sol)),
        "metadata" => _json_sanitize(sol_meta),
        "samples_metadata" => samples_meta,
        "timing" => Dict{String,Any}(
            "effective_time" => t_eff,
            "total_time" => t_tot,
        ),
        "energies" => _report_energies(sol),
        "best_sample" => best_sample_dict,
        "objective_values_verified" => isempty(mismatches),
        "objective_mismatch_count" => length(mismatches),
        "metrics" => metrics_dict,
        "samples" => samples_list,
    )
end

function _discover_reformulation_metadata(
    model::AbstractModel,
    reformulation::Union{AbstractDict,Nothing},
)
    if !isnothing(reformulation)
        return _json_sanitize(reformulation)
    end

    model_meta = metadata(model)
    if model_meta isa AbstractDict && haskey(model_meta, "toqubo")
        toqubo_meta = model_meta["toqubo"]
        if toqubo_meta isa AbstractDict &&
           haskey(toqubo_meta, "reformulation") &&
           toqubo_meta["reformulation"] isa AbstractDict
            return _json_sanitize(toqubo_meta["reformulation"])
        end
    end

    return nothing
end

function _discover_penalties_metadata(
    model::AbstractModel,
    penalties::Union{AbstractDict,Nothing},
    reformulation_dict::Union{Dict{String,Any},Nothing},
)
    if !isnothing(penalties)
        return _json_sanitize(penalties)
    end

    if !isnothing(reformulation_dict)
        if haskey(reformulation_dict, "applied_penalties") &&
           reformulation_dict["applied_penalties"] isa AbstractDict
            pen_dict = deepcopy(_json_sanitize(reformulation_dict["applied_penalties"]))
            if haskey(reformulation_dict, "penalty_policy") &&
               !haskey(pen_dict, "penalty_policy")
                pen_dict["penalty_policy"] = _json_sanitize(reformulation_dict["penalty_policy"])
            end
            return pen_dict
        end
    end

    model_meta = metadata(model)
    if model_meta isa AbstractDict &&
       haskey(model_meta, "penalties") &&
       model_meta["penalties"] isa AbstractDict
        return _json_sanitize(model_meta["penalties"])
    end

    return nothing
end

function report(
    model::AbstractModel;
    solution::Union{AbstractSolution,Nothing} = QUBOTools.solution(model),
    λ::Union{Real,Nothing} = nothing,
    s::Real = 0.99,
    trial_unit::Union{Symbol,AbstractString,Nothing} = nothing,
    cost_boundary::Union{Symbol,AbstractString} = :effective,
    trial_time::Union{Real,Nothing} = nothing,
    batch_time::Union{Real,Nothing} = nothing,
    repetition_mode::Union{Symbol,AbstractString} = :integer,
    penalties::Union{AbstractDict,Nothing} = nothing,
    reformulation::Union{AbstractDict,Nothing} = nothing,
    feasibility::Any = nothing,
    include_samples::Bool = false,
    bit_order::Union{Symbol,AbstractString} = :native,
    include_probability::Bool = true,
)
    norm_bit_order = _samples_bit_order(bit_order)
    reformulation_dict = _discover_reformulation_metadata(model, reformulation)
    penalties_dict = _discover_penalties_metadata(model, penalties, reformulation_dict)
    feasibility_dict = isnothing(feasibility) ? nothing : _json_sanitize(feasibility)

    return Dict{String,Any}(
        "format" => _REPORT_FORMAT,
        "version" => _REPORT_VERSION,
        "package_versions" => Dict{String,Any}(
            "QUBOTools" => string(__version__()),
            "Julia" => string(VERSION),
        ),
        "model" => _report_model_section(model),
        "solution" => _report_solution_section(
            model,
            solution;
            λ,
            s,
            trial_unit,
            cost_boundary,
            trial_time,
            batch_time,
            repetition_mode,
            include_samples,
            bit_order = norm_bit_order,
            include_probability,
        ),
        "penalties" => penalties_dict,
        "reformulation" => reformulation_dict,
        "feasibility" => feasibility_dict,
    )
end

function write_report(
    io::IO,
    model::AbstractModel;
    indent::Integer = 2,
    kws...,
)
    indent >= 0 || throw(ArgumentError("`indent` must be non-negative; got $(indent)"))
    data = report(model; kws...)
    if indent == 0
        JSON.print(io, data)
    else
        JSON.print(io, data, Int(indent))
    end
    println(io)
    return nothing
end

function write_report(
    path::AbstractString,
    model::AbstractModel;
    indent::Integer = 2,
    kws...,
)
    indent >= 0 || throw(ArgumentError("`indent` must be non-negative; got $(indent)"))
    data = report(model; kws...)
    open(path, "w") do io
        if indent == 0
            JSON.print(io, data)
        else
            JSON.print(io, data, Int(indent))
        end
        println(io)
    end
    return path
end

