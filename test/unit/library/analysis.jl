function test_metrics()
    @testset "→ Metrics" verbose = true begin
        test_solution_metrics()
        test_model_metrics()
    end

    return nothing
end

function test_solution_metrics()
    @testset "⋅ Solution" begin
        @testset "Time-to-Target ⋄ Min" begin
            let λ = 1.0,
                sol = QUBOTools.SampleSet(
                    QUBOTools.Sample{Float64,Int}[
                        QUBOTools.Sample([0, 0, 1], 1.0, 1),
                        QUBOTools.Sample([0, 1, 0], 2.0, 2),
                        QUBOTools.Sample([0, 1, 1], 3.0, 3),
                        QUBOTools.Sample([1, 0, 0], 4.0, 4),
                    ];
                    metadata = Dict{String,Any}(
                        "time" => Dict{String,Any}("total" => 2.0, "effective" => 1.0),
                    ),
                    sense  = :min,
                    domain = :bool,
                )

                @test QUBOTools.total_time(sol) == 2.0
                @test QUBOTools.effective_time(sol) == 1.0

                @test QUBOTools.success_rate(sol, λ) ≈ 0.1 atol = 1e-8
                @test QUBOTools.success_rate(sol, λ; trial_unit = :run) == 1.0

                # Declared independent-read batch: 10 reads costing 1.0s => 0.1s per trial
                read_est = QUBOTools.time_to_target_estimate(sol, λ; trial_unit = :read)
                @test read_est.trial_unit === :read
                @test read_est.cost_boundary === :effective
                @test read_est.probability_source === :empirical
                @test read_est.status === :empirical_interior_probability
                @test read_est.trials == 10
                @test read_est.successes == 1
                @test read_est.batch_time == 1.0
                @test read_est.trial_time ≈ 0.1 atol = 1e-12
                @test read_est.success_probability ≈ 0.1 atol = 1e-12
                @test read_est.continuous_repetitions ≈ 43.70869065356663 atol = 1e-8
                @test read_est.continuous_ttt ≈ 4.370869065356663 atol = 1e-8
                @test read_est.operational_repetitions == 44.0
                @test read_est.operational_ttt ≈ 4.4 atol = 1e-12
                @test QUBOTools.ttt(sol, λ; trial_unit = :read) ≈ 4.370869065356663 atol = 1e-8
                @test QUBOTools.ttt(
                    sol,
                    λ;
                    trial_unit = :read,
                    repetition_mode = :integer,
                ) ≈ 4.4 atol = 1e-12

                # Declared independent 1s run: uses 1.0s per trial and run-level attainment
                run_est = QUBOTools.time_to_target_estimate(sol, λ; trial_unit = :run)
                @test run_est.trial_unit === :run
                @test run_est.trials == 1
                @test run_est.successes == 1
                @test run_est.trial_time == 1.0
                @test run_est.batch_time == 1.0
                @test run_est.status === :empirical_all_succeeded
                @test run_est.operational_ttt == 1.0
                @test QUBOTools.ttt(sol, λ; trial_unit = :run) == 1.0

                # Ambiguous batch data require explicit trial semantics in time_to_target_estimate
                @test_throws ArgumentError QUBOTools.time_to_target_estimate(sol, λ)

                # Legacy positional call without trial_unit emits deprecation warning
                @test (@test_deprecated QUBOTools.ttt(sol, λ)) ≈ 43.708690653 atol = 1e-8
            end

            let λ = 0.0, sol = QUBOTools.SampleSet()
                @test isnan(QUBOTools.total_time(sol))
                @test isnan(QUBOTools.effective_time(sol))
                @test isnan(QUBOTools.success_rate(sol, λ))
                @test isnan(@test_deprecated QUBOTools.ttt(sol, λ))
                @test_throws ArgumentError QUBOTools.time_to_target_estimate(
                    sol,
                    λ;
                    trial_unit = :read,
                )
            end

            let λ = 0.0,
                sol = QUBOTools.SampleSet(
                    QUBOTools.Sample{Float64,Int}[];
                    metadata = Dict{String,Any}("time" => Dict{String,Any}()),
                )

                @test isnan(QUBOTools.total_time(sol))
                @test isnan(QUBOTools.effective_time(sol))
                @test isnan(QUBOTools.success_rate(sol, λ))
                @test isnan(@test_deprecated QUBOTools.ttt(sol, λ))
            end

            let λ = 0.0,
                sol = QUBOTools.SampleSet(
                    QUBOTools.Sample{Float64,Int}[];
                    metadata = Dict{String,Any}("time" => Dict{String,Any}("total" => 1.0)),
                )

                @test QUBOTools.total_time(sol) == 1.0
                @test QUBOTools.effective_time(sol) == 1.0
                @test isnan(QUBOTools.success_rate(sol, λ))
                @test isnan(@test_deprecated QUBOTools.ttt(sol, λ))
            end
        end

        @testset "Time-to-Target ⋄ Max" begin
            let λ = 4.0,
                sol = QUBOTools.SampleSet(
                    QUBOTools.Sample{Float64,Int}[
                        QUBOTools.Sample([0, 0, 1], 1.0, 1),
                        QUBOTools.Sample([0, 1, 0], 2.0, 2),
                        QUBOTools.Sample([0, 1, 1], 3.0, 3),
                        QUBOTools.Sample([1, 0, 0], 4.0, 4),
                    ];
                    metadata = Dict{String,Any}(
                        "time" => Dict{String,Any}("total" => 2.0, "effective" => 1.0),
                    ),
                    sense  = :max,
                    domain = :bool,
                )

                @test QUBOTools.total_time(sol) == 2.0
                @test QUBOTools.effective_time(sol) == 1.0

                @test QUBOTools.success_rate(sol, λ) ≈ 0.4 atol = 1e-8
                @test QUBOTools.ttt(sol, λ; trial_unit = :read) ≈ 0.9015151103887694 atol = 1e-8
                @test (@test_deprecated QUBOTools.ttt(sol, λ)) ≈ 9.015151103887694 atol = 1e-8
            end
        end

        @testset "Endpoints, Provenance, Boundaries & Validation" begin
            # 1. Known p = 1 and p = 0 endpoints vs interior high probability
            known_one = QUBOTools.time_to_target_estimate(0.25, 1.0, 0.99)
            @test known_one.probability_source === :known
            @test known_one.status === :known_unit_probability
            @test isnothing(known_one.trials)
            @test isnothing(known_one.successes)
            @test known_one.operational_repetitions == 1.0
            @test known_one.operational_ttt == 0.25
            @test known_one.continuous_repetitions == 0.0
            @test known_one.continuous_ttt == 0.0
            @test known_one.ttt == 0.25
            @test QUBOTools.time_to_target(0.25, 1.0, 0.99) == 0.25
            @test QUBOTools.time_to_target(0.25, 1.0, 0.99; repetition_mode = :continuous) == 0.0

            known_zero = QUBOTools.time_to_target_estimate(0.25, 0.0, 0.99)
            @test known_zero.probability_source === :known
            @test known_zero.status === :known_zero_probability
            @test isinf(known_zero.ttt)
            @test isinf(known_zero.operational_ttt)
            @test isinf(known_zero.continuous_ttt)
            @test isinf(QUBOTools.time_to_target(0.25, 0.0, 0.99))

            # High interior p > s still charges 1 trial operationally
            known_high = QUBOTools.time_to_target_estimate(0.25, 0.995, 0.99)
            @test known_high.status === :known_interior_probability
            @test known_high.operational_repetitions == 1.0
            @test known_high.operational_ttt == 0.25
            @test 0.0 < known_high.continuous_repetitions < 1.0
            @test QUBOTools.time_to_target(0.25, 0.995, 0.99) == 0.25

            # 2. Empirical all-success (N/N) and all-failure (0/N) retain finite counts
            emp_Sol = QUBOTools.SampleSet(
                [
                    QUBOTools.Sample([0, 1], 1.0, 4),
                    QUBOTools.Sample([1, 0], 2.0, 6),
                ];
                metadata = Dict{String,Any}(
                    "time" => Dict{String,Any}("effective" => 2.0, "total" => 3.0),
                ),
                sense = :min,
                domain = :bool,
            )

            all_succ = QUBOTools.time_to_target_estimate(emp_Sol, 5.0; trial_unit = :read)
            @test all_succ.probability_source === :empirical
            @test all_succ.status === :empirical_all_succeeded
            @test all_succ.trials == 10
            @test all_succ.successes == 10
            @test all_succ.trial_time ≈ 0.2 atol = 1e-12
            @test all_succ.operational_repetitions == 1.0
            @test all_succ.operational_ttt ≈ 0.2 atol = 1e-12

            zero_succ = QUBOTools.time_to_target_estimate(emp_Sol, 0.5; trial_unit = :read)
            @test zero_succ.probability_source === :empirical
            @test zero_succ.status === :empirical_zero_successes
            @test zero_succ.trials == 10
            @test zero_succ.successes == 0
            @test isinf(zero_succ.ttt)
            @test isinf(zero_succ.operational_ttt)

            direct_emp = QUBOTools.time_to_target_estimate(0.5; successes = 0, trials = 8)
            @test direct_emp.probability_source === :empirical
            @test direct_emp.status === :empirical_zero_successes
            @test direct_emp.trials == 8
            @test direct_emp.successes == 0
            @test direct_emp.batch_time == 4.0

            # 3. Multi-run campaign vector of solutions
            run_failed = QUBOTools.SampleSet(
                [QUBOTools.Sample([1, 1], 4.0, 5)];
                metadata = Dict{String,Any}("time" => Dict{String,Any}("effective" => 1.0)),
                sense = :min,
                domain = :bool,
            )
            run_succeeded = QUBOTools.SampleSet(
                [QUBOTools.Sample([0, 1], 1.0, 5)];
                metadata = Dict{String,Any}("time" => Dict{String,Any}("effective" => 1.0)),
                sense = :min,
                domain = :bool,
            )
            campaign = vcat([run_succeeded], fill(run_failed, 9))
            @test QUBOTools.success_rate(campaign, 1.0; trial_unit = :run) ≈ 0.1 atol = 1e-12
            campaign_est = QUBOTools.time_to_target_estimate(campaign, 1.0; trial_unit = :run)
            @test campaign_est.trial_unit === :run
            @test campaign_est.trials == 10
            @test campaign_est.successes == 1
            @test campaign_est.trial_time == 1.0
            @test campaign_est.batch_time == 10.0
            @test campaign_est.operational_ttt == 44.0

            # 4. Named cost boundaries do not silently substitute for one another
            eff_est = QUBOTools.time_to_target_estimate(
                emp_Sol,
                1.0;
                trial_unit = :read,
                cost_boundary = :effective,
            )
            tot_est = QUBOTools.time_to_target_estimate(
                emp_Sol,
                1.0;
                trial_unit = :read,
                cost_boundary = :total,
            )
            comp_est = QUBOTools.time_to_target_estimate(
                emp_Sol,
                1.0;
                trial_unit = :read,
                cost_boundary = :complete,
                batch_time = 5.0,
            )
            @test eff_est.cost_boundary === :effective
            @test tot_est.cost_boundary === :total
            @test comp_est.cost_boundary === :complete
            @test eff_est.trial_time ≈ 0.2 atol = 1e-12
            @test tot_est.trial_time ≈ 0.3 atol = 1e-12
            @test comp_est.trial_time ≈ 0.5 atol = 1e-12
            @test eff_est.operational_ttt < tot_est.operational_ttt < comp_est.operational_ttt

            # Missing effective or complete boundary is rejected rather than substituted
            only_total_sol = QUBOTools.SampleSet(
                [QUBOTools.Sample([0, 1], 1.0, 2)];
                metadata = Dict{String,Any}("time" => Dict{String,Any}("total" => 2.0)),
            )
            @test_throws ArgumentError QUBOTools.time_to_target_estimate(
                only_total_sol,
                1.0;
                trial_unit = :read,
                cost_boundary = :effective,
            )
            @test_throws ArgumentError QUBOTools.time_to_target_estimate(
                emp_Sol,
                1.0;
                trial_unit = :read,
                cost_boundary = :complete,
            )

            # 5. Correlated, selected, repaired, or best-only samples reject IID-read semantics
            for regime in ("correlated", "selected", "repaired", "best_only")
                non_iid_sol = QUBOTools.SampleSet(
                    [QUBOTools.Sample([0, 1], 1.0, 5)];
                    metadata = Dict{String,Any}(
                        "time" => Dict{String,Any}("effective" => 1.0),
                        "sampling_regime" => regime,
                    ),
                )
                @test_throws ArgumentError QUBOTools.time_to_target_estimate(
                    non_iid_sol,
                    1.0;
                    trial_unit = :read,
                )
                @test_throws ArgumentError QUBOTools.success_rate(
                    non_iid_sol,
                    1.0;
                    trial_unit = :read,
                )
                @test_throws ArgumentError QUBOTools.ttt(non_iid_sol, 1.0)
                @test QUBOTools.time_to_target_estimate(
                    non_iid_sol,
                    1.0;
                    trial_unit = :run,
                ).trial_unit === :run
            end

            # 6. Zero reads, malformed metadata, and nonfinite/invalid scalar inputs
            zero_read_sol = QUBOTools.SampleSet(
                [QUBOTools.Sample([0, 1], 1.0, 0)];
                metadata = Dict{String,Any}("time" => Dict{String,Any}("effective" => 1.0)),
            )
            @test isnan(QUBOTools.success_rate(zero_read_sol, 1.0))
            @test_throws ArgumentError QUBOTools.time_to_target_estimate(
                zero_read_sol,
                1.0;
                trial_unit = :read,
            )

            malformed_time_sol = QUBOTools.SampleSet(
                [QUBOTools.Sample([0, 1], 1.0, 2)];
                metadata = Dict{String,Any}("time" => "not-a-dict"),
            )
            @test_throws ArgumentError QUBOTools.total_time(malformed_time_sol)
            @test_throws ArgumentError QUBOTools.effective_time(malformed_time_sol)

            malformed_val_sol = QUBOTools.SampleSet(
                [QUBOTools.Sample([0, 1], 1.0, 2)];
                metadata = Dict{String,Any}("time" => Dict{String,Any}("effective" => "fast")),
            )
            @test_throws ArgumentError QUBOTools.effective_time(malformed_val_sol)

            @test_throws ArgumentError QUBOTools.time_to_target(0.0, 0.5, 0.99)
            @test_throws ArgumentError QUBOTools.time_to_target(-1.0, 0.5, 0.99)
            @test_throws ArgumentError QUBOTools.time_to_target(Inf, 0.5, 0.99)
            @test_throws ArgumentError QUBOTools.time_to_target(NaN, 0.5, 0.99)
            @test_throws ArgumentError QUBOTools.time_to_target(1.0, -0.1, 0.99)
            @test_throws ArgumentError QUBOTools.time_to_target(1.0, 1.1, 0.99)
            @test_throws ArgumentError QUBOTools.time_to_target(1.0, NaN, 0.99)
            @test_throws ArgumentError QUBOTools.time_to_target(1.0, 0.5, 0.0)
            @test_throws ArgumentError QUBOTools.time_to_target(1.0, 0.5, 1.0)
            @test_throws ArgumentError QUBOTools.time_to_target(1.0, 0.5, NaN)

            # Numerical stability for small probabilities, exact integer boundaries, and large counts
            small_p = QUBOTools.time_to_target_estimate(1.0, 1e-17, 0.99)
            @test isfinite(small_p.continuous_repetitions) && small_p.continuous_repetitions > 0.0
            @test small_p.continuous_repetitions ≈ log1p(-0.99) / log1p(-1e-17)
            @test small_p.operational_repetitions ≈ 4.60517018598809e17

            equal_small = QUBOTools.time_to_target_estimate(1.0, 1e-17, 1e-17)
            @test equal_small.continuous_repetitions == 1.0
            @test equal_small.operational_repetitions == 1.0
            @test equal_small.ttt == 1.0

            small_s = QUBOTools.time_to_target_estimate(1.0, 0.5, 1e-17)
            @test small_s.continuous_repetitions > 0.0
            @test small_s.continuous_repetitions ≈ log1p(-1e-17) / log1p(-0.5)
            @test small_s.operational_repetitions == 1.0

            p_128 = 1 / 128
            s_128 = 0.023254871368408203
            @test 1 - (1 - Rational{BigInt}(p_128))^3 == Rational{BigInt}(s_128)
            est_128 = QUBOTools.time_to_target_estimate(1.0, p_128, s_128)
            @test est_128.continuous_repetitions == 3.0
            @test est_128.operational_repetitions == 3.0
            @test QUBOTools.time_to_target_estimate(1.0, p_128, prevfloat(s_128)).operational_repetitions == 3.0
            @test QUBOTools.time_to_target_estimate(1.0, p_128, nextfloat(s_128)).operational_repetitions == 4.0

            p_32 = 1 / 32
            s_32 = 0.14678481221199036
            @test 1 - (1 - Rational{BigInt}(p_32))^5 == Rational{BigInt}(s_32)
            est_32 = QUBOTools.time_to_target_estimate(1.0, p_32, s_32)
            @test est_32.continuous_repetitions == 5.0
            @test est_32.operational_repetitions == 5.0
            @test QUBOTools.time_to_target_estimate(1.0, p_32, prevfloat(s_32)).operational_repetitions == 5.0
            @test QUBOTools.time_to_target_estimate(1.0, p_32, nextfloat(s_32)).operational_repetitions == 6.0

            large_n = 2^54
            est_near_one = QUBOTools.time_to_target_estimate(1.0; successes = large_n - 1, trials = large_n)
            @test est_near_one.status == :empirical_interior_probability
            @test est_near_one.successes == large_n - 1
            @test est_near_one.trials == large_n
            @test isfinite(est_near_one.continuous_repetitions) && est_near_one.continuous_repetitions > 0.0
            @test est_near_one.operational_repetitions == 1.0

            est_near_zero = QUBOTools.time_to_target_estimate(1.0; successes = 1, trials = large_n)
            @test est_near_zero.status == :empirical_interior_probability
            @test isfinite(est_near_zero.continuous_repetitions) && est_near_zero.continuous_repetitions > 1.0

            est_exact_one = QUBOTools.time_to_target_estimate(1.0; successes = large_n, trials = large_n)
            @test est_exact_one.status == :empirical_all_succeeded
            @test est_exact_one.continuous_repetitions == 0.0
            @test est_exact_one.operational_repetitions == 1.0

            # Large-count integer rounding and >2^63 safe conversion
            @test QUBOTools.time_to_target_estimate(1.0, 2.0^-52, 0.45).operational_repetitions == 2692418493831307.0
            @test QUBOTools.time_to_target_estimate(1.0, 1.7687970377159239e-16, 0.7048511250042409).operational_repetitions == 6898900003326794.0
            for mode in (:integer, :continuous, :continuous_floor_one)
                est_2p63 = QUBOTools.time_to_target_estimate(1.0, 4.992935520313763e-19, 0.99; repetition_mode = mode)
                @test isfinite(est_2p63.ttt) && est_2p63.ttt > 0.0
                @test isfinite(est_2p63.operational_repetitions) && isfinite(est_2p63.continuous_repetitions)
            end
        end

        @testset "Hamming Distance" begin
            @test QUBOTools.hamming_distance([0, 1, 1], [0, 1, 1]) == 0
            @test QUBOTools.hamming_distance([0, 0, 1], [0, 1, 1]) == 1
            @test QUBOTools.hamming_distance([0, 0, 1], [0, 1, 0]) == 2
            @test QUBOTools.hamming_distance([1, 0, 1], [0, 1, 0]) == 3
        end

        @testset "Field Alignment" begin
            # Bool Min model:
            # h_1 = 2.0/2 + 4.0/4 = +2.0 (prefers s_1 = -1 => x_1 = 0)
            # h_2 = -6.0/2 + 4.0/4 = -2.0 (prefers s_2 = +1 => x_2 = 1)
            # h_3 = 0.0 (inactive at atol = 0)
            m = QUBOTools.Model{Symbol,Float64,Int}(
                Set([:x1, :x2, :x3]),
                Dict(:x1 => 2.0, :x2 => -6.0),
                Dict((:x1, :x2) => 4.0);
                sense = :min,
                domain = :bool,
            )

            @test QUBOTools.field_alignment(m, [0, 1, 0]) == 1.0
            @test QUBOTools.field_alignment(m, [0, 1, 1]) == 1.0
            @test QUBOTools.field_alignment(m, [0, 0, 0]) == 0.5
            @test QUBOTools.field_alignment(m, [1, 0, 1]) == 0.0
            @test QUBOTools.field_alignment(m, Dict(:x1 => 0, :x2 => 1, :x3 => 0)) == 1.0
            @test QUBOTools.field_alignment(
                m,
                [1, 0, 1, 0];
                variables = [:aux, :x1, :x2, :x3],
            ) == 1.0

            # Invariance under domain and sense casts
            m_spin = QUBOTools.cast((QUBOTools.BoolDomain => QUBOTools.SpinDomain), m)
            m_max = QUBOTools.cast((QUBOTools.Min => QUBOTools.Max), m)
            m_max_spin = QUBOTools.cast((QUBOTools.BoolDomain => QUBOTools.SpinDomain), m_max)
            @test QUBOTools.field_alignment(m_spin, [↓, ↑, ↓]) == 1.0
            @test QUBOTools.field_alignment(m_spin, [↓, ↓, ↓]) == 0.5
            @test QUBOTools.field_alignment(m_max, [0, 1, 0]) == 1.0
            @test QUBOTools.field_alignment(m_max_spin, [↓, ↑, ↓]) == 1.0

            # Negative scale flips preferred spin direction; zero scale yields NaN
            m_neg_scale = QUBOTools.Model{Symbol,Float64,Int}(
                Set([:x1, :x2, :x3]),
                Dict(:x1 => 2.0, :x2 => -6.0),
                Dict((:x1, :x2) => 4.0);
                scale = -2.0,
                sense = :min,
                domain = :bool,
            )
            @test QUBOTools.field_alignment(m_neg_scale, [1, 0, 0]) == 1.0
            @test QUBOTools.field_alignment(m_neg_scale, [0, 1, 0]) == 0.0

            m_zero_scale = QUBOTools.Model{Symbol,Float64,Int}(
                Set([:x1, :x2]),
                Dict(:x1 => 2.0, :x2 => -6.0),
                Dict{Tuple{Symbol,Symbol},Float64}();
                scale = 0.0,
            )
            @test isnan(QUBOTools.field_alignment(m_zero_scale, [0, 1]))

            # Sample and SampleSet read-weighted alignment
            sol = QUBOTools.SampleSet{Float64,Int}(
                [
                    QUBOTools.Sample([0, 1, 0], -4.0, 3), # alignment 1.0
                    QUBOTools.Sample([0, 0, 0], 0.0, 2),  # alignment 0.5
                    QUBOTools.Sample([1, 0, 0], 2.0, 1),  # alignment 0.0
                ];
                sense = :min,
                domain = :bool,
            )
            QUBOTools.attach!(m, sol)
            @test QUBOTools.field_alignment(m, sol[1]) == 1.0
            @test QUBOTools.field_alignment(m, 1) == 1.0
            @test QUBOTools.field_alignment(m, 2) == 0.5
            @test QUBOTools.field_alignment(m, 3) == 0.0
            @test QUBOTools.field_alignment(m, sol) == (3 * 2 + 2 * 1 + 1 * 0) / (6 * 2)
            @test QUBOTools.field_alignment(m) == 4 / 6

            # Cross-domain solution on Bool model
            sol_spin = QUBOTools.cast((QUBOTools.BoolDomain => QUBOTools.SpinDomain), sol)
            @test QUBOTools.field_alignment(m, sol_spin) == 4 / 6
            @test QUBOTools.field_alignment(QUBOTools.form(m), sol_spin) == 4 / 6

            # Gauge-invariant model has no active fields => NaN
            m_gi = QUBOTools.gauge_invariant_qubo(m)
            @test isnan(QUBOTools.field_alignment(m_gi, [0, 1, 0]))
            @test isnan(QUBOTools.field_alignment(m_gi, sol))
            @test isnan(QUBOTools.field_alignment(m, [0, 1, 0]; atol = 2.0))

            # Validation errors
            @test_throws ArgumentError QUBOTools.field_alignment(m, [0, 1, 0]; atol = -1e-3)
            @test_throws ArgumentError QUBOTools.field_alignment(m, [0, 1, 0]; atol = NaN)
            @test_throws QUBOTools.SolutionError QUBOTools.field_alignment(m, [0, 1])
            @test_throws QUBOTools.SolutionError QUBOTools.field_alignment(m, [0, 1, 2])
            @test_throws QUBOTools.SolutionError QUBOTools.field_alignment(
                QUBOTools.form(m),
                [0, 1, 0];
                variables = [:x1, :x2, :x3],
            )
        end
    end

    return nothing
