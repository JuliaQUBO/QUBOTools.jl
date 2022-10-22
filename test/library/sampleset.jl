struct SampleModel{T} end

QUBOTools.energy(::SampleModel{T}, ::Any) where {T} = zero(T)

function test_states()
    B = QUBOTools.BoolDomain
    S = QUBOTools.SpinDomain

    @testset "States" begin
        ψ = [↑, ↓, ↑]
        Ψ = [0, 1, 0]
        ϕ = [↓, ↑, ↓]
        Φ = [1, 0, 1]

        # ~ Short Circuits ~ #
        @test QUBOTools.swap_domain(S, S, ψ) == ψ
        @test QUBOTools.swap_domain(S, S, ϕ) == ϕ
        @test QUBOTools.swap_domain(S, S, Ψ) == Ψ
        @test QUBOTools.swap_domain(S, S, Φ) == Φ
        @test QUBOTools.swap_domain(B, B, ψ) == ψ
        @test QUBOTools.swap_domain(B, B, ϕ) == ϕ
        @test QUBOTools.swap_domain(B, B, Ψ) == Ψ
        @test QUBOTools.swap_domain(B, B, Φ) == Φ

        @test QUBOTools.swap_domain(S, S, [Φ, Ψ]) == [Φ, Ψ]
        @test QUBOTools.swap_domain(S, S, [ϕ, ψ]) == [ϕ, ψ]
        @test QUBOTools.swap_domain(B, B, [Φ, Ψ]) == [Φ, Ψ]
        @test QUBOTools.swap_domain(B, B, [ϕ, ψ]) == [ϕ, ψ]

        # ~ State Conversion ~ #
        @test QUBOTools.swap_domain(B, S, Φ) == ϕ
        @test QUBOTools.swap_domain(B, S, Ψ) == ψ
        @test QUBOTools.swap_domain(S, B, ϕ) == Φ
        @test QUBOTools.swap_domain(S, B, ψ) == Ψ

        # ~ Multiple States Conversion ~ #
        @test QUBOTools.swap_domain(B, S, [Φ, Ψ]) == [ϕ, ψ]
        @test QUBOTools.swap_domain(S, B, [ϕ, ψ]) == [Φ, Ψ]
    end
end

function test_samples()
    @testset "Samples" begin
        let sample = QUBOTools.Sample(Int[], 0.0, 0)
            @test sample isa QUBOTools.Sample{Float64,Int}
        end

        let sample = QUBOTools.Sample{Float64}(Int[], 0.0, 0)
            @test sample isa QUBOTools.Sample{Float64,Int}
        end

        let sample = QUBOTools.Sample{Float64,Int}([0, 0], 0.0, 1)
            @test !isempty(sample)
            @test length(sample) == 2

            @test QUBOTools.Sample{Float64,Int}([0, 0], 0.0, 1) == sample
            @test QUBOTools.Sample{Float64,Int}([1, 1], 0.0, 1) != sample
            @test QUBOTools.Sample{Float64,Int}([0, 0], 0.0, 2) != sample
            @test QUBOTools.Sample{Float64,Int}([0, 0], 1.0, 1) != sample
        end
    end
end

