function test_solution_states()
    @testset "⋅ States" begin
        # ~ Short-Circuit ~ #
        @test QUBOTools.cast((𝕊 => 𝕊), [↓, ↑, ↓]) == [↓, ↑, ↓]
        @test QUBOTools.cast((𝕊 => 𝕊), [↑, ↓, ↑]) == [↑, ↓, ↑]
        @test QUBOTools.cast((𝕊 => 𝕊), [0, 1, 0]) == [0, 1, 0]
        @test QUBOTools.cast((𝕊 => 𝕊), [1, 0, 1]) == [1, 0, 1]
        @test QUBOTools.cast((𝔹 => 𝔹), [↓, ↑, ↓]) == [↓, ↑, ↓]
        @test QUBOTools.cast((𝔹 => 𝔹), [↑, ↓, ↑]) == [↑, ↓, ↑]
        @test QUBOTools.cast((𝔹 => 𝔹), [0, 1, 0]) == [0, 1, 0]
        @test QUBOTools.cast((𝔹 => 𝔹), [1, 0, 1]) == [1, 0, 1]

        # ~ Broadcasting ~ #
        @test QUBOTools.cast.((𝕊 => 𝕊), [[1, 0, 1], [0, 1, 0]]) == [[1, 0, 1], [0, 1, 0]]
        @test QUBOTools.cast.((𝕊 => 𝕊), [[↑, ↓, ↑], [↓, ↑, ↓]]) == [[↑, ↓, ↑], [↓, ↑, ↓]]
        @test QUBOTools.cast.((𝔹 => 𝔹), [[1, 0, 1], [0, 1, 0]]) == [[1, 0, 1], [0, 1, 0]]
        @test QUBOTools.cast.((𝔹 => 𝔹), [[↑, ↓, ↑], [↓, ↑, ↓]]) == [[↑, ↓, ↑], [↓, ↑, ↓]]

        # ~ State Conversion ~ #
        @test QUBOTools.cast((𝔹 => 𝕊), [1, 0, 1]) == [↑, ↓, ↑]
        @test QUBOTools.cast((𝔹 => 𝕊), [0, 1, 0]) == [↓, ↑, ↓]
        @test QUBOTools.cast((𝕊 => 𝔹), [↑, ↓, ↑]) == [1, 0, 1]
        @test QUBOTools.cast((𝕊 => 𝔹), [↓, ↑, ↓]) == [0, 1, 0]

        # ~ Broadcasting ~ #
        @test QUBOTools.cast.((𝔹 => 𝕊), [[1, 0, 1], [0, 1, 0]]) == [[↑, ↓, ↑], [↓, ↑, ↓]]
        @test QUBOTools.cast.((𝕊 => 𝔹), [[↑, ↓, ↑], [↓, ↑, ↓]]) == [[1, 0, 1], [0, 1, 0]]
    end

    return nothing
end

function test_solution_samples()
    @testset "⋅ Samples" begin
        let s = Sample([0, 1], 1.0, 3)
            @test length(s) == 2
            @test QUBOTools.QUBOTools.state(s) == [0, 1]
            @test QUBOTools.QUBOTools.value(s) == 1.0
            @test QUBOTools.QUBOTools.reads(s) == 3

            @test s[1] == 0
            @test s[2] == 1
            @test_throws BoundsError s[0]
            @test_throws BoundsError s[3]

            @test Sample([1, 1], 1.0, 3) != s
            @test Sample([0, 1], 2.0, 3) != s
            @test Sample([0, 1], 1.0, 1) != s
            @test Sample([0, 1], 1.0, 3) == s
        end
    end

    return nothing
end

