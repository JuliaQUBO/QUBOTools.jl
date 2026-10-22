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

function test_analysis()
    test_metrics()
    test_plots()

    return nothing
end