end

function test_model_metrics()
    @testset "⋅ Model" begin
        let m = QUBOTools.Model{Int,Float64,Int}(
                Dict{Int,Float64}(1 => 0.5, 2 => 2.0, 3 => -3.0, 4 => 0.0),
                Dict{Tuple{Int,Int},Float64}(
                    (1, 2) => 2.0,
                    (1, 3) => -2.0,
                    (2, 3) => 0.5,
                    (3, 4) => 0.0,
                ),
            )

            @test QUBOTools.linear_density(m) ≈ 3 / 4 atol = 1e-8
            @test QUBOTools.quadratic_density(m) ≈ 3 / 6 atol = 1e-8
            @test QUBOTools.density(m) ≈ 9 / 16 atol = 1e-8
        end

        let m = QUBOTools.Model{Int,Float64,Int}(
                Dict{Int,Float64}(),
                Dict{Tuple{Int,Int},Float64}(
                    (1, 2) => 0.0,
                    (1, 3) => -0.0,
                    (2, 3) => 0.0,
                    (3, 4) => 0.0,
                ),
            )

            @test QUBOTools.linear_density(m) ≈ 0.0 atol = 1e-8
            @test QUBOTools.quadratic_density(m) ≈ 0.0 atol = 1e-8
            @test QUBOTools.density(m) ≈ 0.0 atol = 1e-8
        end

        let m = QUBOTools.Model{Int,Float64,Int}(
                Dict{Int,Float64}(1 => 0.5, 2 => 2.0, 3 => -3.0, 4 => 1.0),
                Dict{Tuple{Int,Int},Float64}(
                    (1, 2) => 2.0,
                    (1, 3) => -2.0,
                    (1, 4) => 3.0,
                    (2, 3) => 0.5,
                    (2, 4) => -1.0,
                    (3, 4) => 1.0,
                ),
            )

            @test QUBOTools.linear_density(m) ≈ 1.0 atol = 1e-8
            @test QUBOTools.quadratic_density(m) ≈ 1.0 atol = 1e-8
            @test QUBOTools.density(m) ≈ 1.0 atol = 1e-8
        end

        @testset "Coercive Fields & Gauge Invariance" begin
            # 1. Naive vs gauge-invariant QUBO on all form types and Model
            L = Dict{Int,Float64}(1 => 2.0, 2 => -4.0, 3 => 0.0, 4 => 6.0)
            Q = Dict{Tuple{Int,Int},Float64}((1, 2) => 8.0, (2, 3) => -4.0)
            m_bool = QUBOTools.Model{Int,Float64,Int}(
                Set(1:4),
                L,
                Q;
                scale = 3.0,
                offset = 1.25,
                sense = :min,
                domain = :bool,
            )
            # h_1 = 2/2 + 8/4 = 3.0; ||J_1||_1 = 2.0, ||J_1||_2 = 2.0
            # h_2 = -4/2 + (8 - 4)/4 = -1.0; ||J_2||_1 = 2 + 1 = 3.0, ||J_2||_2 = sqrt(5)
            # h_3 = 0/2 - 4/4 = -1.0; ||J_3||_1 = 1.0, ||J_3||_2 = 1.0
            # h_4 = 6/2 + 0 = 3.0 (isolated); ||J_4|| = 0 => ratio = Inf
            expected_h = [3.0, -1.0, -1.0, 3.0]
            @test QUBOTools.coercive_fields(m_bool) == expected_h

            for spec in (:sparse, :dense, :dict)
                f_bool = QUBOTools.form(m_bool, spec)
                f_spin = QUBOTools.cast((QUBOTools.BoolDomain => QUBOTools.SpinDomain), f_bool)
                @test QUBOTools.coercive_fields(f_bool) == expected_h
                @test QUBOTools.coercive_fields(f_spin) == expected_h
                @test !QUBOTools.is_gauge_invariant(f_bool)
                @test !QUBOTools.is_gauge_invariant(f_spin)
                @test QUBOTools.zero_field_fraction(f_bool) == 0.0
                @test QUBOTools.zero_field_fraction(f_bool; atol = 1.0) == 0.5
                # Dominance: |h_1|=3 > 2, |h_2|=1 <= 3, |h_3|=1 <= 1, |h_4|=3 > 0 => 2/4 = 0.5
                @test QUBOTools.trivial_dominance_fraction(f_bool) == 0.5
                @test QUBOTools.trivial_dominance_fraction(f_spin) == 0.5

                r_l1 = QUBOTools.coercive_field_ratios(f_bool; norm = 1)
                @test r_l1[1:3] ≈ [1.5, 1 / 3, 1.0]
                @test isinf(r_l1[4])
                @test QUBOTools.coercive_field_ratio(f_bool; norm = 1) ≈ (1.5 + 1 / 3 + 1.0) / 3
                @test QUBOTools.coercive_field_ratio(f_spin; norm = 1) ≈ (1.5 + 1 / 3 + 1.0) / 3

                r_l2 = QUBOTools.coercive_field_ratios(f_bool; norm = 2)
                @test r_l2[1:3] ≈ [1.5, 1 / sqrt(5.0), 1.0]
                @test isinf(r_l2[4])
                @test QUBOTools.coercive_field_ratio(f_bool; norm = 2) ≈ (1.5 + 1 / sqrt(5.0) + 1.0) / 3

                r_inf = QUBOTools.coercive_field_ratios(f_bool; norm = Inf)
                @test r_inf[1:3] ≈ [1.5, 0.5, 1.0]

                # Gauge-invariant projection on both :bool and :spin forms
                gi_bool = QUBOTools.gauge_invariant_qubo(f_bool)
                gi_spin = QUBOTools.gauge_invariant_qubo(f_spin)
                @test QUBOTools.is_gauge_invariant(gi_bool)
                @test QUBOTools.is_gauge_invariant(gi_spin)
                @test QUBOTools.coercive_fields(gi_bool) == zeros(4)
                @test QUBOTools.coercive_fields(gi_spin) == zeros(4)
                @test QUBOTools.zero_field_fraction(gi_bool) == 1.0
                @test QUBOTools.trivial_dominance_fraction(gi_bool) == 0.0
                @test QUBOTools.coercive_field_ratio(gi_bool) == 0.0
                @test QUBOTools.offset(gi_bool) == 1.25

                gi_bool_zero = QUBOTools.gauge_invariant_qubo(f_bool; keep_offset = false)
                gi_spin_zero = QUBOTools.gauge_invariant_qubo(f_spin; keep_offset = false)
                @test QUBOTools.offset(gi_bool_zero) == 0.0
                @test QUBOTools.value(zeros(Int, 4), gi_bool_zero) == 0.0
                @test QUBOTools.value(ones(Int, 4), gi_bool_zero) == 0.0
                @test QUBOTools.value(fill(↓, 4), gi_spin_zero) == 0.0
                @test QUBOTools.value(fill(↑, 4), gi_spin_zero) == 0.0
                # Check Z2 symmetry E(x) == E(1 - x) for all 16 states
                for mask = 0:15
                    x = [((mask >> (k - 1)) & 1) for k = 1:4]
                    x_bar = 1 .- x
                    @test QUBOTools.value(x, gi_bool) == QUBOTools.value(x_bar, gi_bool)
                end
            end

            # Model-level gauge_invariant_qubo resets stale solution
            QUBOTools.attach!(
                m_bool,
                QUBOTools.SampleSet{Float64,Int}([QUBOTools.Sample([0, 1, 1, 0], -5.0, 2)]),
            )
            m_gi = QUBOTools.gauge_invariant_qubo(m_bool; keep_offset = false)
            @test QUBOTools.is_gauge_invariant(m_gi)
            @test isempty(QUBOTools.solution(m_gi))
            @test QUBOTools.value(m_gi, [0, 0, 0, 0]) == 0.0
            @test QUBOTools.value(m_gi, [1, 1, 1, 1]) == 0.0

            # 2. Empty and uncoupled models
            m_empty = QUBOTools.Model{Int,Float64,Int}()
            @test isempty(QUBOTools.coercive_fields(m_empty))
            @test isempty(QUBOTools.coercive_field_ratios(m_empty))
            @test isnan(QUBOTools.coercive_field_ratio(m_empty))
            @test isnan(QUBOTools.zero_field_fraction(m_empty))
            @test isnan(QUBOTools.trivial_dominance_fraction(m_empty))
            @test QUBOTools.is_gauge_invariant(m_empty)

            m_lin_only = QUBOTools.Model{Int,Float64,Int}(
                Set([1, 2]),
                Dict(1 => 2.0, 2 => 0.0),
                Dict{Tuple{Int,Int},Float64}(),
            )
            @test QUBOTools.coercive_field_ratios(m_lin_only) == [Inf, 0.0]
            @test isnan(QUBOTools.coercive_field_ratio(m_lin_only))

            # 3. Overflow & exactness regressions (Int64 typemax/typemin, catastrophic cancellation, wide BigFloat, Rational atol, extreme L2 norms)
            M64 = typemax(Int64)
            m_int_ovf = QUBOTools.Model{Int,Int64,Int}(
                Set(1:3),
                Dict(1 => -M64, 2 => -M64),
                Dict((1, 2) => M64, (1, 3) => M64, (2, 3) => M64),
            )
            @test !QUBOTools.is_gauge_invariant(m_int_ovf)
            @test QUBOTools.coercive_fields(m_int_ovf)[1:2] == [0.0, 0.0]
            @test QUBOTools.zero_field_fraction(m_int_ovf) == 2 / 3
            # Intermediate row sum 2 * M64 exceeds typemax(Int64), but -row_sum ÷ 2 == -M64 fits in Int64!
            m_int_gi = QUBOTools.gauge_invariant_qubo(m_int_ovf)
            @test QUBOTools.is_gauge_invariant(m_int_gi)

            m_int_true_ovf = QUBOTools.Model{Int,Int64,Int}(
                Set(1:4),
                Dict{Int,Int64}(),
                Dict((1, 2) => M64 - 1, (1, 3) => M64 - 1, (1, 4) => M64 - 1),
            )
            @test_throws ArgumentError QUBOTools.gauge_invariant_qubo(m_int_true_ovf)

            m_int_ovf_all = QUBOTools.Model{Int,Int64,Int}(
                Set(1:3),
                Dict(1 => -M64, 2 => -M64, 3 => -M64),
                Dict((1, 2) => M64, (1, 3) => M64, (2, 3) => M64),
            )
            @test QUBOTools.is_gauge_invariant(m_int_ovf_all)
            @test QUBOTools.coercive_fields(m_int_ovf_all) == [0.0, 0.0, 0.0]
            @test QUBOTools.zero_field_fraction(m_int_ovf_all) == 1.0

            m_int_odd = QUBOTools.Model{Int,Int64,Int}(
                Set(1:2),
                Dict{Int,Int64}(),
                Dict((1, 2) => 3),
            )
            @test_throws ArgumentError QUBOTools.gauge_invariant_qubo(m_int_odd)

            # Float64 catastrophic cancellation & cluster-boundary cancellation
            m_cancel = QUBOTools.Model{Int,Float64,Int}(
                Set(1:4),
                Dict(1 => 1.0e100),
                Dict((1, 2) => -1.0e100, (1, 3) => -1.0e100, (1, 4) => 4.0),
            )
            @test QUBOTools.coercive_fields(m_cancel)[1] == 1.0
            @test !QUBOTools.is_gauge_invariant(m_cancel; atol = 0.5)
            @test QUBOTools.is_gauge_invariant(
                QUBOTools.Model{Int,Float64,Int}(
                    Set(1:3),
                    Dict(1 => 2.0, 2 => 2.0, 3 => 0.0),
                    Dict((1, 2) => -4.0, (1, 3) => 4.0 * 2.0^(-60)),
                );
                atol = (BigInt(1) // (BigInt(2)^60)) + (BigInt(1) // (BigInt(2)^200)),
            )
            @test !QUBOTools.is_gauge_invariant(
                QUBOTools.Model{Int,Float64,Int}(
                    Set(1:3),
                    Dict(1 => 2.0, 2 => 2.0, 3 => 0.0),
                    Dict((1, 2) => -4.0, (1, 3) => 4.0 * 2.0^(-60)),
                );
                atol = (BigInt(1) // (BigInt(2)^60)) - (BigInt(1) // (BigInt(2)^200)),
            )

            # Wide-exponent BigFloat and high-precision BigFloat stored in lower ambient precision
            m_bf_wide = QUBOTools.Model{Int,BigFloat,Int}(
                Set(1:3),
                Dict(1 => -ldexp(BigFloat(1), 2200)),
                Dict((1, 2) => ldexp(BigFloat(2), 2200), (1, 3) => BigFloat(4)),
            )
            @test QUBOTools.coercive_fields(m_bf_wide)[1] == BigFloat(1)
            @test !QUBOTools.is_gauge_invariant(m_bf_wide; atol = 0.5)

            two_c_hi = setprecision(BigFloat, 512) do
                BigFloat(2) + ldexp(BigFloat(1), -299)
            end
            setprecision(BigFloat, 64) do
                m_hi = QUBOTools.Model{Int,BigFloat,Int}(
                    Set(1:2),
                    Dict(1 => two_c_hi, 2 => BigFloat(2)),
                    Dict((1, 2) => BigFloat(-4)),
                )
                @test !QUBOTools.is_gauge_invariant(m_hi)
            end

            # Regression test for bigfloat-abs-neg-precision-truncation:
            # 512-bit BigFloat coefficients evaluated inside a 64-bit ambient setprecision block
            # must preserve full 512-bit precision across abs(...) and negation in
            # trivial_dominance_fraction, coercive_field_ratios, and gauge_invariant_qubo.
            let q12_hi = setprecision(BigFloat, 512) do
                    -(BigFloat(4) + ldexp(BigFloat(1), -200))
                end,
                c1_eq = setprecision(BigFloat, 512) do
                    BigFloat(4) + ldexp(BigFloat(1), -200)
                end,
                c1_strict = setprecision(BigFloat, 512) do
                    BigFloat(4) + ldexp(BigFloat(1), -199)
                end,
                j12_spin_hi = setprecision(BigFloat, 512) do
                    -(BigFloat(1) + ldexp(BigFloat(1), -200))
                end,
                h1_spin_hi = setprecision(BigFloat, 512) do
                    (BigFloat(1) + ldexp(BigFloat(1), -53)) * (BigFloat(1) + ldexp(BigFloat(1), -200))
                end

                m_eq = QUBOTools.Model{Int,BigFloat,Int}(
                    Set(1:2),
                    Dict(1 => c1_eq, 2 => BigFloat(0)),
                    Dict((1, 2) => q12_hi),
                )
                m_strict = QUBOTools.Model{Int,BigFloat,Int}(
                    Set(1:2),
                    Dict(1 => c1_strict, 2 => BigFloat(0)),
                    Dict((1, 2) => q12_hi),
                )
                m_ratio_hi = QUBOTools.Model{Int,BigFloat,Int}(
                    Set(1:2),
                    Dict(1 => h1_spin_hi, 2 => BigFloat(0)),
                    Dict((1, 2) => j12_spin_hi);
                    domain = :spin,
                )
                setprecision(BigFloat, 64) do
                    # For m_eq: h_1 = (2 + 2^-201) - (1 + 2^-202) = 1 + 2^-202 == |J_12| => strict dominance is false (0.0)
                    # (Without exact 512-bit abs, |J_12| would truncate to 1 and falsely report 0.5.)
                    @test QUBOTools.trivial_dominance_fraction(m_eq) == 0.0
                    # For m_strict: h_1 = (2 + 2^-200) - (1 + 2^-202) = 1 + 3*2^-202 > |J_12| = 1 + 2^-202 => node 1 strictly dominated (0.5)
                    @test QUBOTools.trivial_dominance_fraction(m_strict) == 0.5
                    # Exact ratio abs_h / |J_12| == 1 + 2^-53 (tie-to-even -> 1.0 in Float64; 64-bit truncated |J_12| -> nextfloat(1.0))
                    @test QUBOTools.coercive_field_ratios(m_ratio_hi; norm = 1)[1] == 1.0

                    m_gi_hi = QUBOTools.gauge_invariant_qubo(m_strict)
                    @test QUBOTools.is_gauge_invariant(m_gi_hi)
                    @test QUBOTools.zero_field_fraction(m_gi_hi) == 1.0
                end
            end

            # Subnormal Float64 coupling nextfloat(0.0) in :bool domain:
            # coercive_fields underflows to 0.0 in Float64, but exact accumulator knows both fields are nonzero
            let m_sub = QUBOTools.Model{Int,Float64,Int}(
                    Set(1:2),
                    Dict{Int,Float64}(),
                    Dict((1, 2) => nextfloat(0.0)),
                )
                @test QUBOTools.coercive_fields(m_sub) == [0.0, 0.0]
                @test !QUBOTools.is_gauge_invariant(m_sub)
                @test QUBOTools.zero_field_fraction(m_sub) == 0.0
                rep_sub = QUBOTools.report(m_sub)
                @test rep_sub["model"]["coercive_fields"]["nonzero_count"] == 2
                @test rep_sub["model"]["coercive_fields"]["zero_field_fraction"] == 0.0
                @test rep_sub["model"]["coercive_fields"]["is_gauge_invariant"] == false
            end

            # Extreme Float64 couplings in coercive_field_ratios (1e300 and 1e-300) do not overflow/underflow L2 norm
            for scale_exp in (1.0e300, 1.0e-300)
                m_ext = QUBOTools.Model{Int,Float64,Int}(
                    Set(1:3),
                    Dict(1 => 2.0 * scale_exp),
                    Dict((1, 2) => 12.0 * scale_exp, (1, 3) => 16.0 * scale_exp),
                )
                # h_1 = (1 + 3 + 4) * scale_exp = 8 * scale_exp
                # J_{1,2} = 3 * scale_exp, J_{1,3} = 4 * scale_exp => ||J_1||_2 = 5 * scale_exp
                @test QUBOTools.coercive_field_ratios(m_ext; norm = 2)[1] ≈ 8 / 5
            end

            @test_throws ArgumentError QUBOTools.coercive_field_ratios(m_bool; norm = 0)
            @test_throws ArgumentError QUBOTools.coercive_field_ratios(m_bool; norm = -1)
            @test_throws ArgumentError QUBOTools.coercive_field_ratios(m_bool; norm = NaN)
            @test_throws ArgumentError QUBOTools.is_gauge_invariant(m_bool; atol = -1.0)
            @test_throws ArgumentError QUBOTools.zero_field_fraction(m_bool; atol = -1.0)
            @test_throws ArgumentError QUBOTools.trivial_dominance_fraction(m_bool; atol = -1.0)
        end

        @testset "Integerize Scale" begin
            # 1. Already integer-scaled Model & Forms are returned as owned copies with unchanged scale
            m_int_f64 = QUBOTools.Model{Int,Float64,Int}(
                Set(1:3),
                Dict(1 => 2.0, 2 => -3.0),
                Dict((1, 2) => 4.0, (2, 3) => -1.0);
                scale = 2.5,
                offset = -5.0,
            )
            @test QUBOTools.is_integer_scaled(m_int_f64)
            m_int_copy = QUBOTools.integerize_scale(m_int_f64)
            @test QUBOTools.is_integer_scaled(m_int_copy)
            @test QUBOTools.scale(m_int_copy) == 2.5
            @test QUBOTools.offset(m_int_copy) == -5.0
            @test Dict(QUBOTools.linear_terms(m_int_copy)) == Dict(QUBOTools.linear_terms(m_int_f64))
            @test Dict(QUBOTools.quadratic_terms(m_int_copy)) == Dict(QUBOTools.quadratic_terms(m_int_f64))

            # 2. Dyadic scaling (m = 4) across SparseForm, DenseForm, DictForm, and Model
            m_dyadic = QUBOTools.Model{Int,Float64,Int}(
                Set(1:3),
                Dict(1 => 0.25, 2 => -0.5, 3 => 1.0),
                Dict((1, 2) => -0.75, (2, 3) => 0.5);
                scale = 2.0,
                offset = 0.25,
            )
            @test !QUBOTools.is_integer_scaled(m_dyadic)
            for spec in (:sparse, :dense, :dict)
                f = QUBOTools.form(m_dyadic, spec)
                @test !QUBOTools.is_integer_scaled(f)
                f_int = QUBOTools.integerize_scale(f)
                @test typeof(f_int) === typeof(f)
                @test QUBOTools.is_integer_scaled(f_int)
                @test QUBOTools.scale(f_int) == 0.5
                @test QUBOTools.offset(f_int) == 1.0
                for mask = 0:7
                    x = [((mask >> (k - 1)) & 1) for k = 1:3]
                    @test QUBOTools.value(x, f_int) == QUBOTools.value(x, f)
                end
            end
            m_dyadic_int = QUBOTools.integerize_scale(m_dyadic)
            @test QUBOTools.is_integer_scaled(m_dyadic_int)
            @test QUBOTools.scale(m_dyadic_int) == 0.5
            @test QUBOTools.offset(m_dyadic_int) == 1.0

            # 3. Decimal Float64 noise (e.g. chimera_k64_01 style -1.7999999999999998 = -0.9 - 0.9)
            # restores exact integer coefficients and exact Z2 gauge invariance!
            m_dec = QUBOTools.Model{Int,Float64,Int}(
                Set(1:3),
                Dict(1 => 0.9, 2 => -1.7999999999999998, 3 => 0.9),
                Dict((1, 2) => 1.8, (2, 3) => 1.8);
                scale = 1.0,
                offset = -0.9,
            )
            # Note: in BoolDomain, h_2 = c_2/2 + (q_{12} + q_{23})/4:
            # With c_1 = -0.9, c_2 = -1.7999999999999998, c_3 = -0.9 and q_{12} = 1.8, q_{23} = 1.8:
            m_chimera = QUBOTools.Model{Int,Float64,Int}(
                Set(1:3),
                Dict(1 => -0.9, 2 => -1.7999999999999998, 3 => -0.9),
                Dict((1, 2) => 1.8, (2, 3) => 1.8);
                scale = 1.0,
                offset = 0.0,
            )
            @test !QUBOTools.is_integer_scaled(m_chimera)
            @test !QUBOTools.is_gauge_invariant(m_chimera)
            m_chimera_int = QUBOTools.integerize_scale(m_chimera)
            @test QUBOTools.is_integer_scaled(m_chimera_int)
            @test QUBOTools.scale(m_chimera_int) == 0.1
            @test Dict(QUBOTools.linear_terms(m_chimera_int)) == Dict(1 => -9.0, 2 => -18.0, 3 => -9.0)
            @test Dict(QUBOTools.quadratic_terms(m_chimera_int)) == Dict((1, 2) => 18.0, (2, 3) => 18.0)
            @test QUBOTools.is_gauge_invariant(m_chimera_int)
            @test QUBOTools.zero_field_fraction(m_chimera_int) == 1.0

            # 4. Sub-ulp near-tie perturbations on dyadic values must NOT be rounded away
            m_near_tie = QUBOTools.Model{Int,Float64,Int}(
                Set(1:3),
                Dict(1 => -0.75 + 2.0^-53, 2 => -prevfloat(0.5)),
                Dict((1, 2) => 1.0, (1, 3) => 0.5),
            )
            @test !QUBOTools.is_integer_scaled(m_near_tie)
            m_near_tie_out = QUBOTools.integerize_scale(m_near_tie)
            @test !QUBOTools.is_integer_scaled(m_near_tie_out)
            @test QUBOTools.scale(m_near_tie_out) == 1.0
            @test Dict(QUBOTools.linear_terms(m_near_tie_out)) == Dict(QUBOTools.linear_terms(m_near_tie))

            # 5. Non-decimal / non-dyadic values (e.g. 1/3) and large atol do not corrupt or annihilate coefficients
            m_third = QUBOTools.Model{Int,Float64,Int}(
                Set(1:2),
                Dict(1 => 1.0 / 3.0, 2 => 1.0),
                Dict((1, 2) => -2.0 / 3.0),
            )
            @test !QUBOTools.is_integer_scaled(QUBOTools.integerize_scale(m_third))
            @test QUBOTools.scale(QUBOTools.integerize_scale(m_third)) == 1.0

            m_tiny = QUBOTools.Model{Int,Float64,Int}(
                Set(1:2),
                Dict(1 => 1e-4, 2 => 0.1),
                Dict((1, 2) => 0.2),
            )
            # Even with loose atol = 0.05, m = 10 must not annihilate 1e-4 to 0; true multiplier is m = 10000
            m_tiny_int = QUBOTools.integerize_scale(m_tiny; atol = 0.05)
            @test QUBOTools.is_integer_scaled(m_tiny_int)
            @test QUBOTools.scale(m_tiny_int) == 1e-4
            @test Dict(QUBOTools.linear_terms(m_tiny_int)) == Dict(1 => 1.0, 2 => 1000.0)

            # 6. Rational{Int} exact LCM denominator scaling
            m_rat = QUBOTools.Model{Int,Rational{Int},Int}(
                Set(1:3),
                Dict(1 => 1 // 6, 2 => -3 // 4),
                Dict((1, 2) => 5 // 12, (2, 3) => -1 // 3);
                scale = 2 // 1,
                offset = 1 // 2,
            )
            @test !QUBOTools.is_integer_scaled(m_rat)
            m_rat_int = QUBOTools.integerize_scale(m_rat)
            @test QUBOTools.is_integer_scaled(m_rat_int)
            @test QUBOTools.scale(m_rat_int) == 1 // 6
            @test QUBOTools.offset(m_rat_int) == 6 // 1
            @test Dict(QUBOTools.linear_terms(m_rat_int)) == Dict(1 => 2 // 1, 2 => -9 // 1)
            @test Dict(QUBOTools.quadratic_terms(m_rat_int)) == Dict((1, 2) => 5 // 1, (2, 3) => -4 // 1)

            # 7. High-precision BigFloat inside lower ambient precision preserves precision
            v_hi = setprecision(BigFloat, 512) do
                BigFloat(1) / BigFloat(8) + ldexp(BigFloat(1), -200)
            end
            m_bf_hi = QUBOTools.Model{Int,BigFloat,Int}(
                Set(1:2),
                Dict(1 => v_hi),
                Dict((1, 2) => BigFloat(1) / BigFloat(4)),
            )
            setprecision(BigFloat, 64) do
                m_bf_out = QUBOTools.integerize_scale(m_bf_hi)
                # v_hi has a 2^-200 perturbation so m <= 10^9 cannot integerize it
                @test !QUBOTools.is_integer_scaled(m_bf_out)
                @test QUBOTools.scale(m_bf_out) == BigFloat(1)
            end

            # 8. Zero or non-finite scale / invalid kwargs
            m_zero_sc = QUBOTools.Model{Int,Float64,Int}(
                Set(1:2),
                Dict(1 => 0.5),
                Dict((1, 2) => 0.25);
                scale = 0.0,
            )
            @test QUBOTools.scale(QUBOTools.integerize_scale(m_zero_sc)) == 0.0
            @test !QUBOTools.is_integer_scaled(QUBOTools.integerize_scale(m_zero_sc))

            @test_throws ArgumentError QUBOTools.integerize_scale(m_dyadic; max_decimals = -1)
            @test_throws ArgumentError QUBOTools.integerize_scale(m_dyadic; max_decimals = true)
            @test_throws ArgumentError QUBOTools.integerize_scale(m_dyadic; atol = -1e-12)
            @test_throws ArgumentError QUBOTools.integerize_scale(m_dyadic; atol = NaN)
            @test_throws ArgumentError QUBOTools.integerize_scale(m_dyadic; atol = Inf)
            @test_throws ArgumentError QUBOTools.integerize_scale(m_dyadic; atol = true)
        end
    end

    return nothing
end

function test_plots()
    @testset "→ Plots" verbose = true begin
        test_energy_frequency_plot()
        test_model_density_plot()
        test_system_layout_plot()
    end

    return nothing
end

function test_energy_frequency_plot()
    @testset "⋅ Energy Frequency" begin
        sol = SampleSet([
            Sample([0, 0], 1.0, 1),
            Sample([0, 1], 2.0, 2),
            Sample([1, 0], 3.0, 3),
            Sample([1, 1], 4.0, 4),
        ])

        p = QUBOTools.EnergyFrequencyPlot(sol)

        let r = RecipesBase.apply_recipe(Dict{Symbol,Any}(), p)
            @test length(r) == 1
            @test length(r[].args) == 2

            x, y = r[].args
            attr = r[].plotattributes

            @test x == [1.0, 2.0, 3.0, 4.0]
            @test y == [1, 2, 3, 4]

            @test attr[:ylabel] == "Frequency"
            @test attr[:xlabel] == "Energy"
        end
    end

    return nothing
end

function test_model_density_plot()
    @testset "⋅ Model Density" begin
        L = Dict{Int,Float64}(1 => 0.5, 2 => 2.0, 3 => -3.0)
        Q = Dict{Tuple{Int,Int},Float64}((1, 2) => 2.0, (1, 3) => -2.0, (2, 3) => 0.5)

        m = QUBOTools.Model{Int,Float64,Int}(L, Q; domain = :bool)
        p = QUBOTools.ModelDensityPlot(m)

        let r = RecipesBase.apply_recipe(Dict{Symbol,Any}(), p)
            @test length(r) == 1
            @test length(r[].args) == 3

            x, y, z = r[].args
            attr = r[].plotattributes

            @test x == [1, 2, 3]
            @test y == [1, 2, 3]
            @test z ≈ [0.5 1.0 -1.0; 1.0 2.0 0.25; -1.0 0.25 -3.0]

            @test attr[:clims] == (-3.0, 3.0)

            @test attr[:ylabel] == "Variable Index"
            @test attr[:xlabel] == "Variable Index"
        end
    end

    return nothing
end

function test_system_layout_plot()
    @testset "⋅ System Layout" begin
        L = Dict{Int,Float64}(1 => 0.5, 2 => 2.0, 3 => -3.0)
        Q = Dict{Tuple{Int,Int},Float64}((1, 2) => 2.0, (1, 3) => -2.0, (2, 3) => 0.5)

        m = QUBOTools.Model{Int,Float64,Int}(L, Q; domain = :bool)
        p = QUBOTools.SystemLayoutPlot(m)

        let r = RecipesBase.apply_recipe(Dict{Symbol,Any}(), p)
            @test length(r) == 2

            let (x, y) = r[1].args
                @test x ≈ [1,  -1/2, NaN, 1,   -1/2, NaN,  -1/2,   -1/2] atol = 1E-8 nans = true
                @test y ≈ [0, 3/√12, NaN, 0, -3/√12, NaN, 3/√12, -3/√12] atol = 1E-8 nans = true
            end

            let (x, y) = r[2].args
                @test x ≈ [1,  -1/2,   -1/2] atol = 1E-8
                @test y ≈ [0, 3/√12, -3/√12] atol = 1E-8
            end
        end
    end

    return nothing
end

struct _MockFeasibilitySummary
    result_count::Int
    feasible_count::Int
    max_violation::Float64
    total_violation::Float64
end

function test_reports()
    @testset "→ Reports" verbose = true begin
        @testset "⋅ Model with attached solution and metadata" begin
            L = Dict{Symbol,Float64}(:x1 => -1.0, :x2 => 2.0, :x3 => -0.5)
            Q = Dict{Tuple{Symbol,Symbol},Float64}((:x1, :x2) => 4.0, (:x2, :x3) => -2.0)
            model = QUBOTools.Model{Symbol,Float64,Int}(
                L,
                Q;
                scale = 2.0,
                offset = 1.5,
                sense = :min,
                domain = :bool,
                metadata = Dict{String,Any}("id" => "test-report-model"),
            )

            s1 = [1, 0, 1]
            s2 = [0, 0, 0]
            s3 = [1, 1, 0]
            v1 = QUBOTools.value(model, s1) # 2.0 * (-1.0 - 0.5 + 1.5) = 0.0
            v2 = QUBOTools.value(model, s2) # 2.0 * (0.0 + 1.5) = 3.0
            v3 = QUBOTools.value(model, s3) # 2.0 * (-1.0 + 2.0 + 4.0 + 1.5) = 13.0

            sol = QUBOTools.SampleSet{Float64,Int}(
                [
                    QUBOTools.Sample(s1, v1, 2),
                    QUBOTools.Sample(s2, v2, 3),
                    QUBOTools.Sample(s3, v3, 5),
                ];
                metadata = Dict{String,Any}(
                    "solver" => "mock-sampler",
                    "time" => Dict{String,Any}("effective" => 1.0, "total" => 2.5),
                ),
                sense = :min,
                domain = :bool,
            )
            QUBOTools.attach!(model, sol)

            reformulation_meta = Dict{String,Any}(
                "schema_version" => 1,
                "package" => Dict{String,Any}("name" => "ToQUBO", "version" => "0.1.0"),
                "applied_penalties" => Dict{String,Any}(
                    "constraints" => [Dict{String,Any}("id" => 1, "penalty" => 12.5)],
                    "variables" => Any[],
                    "slack_variables" => Any[],
                ),
                "penalty_policy" => Dict{String,Any}("strategy" => "exact"),
            )
            feas = _MockFeasibilitySummary(3, 2, 0.25, 0.25)

            mktempdir() do dir
                path = joinpath(dir, "report.json")
                returned_path = QUBOTools.write_report(
                    path,
                    model;
                    λ = 0.0,
                    s = 0.99,
                    trial_unit = :read,
                    reformulation = reformulation_meta,
                    feasibility = feas,
                    include_samples = true,
                )
                @test returned_path == path
                @test isfile(path)

                parsed = QUBOTools.JSON.parsefile(path)
                @test parsed["format"] == "QUBOTools.report"
                @test parsed["version"] == 1
                @test parsed["package_versions"]["QUBOTools"] == string(QUBOTools.__version__())
                @test parsed["package_versions"]["Julia"] == string(VERSION)

                # Model section
                m_sec = parsed["model"]
                @test m_sec["dimension"] == 3
                @test m_sec["variables"] == ["x1", "x2", "x3"]
                @test m_sec["sense"] == "min"
                @test m_sec["domain"] == "bool"
                @test m_sec["scale"] == 2.0
                @test m_sec["offset"] == 1.5
                @test m_sec["linear_size"] == 3
                @test m_sec["quadratic_size"] == 2
                @test m_sec["term_count"] == 5
                @test m_sec["density"]["total"] ≈ (3 + 4) / 9
                @test m_sec["density"]["linear"] ≈ 1.0
                @test m_sec["density"]["quadratic"] ≈ 2 / 3
                @test m_sec["coefficients"]["linear"]["count"] == 3
                @test m_sec["coefficients"]["linear"]["min"] == -1.0
                @test m_sec["coefficients"]["linear"]["max"] == 2.0
                @test m_sec["coefficients"]["linear"]["min_abs"] == 0.5
                @test m_sec["coefficients"]["linear"]["max_abs"] == 2.0
                @test m_sec["coefficients"]["linear"]["dynamic_range"] == 4.0
                @test m_sec["coefficients"]["quadratic"]["count"] == 2
                @test m_sec["coefficients"]["quadratic"]["min"] == -2.0
                @test m_sec["coefficients"]["quadratic"]["max"] == 4.0
                @test m_sec["coefficients"]["all"]["count"] == 5
                @test m_sec["coercive_fields"]["count"] == 3
                @test m_sec["coercive_fields"]["is_gauge_invariant"] == false
                @test m_sec["coercive_fields"]["zero_field_fraction"] == 0.0
                @test m_sec["coercive_fields"]["trivial_dominance_fraction"] ≈ 1 / 3
                @test m_sec["coercive_fields"]["mean_l1_ratio"] ≈ (0.5 + 1.0 + 1.5) / 3
                @test m_sec["metadata"]["id"] == "test-report-model"

                # Solution section
                s_sec = parsed["solution"]
                @test s_sec["present"] == true
                @test s_sec["sample_count"] == 3
                @test s_sec["total_reads"] == 10
                @test s_sec["sense"] == "min"
                @test s_sec["domain"] == "bool"
                @test s_sec["metadata"]["solver"] == "mock-sampler"
                @test s_sec["samples_metadata"]["format"] == "QUBOTools.samples"
                @test s_sec["samples_metadata"]["model"]["scale"] == 2.0
                @test s_sec["samples_metadata"]["model"]["offset"] == 1.5
                @test s_sec["timing"]["effective_time"] == 1.0
                @test s_sec["timing"]["total_time"] == 2.5
                @test s_sec["energies"]["best"] == 0.0
                @test s_sec["energies"]["min"] == 0.0
                @test s_sec["energies"]["max"] == 13.0
                @test s_sec["energies"]["mean"] ≈ (2 * 0.0 + 3 * 3.0 + 5 * 13.0) / 10
                @test s_sec["objective_values_verified"] == true
                @test s_sec["objective_mismatch_count"] == 0

                best_s = s_sec["best_sample"]
                @test best_s["state"] == [1, 0, 1]
                @test best_s["state_string"] == "101"
                @test best_s["value"] == 0.0
                @test best_s["reads"] == 2
                @test best_s["probability"] ≈ 0.2
                @test best_s["field_alignment"] ≈ 2 / 3
                @test best_s["objective_breakdown"]["raw_value"] == -1.5
                @test best_s["objective_breakdown"]["scaled_value"] == -3.0
                @test best_s["objective_breakdown"]["offset_adjusted_value"] == 0.0

                # Metrics section
                met = s_sec["metrics"]
                expected_est = QUBOTools.time_to_target_estimate(sol, 0.0, 0.99; trial_unit = :read)
                @test met["target_threshold"] == 0.0
                @test met["target_probability"] == 0.99
                @test met["trial_unit"] == "read"
                @test met["cost_boundary"] == "effective"
                @test met["trials"] == 10
                @test met["successes"] == 2
                @test met["success_rate"] ≈ 0.2
                @test met["ttt"] ≈ expected_est.ttt
                @test met["time_to_target"]["operational_repetitions"] == expected_est.operational_repetitions
                @test met["time_to_target"]["trial_time"] ≈ 0.1
                @test met["status"] == "empirical_interior_probability"

                # Samples list
                @test length(s_sec["samples"]) == 3
                @test s_sec["samples"][1]["rank"] == 1
                @test s_sec["samples"][1]["state"] == "101"
                @test s_sec["samples"][1]["objective_breakdown"]["offset_adjusted_value"] == 0.0

                # Penalties, reformulation, and feasibility
                @test parsed["reformulation"]["schema_version"] == 1
                @test parsed["penalties"]["constraints"][1]["penalty"] == 12.5
                @test parsed["penalties"]["penalty_policy"]["strategy"] == "exact"
                @test parsed["feasibility"]["result_count"] == 3
                @test parsed["feasibility"]["feasible_count"] == 2
                @test parsed["feasibility"]["max_violation"] == 0.25
            end

            # Threshold without trial_unit reports read/run success rates and status = "trial_unit_required"
            rep_no_unit = QUBOTools.report(model; λ = 0.0)
            @test rep_no_unit["solution"]["metrics"]["status"] == "trial_unit_required"
            @test rep_no_unit["solution"]["metrics"]["read_success_rate"] ≈ 0.2
            @test rep_no_unit["solution"]["metrics"]["run_success_rate"] == 1.0
            @test isnothing(rep_no_unit["solution"]["metrics"]["ttt"])

            # Zero-success threshold serializes Inf TTT fields as null for valid RFC 8259 JSON
            buf = IOBuffer()
            QUBOTools.write_report(buf, model; λ = -100.0, trial_unit = :read, indent = 0)
            zero_parsed = QUBOTools.JSON.parse(String(take!(buf)))
            @test zero_parsed["solution"]["metrics"]["status"] == "empirical_zero_successes"
            @test zero_parsed["solution"]["metrics"]["success_rate"] == 0.0
            @test isnothing(zero_parsed["solution"]["metrics"]["ttt"])
            @test isnothing(zero_parsed["solution"]["metrics"]["time_to_target"]["operational_ttt"])
        end

        @testset "⋅ Models without solutions, empty models, and auto-discovered metadata" begin
            # Unattached solution model with embedded ToQUBO reformulation metadata
            L = Dict{Int,Float64}(1 => 1.0)
            Q = Dict{Tuple{Int,Int},Float64}()
            one_var_model = QUBOTools.Model{Int,Float64,Int}(
                L,
                Q;
                metadata = Dict{String,Any}(
                    "toqubo" => Dict{String,Any}(
                        "reformulation" => Dict{String,Any}(
                            "schema_version" => 1,
                            "applied_penalties" => Dict{String,Any}(
                                "constraints" => [Dict{String,Any}("id" => 7, "penalty" => 5.0)],
                            ),
                        ),
                    ),
                ),
            )

            buf = IOBuffer()
            QUBOTools.write_report(buf, one_var_model)
            parsed = QUBOTools.JSON.parse(String(take!(buf)))

            @test parsed["model"]["dimension"] == 1
            @test parsed["model"]["density"]["total"] == 1.0
            @test parsed["model"]["density"]["linear"] == 1.0
            @test isnothing(parsed["model"]["density"]["quadratic"])
            @test isnothing(parsed["model"]["coefficients"]["linear"]["std"])
            @test parsed["model"]["coefficients"]["quadratic"]["count"] == 0
            @test isnothing(parsed["model"]["coefficients"]["quadratic"]["min"])

            @test parsed["solution"]["present"] == false
            @test parsed["solution"]["sample_count"] == 0
            @test parsed["solution"]["total_reads"] == 0
            @test isnothing(parsed["solution"]["best_sample"])
            @test isnothing(parsed["solution"]["energies"])
            @test parsed["solution"]["metrics"]["status"] == "empty_solution"
            @test parsed["reformulation"]["schema_version"] == 1
            @test parsed["penalties"]["constraints"][1]["penalty"] == 5.0
            @test isnothing(parsed["feasibility"])

            # Empty 0-variable model and solution = nothing override
            empty_model = QUBOTools.Model{Int,Float64,Int}(
                Dict{Int,Float64}(),
                Dict{Tuple{Int,Int},Float64}();
                metadata = Dict{String,Any}("penalties" => Dict{String,Any}("lambda" => 3.5)),
            )
            buf_empty = IOBuffer()
            QUBOTools.write_report(buf_empty, empty_model; solution = nothing, include_samples = true)
            parsed_empty = QUBOTools.JSON.parse(String(take!(buf_empty)))
            @test parsed_empty["model"]["dimension"] == 0
            @test isnothing(parsed_empty["model"]["density"]["total"])
            @test parsed_empty["solution"]["present"] == false
            @test isempty(parsed_empty["solution"]["samples"])
            @test parsed_empty["penalties"]["lambda"] == 3.5

            # Solution without timing metadata and with objective mismatch
            untimed_sol = QUBOTools.SampleSet{Float64,Int}(
                [QUBOTools.Sample([1], 99.0, 4)];
                sense = :min,
                domain = :bool,
            )
            rep_untimed = QUBOTools.report(
                one_var_model;
                solution = untimed_sol,
                λ = 100.0,
                trial_unit = :read,
                penalties = Dict("override" => 42.0),
            )
            @test rep_untimed["solution"]["present"] == true
            @test rep_untimed["solution"]["objective_values_verified"] == false
            @test rep_untimed["solution"]["objective_mismatch_count"] == 1
            @test rep_untimed["solution"]["metrics"]["status"] == "missing_timing_metadata"
            @test rep_untimed["solution"]["metrics"]["success_rate"] == 1.0
            @test isnothing(rep_untimed["solution"]["metrics"]["ttt"])
            @test rep_untimed["penalties"]["override"] == 42.0

            @test_throws ArgumentError QUBOTools.write_report(IOBuffer(), one_var_model; indent = -1)
            @test_throws ArgumentError QUBOTools.report(one_var_model; s = 1.0)
            @test_throws ArgumentError QUBOTools.report(one_var_model; trial_unit = :invalid)
            @test_throws ArgumentError QUBOTools.report(one_var_model; cost_boundary = :invalid)
            @test_throws ArgumentError QUBOTools.report(one_var_model; λ = Inf)

            # R1 regression: integer threshold above 2^53 preserved without Float64 rounding
            λ_large_int = 2^53 + 1
            int_model = QUBOTools.Model{Int,Int,Int}(
                Dict(1 => λ_large_int),
                Dict{Tuple{Int,Int},Int}(),
            )
            int_sol = QUBOTools.SampleSet{Int,Int}(
                [QUBOTools.Sample{Int,Int}([1], λ_large_int, 1)];
                metadata = Dict{String,Any}("time" => Dict{String,Any}("effective" => 1.0)),
            )
            direct_est = QUBOTools.time_to_target_estimate(int_sol, λ_large_int; trial_unit = :read)
            rep_int = QUBOTools.report(int_model; solution = int_sol, λ = λ_large_int, trial_unit = :read)
            int_metrics = rep_int["solution"]["metrics"]
            @test int_metrics["target_threshold"] == λ_large_int
            @test int_metrics["successes"] == direct_est.successes == 1
            @test int_metrics["success_rate"] == direct_est.success_probability == 1.0
            @test int_metrics["ttt"] == direct_est.ttt == 1.0
            @test int_metrics["status"] == String(direct_est.status) == "empirical_all_succeeded"

            buf_int = IOBuffer()
            QUBOTools.write_report(buf_int, int_model; solution = int_sol, λ = λ_large_int, trial_unit = :read)
            parsed_int = QUBOTools.JSON.parse(String(take!(buf_int)))
            @test parsed_int["solution"]["metrics"]["target_threshold"] == λ_large_int
            @test parsed_int["solution"]["metrics"]["successes"] == 1
            @test parsed_int["solution"]["metrics"]["ttt"] == 1.0

            # R2 regression: BigInt model fields and Float64-overflowing finite metadata
            big_val = big(2)^100
            big_model = QUBOTools.Model{Int,BigInt,Int}(
                Dict(1 => big_val),
                Dict{Tuple{Int,Int},BigInt}();
                offset = big_val,
            )
            buf_big = IOBuffer()
            QUBOTools.write_report(buf_big, big_model)
            parsed_big = QUBOTools.JSON.parse(String(take!(buf_big)))
            @test parsed_big["model"]["offset"] == big_val
            @test parsed_big["model"]["coefficients"]["linear"]["min"] == big_val
            @test parsed_big["model"]["coefficients"]["linear"]["max"] == big_val

            overflow_meta_model = QUBOTools.Model{Int,Float64,Int}(
                Dict(1 => 1.0),
                Dict{Tuple{Int,Int},Float64}();
                metadata = Dict{String,Any}("large" => big"1e400"),
            )
            buf_ovf = IOBuffer()
            QUBOTools.write_report(buf_ovf, overflow_meta_model)
            parsed_ovf = QUBOTools.JSON.parse(String(take!(buf_ovf)))
            @test isnothing(parsed_ovf["model"]["metadata"]["large"])

            # Signed typemin magnitude regression (Int8(-128) and typemin(Int64))
            m_int8 = QUBOTools.Model{Int,Int8,Int}(
                Dict(1 => typemin(Int8)),
                Dict{Tuple{Int,Int},Int8}(),
            )
            buf_i8 = IOBuffer()
            QUBOTools.write_report(buf_i8, m_int8; solution = nothing)
            stats_i8 = QUBOTools.JSON.parse(String(take!(buf_i8)))["model"]["coefficients"]["linear"]
            @test stats_i8["min"] == -128
            @test stats_i8["max"] == -128
            @test stats_i8["min_abs"] == 128
            @test stats_i8["max_abs"] == 128

            m_int64 = QUBOTools.Model{Int,Int64,Int}(
                Dict(1 => typemin(Int64)),
                Dict{Tuple{Int,Int},Int64}(),
            )
            buf_i64 = IOBuffer()
            QUBOTools.write_report(buf_i64, m_int64; solution = nothing)
            stats_i64 = QUBOTools.JSON.parse(String(take!(buf_i64)))["model"]["coefficients"]["linear"]
            @test stats_i64["min"] == typemin(Int64)
            @test stats_i64["min_abs"] == -widen(typemin(Int64))
            @test stats_i64["max_abs"] == -widen(typemin(Int64))
        end
    end

    return nothing
end

function test_analysis()
    test_metrics()
    test_plots()
    test_reports()

    return nothing
end