function test_solution_sampleset()
    @testset "⋅ SampleSet" begin
        let null_sol = SampleSet()
            @test isempty(null_sol)
            @test isempty(QUBOTools.metadata(null_sol))

            # ~ indexing ~ #
            @test length(null_sol) == 0

            @test_throws BoundsError null_sol[begin]
            @test_throws BoundsError null_sol[end]
        end

        let metadata = Dict{String,Any}("time" => Dict{String,Any}("total" => 1.0))
            meta_sol = SampleSet(Sample{Float64,Int}[]; metadata)

            @test isempty(meta_sol)
            
            @test _compare_metadata(QUBOTools.metadata(meta_sol), metadata)
        end

        let sol = SampleSet()
            @test sol isa SampleSet{Float64,Int}
        end

        let sol = SampleSet{Float64}()
            @test sol isa SampleSet{Float64,Int}
        end

        @test_throws Exception SampleSet([
            Sample([0, 0], 0.0, 1),
            Sample([0, 0, 1], 0.0, 1),
        ])
        @test_throws Exception SampleSet([
            Sample([0, 0], 0.0, 1),
            Sample([0, 0], 0.1, 1),
        ])

        # ~*~ Merge & Sort ~*~#
        u = Sample{Float64,Int}[
            Sample([0, 0], 0.0, 1),
            Sample([0, 0], 0.0, 2),
            Sample([0, 1], 2.0, 3),
            Sample([0, 1], 2.0, 4),
            Sample([1, 0], 4.0, 5),
            Sample([1, 0], 4.0, 6),
            Sample([1, 1], 1.0, 7),
            Sample([1, 1], 1.0, 8),
        ]

        v = Sample{Float64,Int}[
            Sample([0, 0], 0.0, 3),
            Sample([1, 1], 1.0, 15),
            Sample([0, 1], 2.0, 7),
            Sample([1, 0], 4.0, 11),
        ]

        metadata = Dict{String,Any}(
            "time"       => Dict{String,Any}("effective" => 9.9, "total" => 10.0),
            "origin"     => "quantum",
            "heuristics" => [
                "presolve",
                "decomposition", 
                "binary quadratic polytope cuts",
            ],
        )

        sol_u = SampleSet(u; metadata)
        sol_v = SampleSet(v)
        sol_w = copy(sol_u)

        @test _compare_solutions(sol_u, sol_v; compare_metadata = false)
        @test _compare_solutions(sol_u, sol_w)
        
        @test _compare_metadata(QUBOTools.metadata(sol_u), metadata)
        @test _compare_metadata(QUBOTools.metadata(sol_w), metadata)

        # Ensure metadata was deepcopied
        metadata["origin"] = "classical monte carlo"

        @test _compare_metadata(QUBOTools.metadata(sol_u), metadata)
        @test !_compare_metadata(QUBOTools.metadata(sol_w), metadata)


        bool_sol = SampleSet(
            Sample{Float64,Int}[
                Sample([0, 0], 4.0, 1),
                Sample([0, 1], 3.0, 2),
                Sample([1, 0], 2.0, 3),
                Sample([1, 1], 1.0, 4),
            ];
            sense  = :min,
            domain = :bool,
        )
        spin_sol = SampleSet{Float64,Int}(
            Sample{Float64,Int}[
                Sample([↓, ↓], -4.0, 1),
                Sample([↓, ↑], -3.0, 2),
                Sample([↑, ↓], -2.0, 3),
                Sample([↑, ↑], -1.0, 4),
            ];
            sense  = :max,
            domain = :spin,
        )

        # ~*~ Domain translation ~*~ #
        @test length(bool_sol) == 4
        @test size(bool_sol) == (4,)
        @test size(bool_sol, 1) == 4
        @test length(spin_sol) == 4
        @test size(spin_sol) == (4,)
        @test size(spin_sol, 1) == 4
        @test QUBOTools.dimension(bool_sol) == 2
        @test QUBOTools.dimension(spin_sol) == 2

        # ~ index ~ #
        @test_throws BoundsError bool_sol[0]
        @test_throws BoundsError bool_sol[5]
        @test bool_sol[begin] === bool_sol[1]
        @test spin_sol[begin] === spin_sol[1]
        @test bool_sol[end]   === bool_sol[4]
        @test spin_sol[end]   === spin_sol[4]
        @test_throws BoundsError spin_sol[0]
        @test_throws BoundsError spin_sol[5]

        # ~ state ~ #
        @test QUBOTools.state(bool_sol, 1) == [1, 1]
        @test QUBOTools.state(bool_sol, 2) == [1, 0]
        @test QUBOTools.state(bool_sol, 3) == [0, 1]
        @test QUBOTools.state(bool_sol, 4) == [0, 0]

        @test_throws Exception QUBOTools.state(bool_sol, 0)
        @test_throws Exception QUBOTools.state(bool_sol, 5)

        @test QUBOTools.state(spin_sol, 1) == [↑, ↑]
        @test_throws Exception QUBOTools.state(spin_sol, 1, 0)
        @test QUBOTools.state(spin_sol, 1, 1) == ↑
        @test QUBOTools.state(spin_sol, 1, 2) == ↑
        @test_throws Exception QUBOTools.state(spin_sol, 1, 3)
        
        @test QUBOTools.state(spin_sol, 2) == [↑, ↓]
        @test_throws Exception QUBOTools.state(spin_sol, 2, 0)
        @test QUBOTools.state(spin_sol, 2, 1) == ↑
        @test QUBOTools.state(spin_sol, 2, 2) == ↓
        @test_throws Exception QUBOTools.state(spin_sol, 2, 3)

        @test QUBOTools.state(spin_sol, 3) == [↓, ↑]
        @test_throws Exception QUBOTools.state(spin_sol, 3, 0)
        @test QUBOTools.state(spin_sol, 3, 1) == ↓
        @test QUBOTools.state(spin_sol, 3, 2) == ↑
        @test_throws Exception QUBOTools.state(spin_sol, 3, 3)

        @test QUBOTools.state(spin_sol, 4) == [↓, ↓]
        @test_throws Exception QUBOTools.state(spin_sol, 4, 0)
        @test QUBOTools.state(spin_sol, 4, 1) == ↓
        @test QUBOTools.state(spin_sol, 4, 2) == ↓
        @test_throws Exception QUBOTools.state(spin_sol, 4, 3)

        @test_throws Exception QUBOTools.state(spin_sol, 0)
        @test_throws Exception QUBOTools.state(spin_sol, 5)

        # Iteration
        for (i, s) in enumerate(spin_sol)
            @test QUBOTools.sample(spin_sol, i) === s
        end

        # ~ reads ~ #
        @test QUBOTools.reads(bool_sol) == 10
        @test QUBOTools.reads(spin_sol) == 10

        @test QUBOTools.reads(bool_sol, 1) == 4
        @test QUBOTools.reads(bool_sol, 2) == 3
        @test QUBOTools.reads(bool_sol, 3) == 2
        @test QUBOTools.reads(bool_sol, 4) == 1

        @test_throws Exception QUBOTools.reads(bool_sol, 0)
        @test_throws Exception QUBOTools.reads(bool_sol, 5)

        @test QUBOTools.reads(spin_sol, 1) == 4
        @test QUBOTools.reads(spin_sol, 2) == 3
        @test QUBOTools.reads(spin_sol, 3) == 2
        @test QUBOTools.reads(spin_sol, 4) == 1

        @test_throws Exception QUBOTools.reads(spin_sol, 0)
        @test_throws Exception QUBOTools.reads(spin_sol, 5)

        # ~ value ~ #
        @test QUBOTools.value(bool_sol, 1) == 1.0
        @test QUBOTools.value(bool_sol, 2) == 2.0
        @test QUBOTools.value(bool_sol, 3) == 3.0
        @test QUBOTools.value(bool_sol, 4) == 4.0

        @test_throws Exception QUBOTools.value(bool_sol, 0)
        @test_throws Exception QUBOTools.value(bool_sol, 5)

        @test QUBOTools.value(spin_sol, 1) == -1.0
        @test QUBOTools.value(spin_sol, 2) == -2.0
        @test QUBOTools.value(spin_sol, 3) == -3.0
        @test QUBOTools.value(spin_sol, 4) == -4.0

        @test_throws Exception QUBOTools.value(spin_sol, 0)
        @test_throws Exception QUBOTools.value(spin_sol, 5)

        # ~ cast ~ #
        @testset "Casting" begin
            @test QUBOTools.cast((𝔹 => 𝔹), bool_sol) === bool_sol
            @test QUBOTools.cast((𝕊 => 𝕊), spin_sol) === spin_sol
            @test _compare_solutions(
                QUBOTools.cast((QUBOTools.Frame(:min, :bool) => QUBOTools.Frame(:max, :spin)), bool_sol),
                spin_sol
            )
            @test _compare_solutions(
                QUBOTools.cast((QUBOTools.Frame(:max, :spin) => QUBOTools.Frame(:min, :bool)), spin_sol),
                bool_sol
            )
        end
    end
