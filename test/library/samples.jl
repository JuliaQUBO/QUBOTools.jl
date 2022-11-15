struct SampleModel{T} end
struct QUBOModel{T} <: QUBOTools.AbstractQUBOModel{T} end

QUBOTools.value(::SampleModel{T}, ::Any) where {T} = zero(T)

function test_samples()
    @testset "States" begin
        ψ = [↑, ↓, ↑]
        Ψ = [0, 1, 0]
        ϕ = [↓, ↑, ↓]
        Φ = [1, 0, 1]

        # ~ Short Circuits ~ #
        @test QUBOTools.swap_domain(QUBOTools.𝕊(), QUBOTools.𝕊(), ψ) == ψ
        @test QUBOTools.swap_domain(QUBOTools.𝕊(), QUBOTools.𝕊(), ϕ) == ϕ
        @test QUBOTools.swap_domain(QUBOTools.𝕊(), QUBOTools.𝕊(), Ψ) == Ψ
        @test QUBOTools.swap_domain(QUBOTools.𝕊(), QUBOTools.𝕊(), Φ) == Φ
        @test QUBOTools.swap_domain(QUBOTools.𝔹(), QUBOTools.𝔹(), ψ) == ψ
        @test QUBOTools.swap_domain(QUBOTools.𝔹(), QUBOTools.𝔹(), ϕ) == ϕ
        @test QUBOTools.swap_domain(QUBOTools.𝔹(), QUBOTools.𝔹(), Ψ) == Ψ
        @test QUBOTools.swap_domain(QUBOTools.𝔹(), QUBOTools.𝔹(), Φ) == Φ

        @test QUBOTools.swap_domain(QUBOTools.𝕊(), QUBOTools.𝕊(), [Φ, Ψ]) == [Φ, Ψ]
        @test QUBOTools.swap_domain(QUBOTools.𝕊(), QUBOTools.𝕊(), [ϕ, ψ]) == [ϕ, ψ]
        @test QUBOTools.swap_domain(QUBOTools.𝔹(), QUBOTools.𝔹(), [Φ, Ψ]) == [Φ, Ψ]
        @test QUBOTools.swap_domain(QUBOTools.𝔹(), QUBOTools.𝔹(), [ϕ, ψ]) == [ϕ, ψ]

        # ~ State Conversion ~ #
        @test QUBOTools.swap_domain(QUBOTools.𝔹(), QUBOTools.𝕊(), Φ) == ϕ
        @test QUBOTools.swap_domain(QUBOTools.𝔹(), QUBOTools.𝕊(), Ψ) == ψ
        @test QUBOTools.swap_domain(QUBOTools.𝕊(), QUBOTools.𝔹(), ϕ) == Φ
        @test QUBOTools.swap_domain(QUBOTools.𝕊(), QUBOTools.𝔹(), ψ) == Ψ

        # ~ Multiple States Conversion ~ #
        @test QUBOTools.swap_domain(QUBOTools.𝔹(), QUBOTools.𝕊(), [Φ, Ψ]) == [ϕ, ψ]
        @test QUBOTools.swap_domain(QUBOTools.𝕊(), QUBOTools.𝔹(), [ϕ, ψ]) == [Φ, Ψ]
    end

    @testset "Samples" begin
        let sample = QUBOTools.Sample(Int[], 0.0, 0)
            @test sample isa QUBOTools.Sample{Float64,Int}
        end

        let sample = QUBOTools.Sample{Float64}(Int[], 0.0, 0)
            @test sample isa QUBOTools.Sample{Float64,Int}
        end

        let sample = QUBOTools.Sample([0, 1], -1.0, 1)
            @test length(sample) == 2

            @test sample[1] == 0
            @test sample[2] == 1
            @test_throws BoundsError sample[3] 

            @test QUBOTools.Sample([0, 1], -1.0, 1) == sample
            @test QUBOTools.Sample([1, 1], 0.0, 1) != sample
            @test QUBOTools.Sample([0, 1], 0.0, 2) == sample
            @test QUBOTools.Sample([0, 1], 1.0, 1) == sample

            @test sample < QUBOTools.Sample([0, 0], 1.0, 1)
            @test isequal(sample, QUBOTools.Sample([0, 1], -1.0, 1))
            @test !isequal(sample, QUBOTools.Sample([0, 0], 0.0, 2))
            @test !isequal(sample, QUBOTools.Sample([0, 0], 1.0, 1))

            let io = IOBuffer()
                print(io, sample)
                @test String(take!(io)) == "↑↓"
            end
        end
    end

    @testset "SampleSet" begin
        let null_set = QUBOTools.SampleSet()
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
            meta_set = QUBOTools.SampleSet(QUBOTools.Sample{Float64,Int}[], metadata)

            @test isempty(meta_set)
            @test meta_set.metadata === metadata
        end

        let sampleset = QUBOTools.SampleSet()
            @test sampleset isa QUBOTools.SampleSet{Float64,Int}
        end

        let sampleset = QUBOTools.SampleSet{Float64}()
            @test sampleset isa QUBOTools.SampleSet{Float64,Int}
        end

        @test_throws QUBOTools.SampleError QUBOTools.SampleSet{Float64,Int}(
            [
                QUBOTools.Sample([0, 0],    0.0, 1),
                QUBOTools.Sample([0, 0, 1], 0.0, 1),
            ],
        )
        @test_throws QUBOTools.SampleError QUBOTools.SampleSet(
            [
                QUBOTools.Sample([0, 0], 0.0, 1),
                QUBOTools.Sample([0, 0], 0.1, 1),
            ],
        )
        # ~*~ Merge & Sort ~*~#
        source_samples = QUBOTools.Sample{Float64,Int}[
            QUBOTools.Sample([0, 0], 0.0, 1),
            QUBOTools.Sample([0, 0], 0.0, 2),
            QUBOTools.Sample([0, 1], 2.0, 3),
            QUBOTools.Sample([0, 1], 2.0, 4),
            QUBOTools.Sample([1, 0], 4.0, 5),
            QUBOTools.Sample([1, 0], 4.0, 6),
            QUBOTools.Sample([1, 1], 1.0, 7),
            QUBOTools.Sample([1, 1], 1.0, 8),
        ]

        metadata = Dict{String,Any}(
            "time" => Dict{String,Any}("total" => 10.0),
            "origin" => "quantum",
            "heuristics" =>
                ["presolve", "decomposition", "binary quadratic polytope cuts"],
        )

        target_samples = QUBOTools.Sample{Float64,Int}[
            QUBOTools.Sample([0, 0], 0.0,  3),
            QUBOTools.Sample([1, 1], 1.0, 15),
            QUBOTools.Sample([0, 1], 2.0,  7),
            QUBOTools.Sample([1, 0], 4.0, 11),
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
                @test QUBOTools.reads(sample) == sample.reads == 1
                @test QUBOTools.value(sample) == sample.value == 0.0

                for j in eachindex(sample.state)
                    @test model_set[i][j] == sample.state[j]
                end
            end
        end

        bool_samples = QUBOTools.Sample{Float64,Int}[
            QUBOTools.Sample([0, 0], 4.0, 1),
            QUBOTools.Sample([0, 1], 3.0, 2),
            QUBOTools.Sample([1, 0], 2.0, 3),
            QUBOTools.Sample([1, 1], 1.0, 4),
        ]

        spin_samples = QUBOTools.Sample{Float64,Int}[
            QUBOTools.Sample([↑, ↑], 4.0, 1),
            QUBOTools.Sample([↑, ↓], 3.0, 2),
            QUBOTools.Sample([↓, ↑], 2.0, 3),
            QUBOTools.Sample([↓, ↓], 1.0, 4),
        ]

        # ~*~ Domain translation ~*~ #
        let (bool_set, spin_set) = (
                QUBOTools.SampleSet(bool_samples),
                QUBOTools.SampleSet(spin_samples),
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

            # ~ value ~ #
            @test QUBOTools.value(bool_set, 1) == 1.0
            @test QUBOTools.value(bool_set, 2) == 2.0
            @test QUBOTools.value(bool_set, 3) == 3.0
            @test QUBOTools.value(bool_set, 4) == 4.0

            @test_throws Exception QUBOTools.value(bool_set, 0)
            @test_throws Exception QUBOTools.value(bool_set, 5)

            @test QUBOTools.value(spin_set, 1) == 1.0
            @test QUBOTools.value(spin_set, 2) == 2.0
            @test QUBOTools.value(spin_set, 3) == 3.0
            @test QUBOTools.value(spin_set, 4) == 4.0

            @test_throws Exception QUBOTools.value(spin_set, 0)
            @test_throws Exception QUBOTools.value(spin_set, 5)

            # ~ swap_domain ~ #
            @test QUBOTools.swap_domain(QUBOTools.𝕊(), QUBOTools.𝕊(), bool_set) == bool_set
            @test QUBOTools.swap_domain(QUBOTools.𝔹(), QUBOTools.𝔹(), bool_set) == bool_set
            @test QUBOTools.swap_domain(QUBOTools.𝕊(), QUBOTools.𝕊(), spin_set) == spin_set
            @test QUBOTools.swap_domain(QUBOTools.𝔹(), QUBOTools.𝔹(), spin_set) == spin_set
            @test QUBOTools.swap_domain(QUBOTools.𝔹(), QUBOTools.𝕊(), bool_set) == spin_set
            @test QUBOTools.swap_domain(QUBOTools.𝕊(), QUBOTools.𝔹(), spin_set) == bool_set
        end
    end
end