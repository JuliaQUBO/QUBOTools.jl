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
        @test length(spin_sol) == 4
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
        @test QUBOTools.state(spin_sol, 2) == [↑, ↓]
        @test QUBOTools.state(spin_sol, 3) == [↓, ↑]
        @test QUBOTools.state(spin_sol, 4) == [↓, ↓]

        @test_throws Exception QUBOTools.state(spin_sol, 0)
        @test_throws Exception QUBOTools.state(spin_sol, 5)

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

function test_solution()
    @testset "→ Solution" verbose = true begin
        test_solution_states()
        test_solution_samples()
        test_solution_sampleset()
    end

    return nothing
end