end

function test_solution_sampleset_io()
    @testset "⋅ SampleSet Tables & I/O" begin
        metadata = Dict{String,Any}(
            "origin" => "test-solver",
            "time" => Dict{String,Any}("total" => 1.25),
            "model" => Dict{String,Any}(
                "scale" => 2.0,
                "offset" => -1.0,
                "variables" => ["x1", "x2", "x3"],
            ),
        )

        sol = SampleSet{Float64,Int}(
            Sample{Float64,Int}[
                Sample([0, 1, 1], 1.5, 2),
                Sample([1, 0, 0], -2.0, 3),
                Sample([0, 1, 1], 1.5, 4),
            ];
            metadata,
            sense = :min,
            domain = :bool,
        )

        rows = QUBOTools.sampleset_table(sol)

        @test propertynames(first(rows)) == (:rank, :state, :reads, :value, :probability)
        @test rows[1] == (rank = 1, state = "100", reads = 3, value = -2.0, probability = 1 / 3)
        @test rows[2] == (rank = 2, state = "011", reads = 6, value = 1.5, probability = 2 / 3)

        rows_without_probability = QUBOTools.sampleset_table(sol; include_probability = false)

        @test propertynames(first(rows_without_probability)) == (:rank, :state, :reads, :value)

        zero_read_sol = SampleSet{Float64,Int}(
            Sample{Float64,Int}[
                Sample([0, 0], 0.0, 0),
                Sample([1, 1], 1.0, 0),
            ];
            sense = :min,
            domain = :bool,
        )

        @test all(row -> row.probability == 0.0, QUBOTools.sampleset_table(zero_read_sol))

        mktempdir() do dir
            samples_path = joinpath(dir, "samples.csv")

            QUBOTools.write_samples(samples_path, sol)

            samples_text = read(samples_path, String)

            @test occursin("# QUBOTools.samples.metadata=", samples_text)
            @test occursin("rank,state,reads,value,probability", samples_text)

            dst = QUBOTools.read_samples(samples_path)

            @test _compare_solutions(sol, dst)

            samples_without_probability_path = joinpath(dir, "samples-without-probability.csv")

            QUBOTools.write_samples(
                samples_without_probability_path,
                sol;
                include_probability = false,
            )

            @test occursin("rank,state,reads,value\n", read(samples_without_probability_path, String))

            spin_sol = SampleSet{Float64,Int}(
                Sample{Float64,Int}[
                    Sample([↑, ↑, ↑], -4.0, 2),
                    Sample([↓, ↑, ↓], -3.0, 5),
                    Sample([↑, ↓, ↑], -1.0, 7),
                ];
                metadata = Dict{String,Any}("origin" => "spin-solver"),
                sense = :max,
                domain = :spin,
            )

            spin_samples_path = joinpath(dir, "spin-samples.csv")
            spin_metadata_path = joinpath(dir, "spin-samples.json")

            QUBOTools.write_samples(
                spin_samples_path,
                spin_sol;
                metadata_path = spin_metadata_path,
                bit_order = :reverse,
            )

            spin_samples_text = read(spin_samples_path, String)
            spin_metadata_text = read(spin_metadata_path, String)

            @test !startswith(spin_samples_text, "#")
            @test occursin("1 1 1", spin_samples_text)
            @test occursin("\"domain\": \"spin\"", spin_metadata_text)

            spin_dst = QUBOTools.read_samples(
                spin_samples_path;
                metadata_path = spin_metadata_path,
            )

            @test _compare_solutions(spin_sol, spin_dst)

            spin_dst_with_explicit_native = QUBOTools.read_samples(
                spin_samples_path;
                metadata_path = spin_metadata_path,
                bit_order = :native,
            )

            @test _compare_solutions(spin_sol, spin_dst_with_explicit_native)

            model = QUBOTools.Model(
                Dict(:x1 => 1.0, :x2 => 0.0, :x3 => -1.0),
                Dict{Tuple{Symbol,Symbol},Float64}();
                scale = 2.0,
                offset = -1.0,
            )

            QUBOTools.attach!(model, sol)

            model_samples_path = joinpath(dir, "model-samples.csv")
            model_metadata_path = joinpath(dir, "model-samples.json")

            QUBOTools.write_samples(
                model_samples_path,
                model;
                metadata_path = model_metadata_path,
            )

            model_metadata_text = read(model_metadata_path, String)

            @test occursin("\"scale\": 2.0", model_metadata_text)
            @test occursin("\"offset\": -1.0", model_metadata_text)
            @test occursin("\"variables\":", model_metadata_text)
            @test occursin("\"x1\"", model_metadata_text)
            @test _compare_solutions(
                sol,
                QUBOTools.read_samples(model_samples_path; metadata_path = model_metadata_path),
            )

            duplicate_samples_path = joinpath(dir, "duplicate-samples.csv")

            open(duplicate_samples_path, "w") do io
                println(io, "rank,state,reads,value,probability")
                println(io, "1,01,2,1.0,0.4")
                println(io, "2,01,3,1.0,0.6")
            end

            duplicate_dst = QUBOTools.read_samples(duplicate_samples_path)

            @test length(duplicate_dst) == 1
            @test QUBOTools.state(duplicate_dst, 1) == [0, 1]
            @test QUBOTools.value(duplicate_dst, 1) == 1.0
            @test QUBOTools.reads(duplicate_dst, 1) == 5
        end
    end

    return nothing
