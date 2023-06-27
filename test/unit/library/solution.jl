function test_solution_states()
    @testset "States" begin
        # ~ Short-Circuit ~ #
        @test QUBOTools.cast(𝕊 => 𝕊, [↑, ↓, ↑]) == [↑, ↓, ↑]
        @test QUBOTools.cast(𝕊 => 𝕊, [↓, ↑, ↓]) == [↓, ↑, ↓]
        @test QUBOTools.cast(𝕊 => 𝕊, [0, 1, 0]) == [0, 1, 0]
        @test QUBOTools.cast(𝕊 => 𝕊, [1, 0, 1]) == [1, 0, 1]
        @test QUBOTools.cast(𝔹 => 𝔹, [↑, ↓, ↑]) == [↑, ↓, ↑]
        @test QUBOTools.cast(𝔹 => 𝔹, [↓, ↑, ↓]) == [↓, ↑, ↓]
        @test QUBOTools.cast(𝔹 => 𝔹, [0, 1, 0]) == [0, 1, 0]
        @test QUBOTools.cast(𝔹 => 𝔹, [1, 0, 1]) == [1, 0, 1]

        # ~ Broadcasting ~ #
        @test QUBOTools.cast.(𝕊 => 𝕊, [[1, 0, 1], [0, 1, 0]]) == [[1, 0, 1], [0, 1, 0]]
        @test QUBOTools.cast.(𝕊 => 𝕊, [[↓, ↑, ↓], [↑, ↓, ↑]]) == [[↓, ↑, ↓], [↑, ↓, ↑]]
        @test QUBOTools.cast.(𝔹 => 𝔹, [[1, 0, 1], [0, 1, 0]]) == [[1, 0, 1], [0, 1, 0]]
        @test QUBOTools.cast.(𝔹 => 𝔹, [[↓, ↑, ↓], [↑, ↓, ↑]]) == [[↓, ↑, ↓], [↑, ↓, ↑]]

        # ~ State Conversion ~ #
        @test QUBOTools.cast(𝔹 => 𝕊, [1, 0, 1]) == [↓, ↑, ↓]
        @test QUBOTools.cast(𝔹 => 𝕊, [0, 1, 0]) == [↑, ↓, ↑]
        @test QUBOTools.cast(𝕊 => 𝔹, [↓, ↑, ↓]) == [1, 0, 1]
        @test QUBOTools.cast(𝕊 => 𝔹, [↑, ↓, ↑]) == [0, 1, 0]

        # ~ Broadcasting ~ #
        @test QUBOTools.cast.(𝔹 => 𝕊, [[1, 0, 1], [0, 1, 0]]) == [[↓, ↑, ↓], [↑, ↓, ↑]]
        @test QUBOTools.cast.(𝕊 => 𝔹, [[↓, ↑, ↓], [↑, ↓, ↑]]) == [[1, 0, 1], [0, 1, 0]]
    end

    return nothing
end

