struct SampleModel{T} end

QUBOTools.energy(::Any, ::SampleModel{T}) where {T} = zero(T)

function test_sampleset()
    U = Int
    T = Float64

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
                QUBOTools.Sample{U,T}([0, 0, 1], 1, 0.0)
            ]
        )
        @test_throws QUBOTools.SampleError QUBOTools.SampleSet{U,T}(
            QUBOTools.Sample{U,T}[
                QUBOTools.Sample{U,T}([0, 0], 1, 0.0),
                QUBOTools.Sample{U,T}([0, 0], 1, 0.1)
            ]
        )

        let model = SampleModel{T}()
            data = Vector{U}[[0, 0], [0, 1], [1, 0], [1, 1]]
            model_set = QUBOTools.SampleSet{U,T}(
                model,
                data,
            )

            @test length(model_set) == length(data)

            for (i, sample) in zip(1:length(model_set), model_set)
                @test sample === model_set[i]
                @test sample isa QUBOTools.Sample{U,T}
                @test sample.reads == 1
                @test sample.value == zero(T)

                for j = eachindex(sample.state)
                    @test model_set[i, j] == sample.state[j]
                end
            end
        end
    end
end