end

function test_solution_objectives()
    @testset "⋅ Objective Bookkeeping" begin
        L = [1.0, -2.0, 0.5]
        Q = [
            0.0 3.0 0.0
            0.0 0.0 -1.0
            0.0 0.0 0.0
        ]
        state = [1, 1, 0]

        dense_form = QUBOTools.DenseForm{Float64}(
            3,
            L,
            Q,
            2.0,
            -1.5;
            sense = :min,
            domain = :bool,
        )
        sparse_form = QUBOTools.SparseForm{Float64}(
            3,
            sparse(L),
            sparse(Q),
            2.0,
            -1.5;
            sense = :min,
            domain = :bool,
        )

        dense_breakdown = QUBOTools.objective_breakdown(dense_form, state)
        sparse_breakdown = QUBOTools.objective_breakdown(sparse_form, state)

        @test dense_breakdown.raw_value == 2.0
        @test dense_breakdown.scaled_value == 4.0
        @test dense_breakdown.offset_adjusted_value == 1.0
        @test QUBOTools.value(dense_breakdown) == 1.0
        @test dense_breakdown.sense === QUBOTools.Min
        @test dense_breakdown.domain === QUBOTools.BoolDomain
        @test sparse_breakdown.raw_value == dense_breakdown.raw_value
        @test sparse_breakdown.offset_adjusted_value == dense_breakdown.offset_adjusted_value

        spin_model = QUBOTools.Model(
            Dict(:a => 1.0, :b => -2.0),
            Dict((:a, :b) => 0.5);
            scale = 0.5,
            offset = 2.0,
            sense = :max,
            domain = :spin,
        )
        spin_breakdown = QUBOTools.objective_breakdown(
            spin_model,
            Dict(:a => ↑, :b => ↓),
        )

        @test spin_breakdown.raw_value == 2.5
        @test spin_breakdown.scaled_value == 1.25
        @test spin_breakdown.offset_adjusted_value == 2.25
        @test spin_breakdown.sense === QUBOTools.Max
        @test spin_breakdown.domain === QUBOTools.SpinDomain

        model = QUBOTools.Model(
            Dict(:x => 1.0, :y => -2.0, :z => 0.5),
            Dict((:x, :y) => 3.0, (:y, :z) => -1.0);
            scale = 2.0,
            offset = -1.5,
            sense = :min,
            domain = :bool,
        )

        projected_breakdown = QUBOTools.objective_breakdown(
            model,
            [0, 1, 1, 0];
            variables = [:aux, :x, :y, :z],
        )

        @test projected_breakdown.state == state
        @test projected_breakdown.offset_adjusted_value == 1.0

        sample_breakdown = QUBOTools.objective_breakdown(
            model,
            Sample{Float64,Int}([1, 1, 0], 1.0, 1),
        )

        @test sample_breakdown.state == state
        @test sample_breakdown.offset_adjusted_value == 1.0

        sol = SampleSet{Float64,Int}(
            Sample{Float64,Int}[
                Sample([1, 1, 0], 1.0, 2),
                Sample([0, 0, 0], -3.0, 1),
            ];
            sense = :min,
            domain = :bool,
        )

        QUBOTools.attach!(model, sol)

        indexed_breakdown = QUBOTools.objective_breakdown(model, 2)

        @test indexed_breakdown.state == state
        @test indexed_breakdown.offset_adjusted_value == 1.0

        rows = QUBOTools.annotate_objectives!(sol, model; label = :qubo)

        @test length(rows) == 2
        @test rows[1].offset_adjusted_value == -3.0
        @test rows[2].offset_adjusted_value == 1.0
        @test haskey(QUBOTools.metadata(sol), "objectives")
        @test QUBOTools.metadata(sol)["objectives"]["qubo"][2]["raw_value"] == 2.0
        @test QUBOTools.verify_objective_values(model, sol)

        flipped_sol = SampleSet{Float64,Int}(
            Sample{Float64,Int}[
                Sample([↑, ↑, ↓], -1.0, 1),
            ];
            sense = :max,
            domain = :spin,
        )

        @test_throws QUBOTools.SolutionError QUBOTools.objective_breakdown(
            model,
            Sample{Float64,Int}([↑, ↑, ↓], -1.0, 1),
        )
        @test QUBOTools.verify_objective_values(model, flipped_sol)

        flipped_rows = QUBOTools.annotate_objectives!(flipped_sol, model; label = :cast)

        @test flipped_rows[1].state == [1, 1, 0]
        @test QUBOTools.metadata(flipped_sol)["objectives"]["cast"][1]["state"] == [1, 1, 0]

        bad_sol = SampleSet{Float64,Int}(
            Sample{Float64,Int}[
                Sample([1, 1, 0], 1.25, 1),
            ];
            sense = :min,
            domain = :bool,
        )
        mismatches = QUBOTools.objective_value_mismatches(model, bad_sol; atol = 1e-9)

        @test !QUBOTools.verify_objective_values(model, bad_sol; atol = 1e-9)
        @test length(mismatches) == 1
        @test mismatches[1].index == 1
        @test mismatches[1].stored_value == 1.25
        @test mismatches[1].evaluated_value == 1.0
        @test mismatches[1].difference == 0.25

        @test_throws QUBOTools.SolutionError QUBOTools.objective_breakdown(model, [2, 1, 0])
        @test_throws QUBOTools.SolutionError QUBOTools.objective_breakdown(
            model,
            [1, 0];
            variables = [:x, :y],
        )
    end

    return nothing
end

function test_solution()
    @testset "→ Solution" verbose = true begin
        test_solution_states()
        test_solution_samples()
        test_solution_sampleset()
        test_solution_sampleset_io()
        test_solution_objectives()
    end

    return nothing
end