function test_sampleset()
    B = QUBOTools.BoolDomain
    S = QUBOTools.SpinDomain

    @testset "SampleSet" begin
        test_states()
        test_samples()

        let null_set = QUBOTools.SampleSet{Float64,Int}()
            @test isempty(null_set)
            @test length(null_set) == 0
            @test null_set.metadata isa Dict{String,Any}
            @test isempty(null_set.metadata)
        end

        let metadata = Dict{String,Any}("time" => Dict{String,Any}("total" => 1.0))
            meta_set = QUBOTools.SampleSet{Float64,Int}(QUBOTools.Sample{Float64,Int}[], metadata)

            @test meta_set |> isempty
            @test meta_set.metadata isa Dict{String,Any}
            @test meta_set.metadata === metadata
        end

        let sampleset = QUBOTools.SampleSet()
            @test sampleset isa QUBOTools.SampleSet{Float64,Int}
        end

        let sampleset = QUBOTools.SampleSet{Float64}()
            @test sampleset isa QUBOTools.SampleSet{Float64,Int}
        end

        @test_throws QUBOTools.SampleError QUBOTools.SampleSet{Float64,Int}(
            QUBOTools.Sample{Float64,Int}[
                QUBOTools.Sample{Float64,Int}([0, 0], 0.0, 1),
                QUBOTools.Sample{Float64,Int}([0, 0, 1], 0.0, 1),
            ],
        )
        @test_throws QUBOTools.SampleError QUBOTools.SampleSet{Float64,Int}(
            QUBOTools.Sample{Float64,Int}[
                QUBOTools.Sample{Float64,Int}([0, 0], 0.0, 1),
                QUBOTools.Sample{Float64,Int}([0, 0], 0.1, 1),
            ],
        )
        # ~*~ Merge & Sort ~*~#
        source_samples = QUBOTools.Sample{Float64,Int}[
            QUBOTools.Sample{Float64,Int}([0, 0], 0.0, 1),
            QUBOTools.Sample{Float64,Int}([0, 0], 0.0, 2),
            QUBOTools.Sample{Float64,Int}([0, 1], 2.0, 3),
            QUBOTools.Sample{Float64,Int}([0, 1], 2.0, 4),
            QUBOTools.Sample{Float64,Int}([1, 0], 4.0, 5),
            QUBOTools.Sample{Float64,Int}([1, 0], 4.0, 6),
            QUBOTools.Sample{Float64,Int}([1, 1], 1.0, 7),
            QUBOTools.Sample{Float64,Int}([1, 1], 1.0, 8),
        ]

        metadata = Dict{String,Any}(
            "time" => Dict{String,Any}("total" => 10.0),
            "origin" => "quantum",
            "heuristics" =>
                ["presolve", "decomposition", "binary quadratic polytope cuts"],
        )

        target_samples = QUBOTools.Sample{Float64,Int}[
            QUBOTools.Sample{Float64,Int}([0, 0], 0.0,  3),
            QUBOTools.Sample{Float64,Int}([1, 1], 1.0, 15),
            QUBOTools.Sample{Float64,Int}([0, 1], 2.0,  7),
            QUBOTools.Sample{Float64,Int}([1, 0], 4.0, 11),
        ]

        source_sampleset = QUBOTools.SampleSet{Float64,Int}(source_samples, metadata)

        let target_sampleset = QUBOTools.SampleSet{Float64,Int}(target_samples)
            @test source_sampleset == target_sampleset
        end

        let target_sampleset = copy(source_sampleset)
            @test source_sampleset == target_sampleset
            @test target_sampleset.metadata == metadata

            # Ensure metadata was deepcopied
            metadata["origin"] = "monte carlo"

            @test target_sampleset.metadata != metadata
        end

        # ~*~ Model constructor ~*~ #
        let model = SampleModel{Float64}()
            data = Vector{Int}[[0, 0], [0, 1], [1, 0], [1, 1]]
            model_set = QUBOTools.SampleSet{Float64,Int}(model, data)

            @test length(model_set) == length(data)

            for (i, sample) in zip(1:length(model_set), model_set)
                @test sample === model_set[i]
                @test sample isa QUBOTools.Sample{Float64,Int}
                @test sample.reads == 1
                @test sample.value == 0.0

                for j in eachindex(sample.state)
                    @test model_set[i, j] == sample.state[j]
                end
            end
        end

        bool_samples = QUBOTools.Sample{Float64,Int}[
            QUBOTools.Sample{Float64,Int}([0, 0], 4.0, 1),
            QUBOTools.Sample{Float64,Int}([0, 1], 3.0, 2),
            QUBOTools.Sample{Float64,Int}([1, 0], 2.0, 3),
            QUBOTools.Sample{Float64,Int}([1, 1], 1.0, 4),
        ]

        spin_samples = QUBOTools.Sample{Float64,Int}[
            QUBOTools.Sample{Float64,Int}([↑, ↑], 4.0, 1),
            QUBOTools.Sample{Float64,Int}([↑, ↓], 3.0, 2),
            QUBOTools.Sample{Float64,Int}([↓, ↑], 2.0, 3),
            QUBOTools.Sample{Float64,Int}([↓, ↓], 1.0, 4),
        ]

        # ~*~ Domain translation ~*~ #
        let (bool_set, spin_set) = (
                QUBOTools.SampleSet{Float64,Int}(bool_samples),
                QUBOTools.SampleSet{Float64,Int}(spin_samples),
            )

            # ~ state ~ #
            @test QUBOTools.state(bool_set, 1) == [1, 1]
            @test QUBOTools.state(bool_set, 2) == [1, 0]
            @test QUBOTools.state(bool_set, 3) == [0, 1]
            @test QUBOTools.state(bool_set, 4) == [0, 0]

            @test_throws Exception QUBOTools.state(bool_set, 0)
            @test_throws Exception QUBOTools.state(bool_set, 5)

            @test QUBOTools.state(spin_set, 1) == [↓, ↓]
            @test QUBOTools.state(spin_set, 2) == [↓, ↑]
            @test QUBOTools.state(spin_set, 3) == [↑, ↓]
            @test QUBOTools.state(spin_set, 4) == [↑, ↑]

            @test_throws Exception QUBOTools.state(spin_set, 0)
            @test_throws Exception QUBOTools.state(spin_set, 5)

            # ~ reads ~ #
            @test QUBOTools.reads(bool_set) == 10
            @test QUBOTools.reads(spin_set) == 10

            @test QUBOTools.reads(bool_set, 1) == 4
            @test QUBOTools.reads(bool_set, 2) == 3
            @test QUBOTools.reads(bool_set, 3) == 2
            @test QUBOTools.reads(bool_set, 4) == 1

            @test_throws Exception QUBOTools.reads(bool_set, 0)
            @test_throws Exception QUBOTools.reads(bool_set, 5)

            @test QUBOTools.reads(spin_set, 1) == 4
            @test QUBOTools.reads(spin_set, 2) == 3
            @test QUBOTools.reads(spin_set, 3) == 2
            @test QUBOTools.reads(spin_set, 4) == 1

            @test_throws Exception QUBOTools.reads(spin_set, 0)
            @test_throws Exception QUBOTools.reads(spin_set, 5)

            # ~ energy ~ #
            @test QUBOTools.energy(bool_set, 1) == 1.0
            @test QUBOTools.energy(bool_set, 2) == 2.0
            @test QUBOTools.energy(bool_set, 3) == 3.0
            @test QUBOTools.energy(bool_set, 4) == 4.0

            @test_throws Exception QUBOTools.energy(bool_set, 0)
            @test_throws Exception QUBOTools.energy(bool_set, 5)

            @test QUBOTools.energy(spin_set, 1) == 1.0
            @test QUBOTools.energy(spin_set, 2) == 2.0
            @test QUBOTools.energy(spin_set, 3) == 3.0
            @test QUBOTools.energy(spin_set, 4) == 4.0

            @test_throws Exception QUBOTools.energy(spin_set, 0)
            @test_throws Exception QUBOTools.energy(spin_set, 5)

            # ~ swap_domain ~ #
            @test QUBOTools.swap_domain(S, S, bool_set) == bool_set
            @test QUBOTools.swap_domain(S, S, spin_set) == spin_set
            @test QUBOTools.swap_domain(B, B, bool_set) == bool_set
            @test QUBOTools.swap_domain(B, B, spin_set) == spin_set
            @test QUBOTools.swap_domain(B, S, bool_set) == spin_set
            @test QUBOTools.swap_domain(S, B, spin_set) == bool_set
        end
    end
end