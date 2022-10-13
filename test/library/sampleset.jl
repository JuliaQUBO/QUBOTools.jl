struct SampleModel{T} end

QUBOTools.energy(::SampleModel{T}, ::Any) where {T} = zero(T)

function test_sampleset()
    U = Int
    T = Float64
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

    @testset "SampleSet" begin
        let sample = QUBOTools.Sample{U,T}([0, 0], 1, 0.0)
            @test !isempty(sample)
            @test length(sample) == 2

            @test QUBOTools.Sample{U,T}([0, 0], 1, 0.0) == sample
            @test QUBOTools.Sample{U,T}([1, 1], 1, 0.0) != sample
            @test QUBOTools.Sample{U,T}([0, 0], 2, 0.0) != sample
            @test QUBOTools.Sample{U,T}([0, 0], 1, 1.0) != sample
        end

        let null_set = QUBOTools.SampleSet{U,T}()
            @test isempty(null_set)
            @test length(null_set) == 0
            @test null_set.metadata isa Dict{String,Any}
            @test isempty(null_set.metadata)
        end

        let metadata = Dict{String,Any}("time" => Dict{String,Any}("total" => 1.0))
            meta_set = QUBOTools.SampleSet{U,T}(QUBOTools.Sample{U,T}[], metadata)

            @test meta_set |> isempty
            @test meta_set.metadata isa Dict{String,Any}
            @test meta_set.metadata === metadata
        end

        @test_throws QUBOTools.SampleError QUBOTools.SampleSet{U,T}(
            QUBOTools.Sample{U,T}[
                QUBOTools.Sample{U,T}([0, 0], 1, 0.0),
                QUBOTools.Sample{U,T}([0, 0, 1], 1, 0.0),
            ],
        )
        @test_throws QUBOTools.SampleError QUBOTools.SampleSet{U,T}(
            QUBOTools.Sample{U,T}[
                QUBOTools.Sample{U,T}([0, 0], 1, 0.0),
                QUBOTools.Sample{U,T}([0, 0], 1, 0.1),
            ],
        )
        # ~*~ Merge & Sort ~*~#
        source_samples = QUBOTools.Sample{U,T}[
            QUBOTools.Sample{U,T}([0, 0], 1, 0.0),
            QUBOTools.Sample{U,T}([0, 0], 2, 0.0),
            QUBOTools.Sample{U,T}([0, 1], 3, 2.0),
            QUBOTools.Sample{U,T}([0, 1], 4, 2.0),
            QUBOTools.Sample{U,T}([1, 0], 5, 4.0),
            QUBOTools.Sample{U,T}([1, 0], 6, 4.0),
            QUBOTools.Sample{U,T}([1, 1], 7, 1.0),
            QUBOTools.Sample{U,T}([1, 1], 8, 1.0),
        ]

        metadata = Dict{String,Any}(
            "time" => Dict{String,Any}("total" => 10.0),
            "origin" => "quantum",
            "heuristics" =>
                ["presolve", "decomposition", "binary quadratic polytope cuts"],
        )

        target_samples = QUBOTools.Sample{U,T}[
            QUBOTools.Sample{U,T}([0, 0], 3, 0.0),
            QUBOTools.Sample{U,T}([1, 1], 15, 1.0),
            QUBOTools.Sample{U,T}([0, 1], 7, 2.0),
            QUBOTools.Sample{U,T}([1, 0], 11, 4.0),
        ]

        source_sampleset = QUBOTools.SampleSet{U,T}(source_samples, metadata)

        let target_sampleset = QUBOTools.SampleSet{U,T}(target_samples)
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
        let model = SampleModel{T}()
            data = Vector{U}[[0, 0], [0, 1], [1, 0], [1, 1]]
            model_set = QUBOTools.SampleSet{U,T}(model, data)

            @test length(model_set) == length(data)

            for (i, sample) in zip(1:length(model_set), model_set)
                @test sample === model_set[i]
                @test sample isa QUBOTools.Sample{U,T}
                @test sample.reads == 1
                @test sample.value == zero(T)

                for j in eachindex(sample.state)
                    @test model_set[i, j] == sample.state[j]
                end
            end
        end

        bool_samples = QUBOTools.Sample{U,T}[
            QUBOTools.Sample{U,T}([0, 0], 1, 4.0),
            QUBOTools.Sample{U,T}([0, 1], 2, 3.0),
            QUBOTools.Sample{U,T}([1, 0], 3, 2.0),
            QUBOTools.Sample{U,T}([1, 1], 4, 1.0),
        ]

        spin_samples = QUBOTools.Sample{U,T}[
            QUBOTools.Sample{U,T}([↑, ↑], 1, 4.0),
            QUBOTools.Sample{U,T}([↑, ↓], 2, 3.0),
            QUBOTools.Sample{U,T}([↓, ↑], 3, 2.0),
            QUBOTools.Sample{U,T}([↓, ↓], 4, 1.0),
        ]

        # ~*~ Domain translation ~*~ #
        let (bool_set, spin_set) = (
                QUBOTools.SampleSet{U,T}(bool_samples),
                QUBOTools.SampleSet{U,T}(spin_samples),
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