function test_solution_samples()
    @testset "Samples" begin
        let s = Sample([0, 1], 1.0, 3)
            @test length(s) == 2
            @test QUBOTools.state(s) == [0, 1]
            @test QUBOTools.value(s) == 1.0
            @test QUBOTools.reads(s) == 3

            @test s[1] == 0
            @test s[2] == 1
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
    @testset "SampleSet" begin
        let null_set = SampleSet()
            @test isempty(null_set)
            @test isempty(null_set.metadata)
            
            # ~ index ~ #
            @test size(null_set) == (0,)
            @test size(null_set, 1) == length(null_set) == 0
            @test size(null_set, 2) == 1

            @test_throws BoundsError null_set[begin]
            @test_throws BoundsError null_set[end]
        end

        let metadata = Dict{String,Any}("time" => Dict{String,Any}("total" => 1.0))
            meta_set = SampleSet(Sample{Float64,Int}[], metadata)

            @test isempty(meta_set)
            @test meta_set.metadata === metadata
        end

        let ω = SampleSet()
            @test ω isa SampleSet{Float64,Int}
        end

        let ω = SampleSet{Float64}()
            @test ω isa SampleSet{Float64,Int}
        end

        @test_throws SolutionError SampleSet(
            [
                Sample([0, 0],    0.0, 1),
                Sample([0, 0, 1], 0.0, 1),
            ],
        )
        @test_throws SolutionError SampleSet(
            [
                Sample([0, 0], 0.0, 1),
                Sample([0, 0], 0.1, 1),
            ],
        )
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
            Sample([0, 0], 0.0,  3),
            Sample([1, 1], 1.0, 15),
            Sample([0, 1], 2.0,  7),
            Sample([1, 0], 4.0, 11),
        ]

        metadata = Dict{String,Any}(
            "time" => Dict{String,Any}("total" => 10.0),
            "origin" => "quantum",
            "heuristics" =>
                ["presolve", "decomposition", "binary quadratic polytope cuts"],
        )

        ω = SampleSet(u, metadata)
        η = SampleSet(v)

        @test ω == η

        let θ = copy(ω)
            @test θ == ω
            @test QUBOTools.metadata(ω) == metadata

            # Ensure metadata was deepcopied
            metadata["origin"] = "monte carlo"

            @test QUBOTools.metadata(ω) == metadata
            @test QUBOTools.metadata(θ) != metadata
        end

        # ~*~ Model constructor ~*~ #
        let model = SampleModel{Float64}()
            data = Vector{Int}[[0, 0], [0, 1], [1, 0], [1, 1]]
            model_set = SampleSet{Float64,Int}(model, data)

            @test length(model_set) == length(data)

            for (i, s) in zip(1:length(model_set), model_set)
                @test s === model_set[i]
                @test s isa Sample{Float64,Int}
                @test reads(s) == s.reads == 1
                @test value(s) == s.value == 0.0

                for j in eachindex(s.state)
                    @test model_set[i][j] == s.state[j]
                end
            end
        end

        bool_ω = Sample{Float64,Int}[
            Sample([0, 0], 4.0, 1),
            Sample([0, 1], 3.0, 2),
            Sample([1, 0], 2.0, 3),
            Sample([1, 1], 1.0, 4),
        ]

        spin_ω = Sample{Float64,Int}[
            Sample([↑, ↑], 4.0, 1),
            Sample([↑, ↓], 3.0, 2),
            Sample([↓, ↑], 2.0, 3),
            Sample([↓, ↓], 1.0, 4),
        ]

        # ~*~ Domain translation ~*~ #
        let (bool_set, spin_set) = (
                SampleSet(bool_ω),
                SampleSet(spin_ω),
            )
            # ~ index ~ #
            @test size(bool_set) == (4,)
            @test size(spin_set) == (4,)
            @test size(bool_set, 1) == length(bool_set) == 4
            @test size(spin_set, 1) == length(spin_set) == 4
            @test size(bool_set, 2) == 1
            @test size(spin_set, 2) == 1
            @test bool_set[begin] === bool_set[1]
            @test spin_set[begin] === spin_set[1]
            @test bool_set[end]   === bool_set[4]
            @test spin_set[end]   === spin_set[4]

            # ~ state ~ #
            @test state(bool_set, 1) == [1, 1]
            @test state(bool_set, 2) == [1, 0]
            @test state(bool_set, 3) == [0, 1]
            @test state(bool_set, 4) == [0, 0]

            @test_throws Exception state(bool_set, 0)
            @test_throws Exception state(bool_set, 5)

            @test state(spin_set, 1) == [↓, ↓]
            @test state(spin_set, 2) == [↓, ↑]
            @test state(spin_set, 3) == [↑, ↓]
            @test state(spin_set, 4) == [↑, ↑]

            @test_throws Exception state(spin_set, 0)
            @test_throws Exception state(spin_set, 5)

            # ~ reads ~ #
            @test reads(bool_set) == 10
            @test reads(spin_set) == 10

            @test reads(bool_set, 1) == 4
            @test reads(bool_set, 2) == 3
            @test reads(bool_set, 3) == 2
            @test reads(bool_set, 4) == 1

            @test_throws Exception reads(bool_set, 0)
            @test_throws Exception reads(bool_set, 5)

            @test reads(spin_set, 1) == 4
            @test reads(spin_set, 2) == 3
            @test reads(spin_set, 3) == 2
            @test reads(spin_set, 4) == 1

            @test_throws Exception reads(spin_set, 0)
            @test_throws Exception reads(spin_set, 5)

            # ~ value ~ #
            @test value(bool_set, 1) == 1.0
            @test value(bool_set, 2) == 2.0
            @test value(bool_set, 3) == 3.0
            @test value(bool_set, 4) == 4.0

            @test_throws Exception value(bool_set, 0)
            @test_throws Exception value(bool_set, 5)

            @test value(spin_set, 1) == 1.0
            @test value(spin_set, 2) == 2.0
            @test value(spin_set, 3) == 3.0
            @test value(spin_set, 4) == 4.0

            @test_throws Exception value(spin_set, 0)
            @test_throws Exception value(spin_set, 5)

            # ~ cast ~ #
            @test cast(𝕊 => 𝕊, bool_set) == bool_set
            @test cast(𝔹 => 𝔹, bool_set) == bool_set
            @test cast(𝕊 => 𝕊, spin_set) == spin_set
            @test cast(𝔹 => 𝔹, spin_set) == spin_set
            @test cast(𝔹 => 𝕊, bool_set) == spin_set
            @test cast(𝕊 => 𝔹, spin_set) == bool_set
        end
    end
end

function test_solution()
    @testset "→ Solution" begin
        test_solution_states()
        test_solution_samples()
    end

    return nothing
end
