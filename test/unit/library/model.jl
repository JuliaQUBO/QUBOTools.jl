function test_model(V = Symbol, T = Float64, U = Int)
    @testset "→ Model" verbose = true begin
        L = Dict{V,T}(:x => 0.5, :y => 1.0, :z => 2.0, :w => -0.25, :ξ => 0.0, :γ => 1.0)

        Q = Dict{Tuple{V,V},T}(
            (:x, :x) => 0.5,
            (:x, :y) => 1.0,
            (:x, :z) => 2.0,
            (:x, :w) => 3.0,
            (:z, :y) => -1.0,
            (:w, :z) => -2.0,
            (:γ, :γ) => -1.0,
            (:α, :β) => 0.5,
            (:β, :α) => -0.5,
            (:β, :α) => 0.5,
            (:α, :β) => -0.5,
        )

        model = QUBOTools.Model(
            L,
            Q;
            scale       = 2.0,
            offset      = -1.0,
            sense       = :max,
            domain      = :spin,
            id          = 33,
            description = "A QUBO Model",
            solution    = SampleSet{T,U}(
                [
                    Sample{T,U}([↓, ↑, ↓, ↑, ↓, ↑, ↓, ↑], 4.0, 1),
                    Sample{T,U}([↑, ↓, ↑, ↓, ↑, ↓, ↑, ↓], 3.0, 2),
                    Sample{T,U}([↑, ↓, ↑, ↓, ↓, ↑, ↓, ↑], 2.0, 3),
                    Sample{T,U}([↓, ↑, ↓, ↑, ↑, ↓, ↑, ↓], 1.0, 4),
                ];
                sense  = :max,
                domain = :spin,
            ),
            start      = Dict{V,Int}(
                :w => ↓,
                :x => ↑,
                :y => ↓,
                :z => ↑,
                :α => ↑,
                :β => ↓,
                :γ => ↑,
                :ξ => ↓,
            )
        )

        @testset "⋅ Constructor" begin
            @test model isa QUBOTools.Model{V,T,U}

            let empty_model = QUBOTools.Model{V,T,U}()
                @test isempty(empty_model)
            end
        end

        @testset "⋅ Queries" begin
            @testset "Data access" begin
                @test QUBOTools.dimension(model) == 8

                @test QUBOTools.indices(model)   == collect(1:8)
                @test QUBOTools.variables(model) == [:w, :x, :y, :z, :α, :β, :γ, :ξ]

                @test QUBOTools.hasvariable(model, :u) === false
                @test_throws Exception QUBOTools.index(model, :u)
                @test QUBOTools.hasvariable(model, :w) === true
                @test QUBOTools.index(model, :w) == 1
                @test QUBOTools.hasvariable(model, :x) === true
                @test QUBOTools.index(model, :x) == 2
                @test QUBOTools.hasvariable(model, :y) === true
                @test QUBOTools.index(model, :y) == 3
                @test QUBOTools.hasvariable(model, :δ) === false
                @test_throws Exception QUBOTools.index(model, :δ)

                @test QUBOTools.hasindex(model, 0) === false
                @test_throws Exception QUBOTools.variable(model, 0)
                @test QUBOTools.hasindex(model, 1) === true
                @test QUBOTools.variable(model, 1) == :w
                @test QUBOTools.hasindex(model, 2) === true
                @test QUBOTools.variable(model, 2) == :x
                @test QUBOTools.hasindex(model, 3) === true
                @test QUBOTools.variable(model, 3) == :y
                @test QUBOTools.hasindex(model, 9) === false
                @test_throws Exception QUBOTools.variable(model, 9)

                @test Dict(QUBOTools.linear_terms(model)) == Dict(
                    1 => -0.25,
                    2 => 1.00,
                    3 => 1.00,
                    4 => 2.00,
                )

                @test Dict(QUBOTools.quadratic_terms(model)) == Dict(
                    (1, 2) => 3.0,
                    (1, 4) => -2.0,
                    (2, 3) => 1.0,
                    (2, 4) => 2.0,
                    (3, 4) => -1.0,
                )

                @test QUBOTools.scale(model) == 2.0
                @test QUBOTools.offset(model) == -1.0

                @test QUBOTools.id(model) == 33
                @test QUBOTools.description(model) == "A QUBO Model"

                @test QUBOTools.state(model, 1) == [↓, ↑, ↓, ↑, ↓, ↑, ↓, ↑]
                @test QUBOTools.state(model, 2) == [↑, ↓, ↑, ↓, ↑, ↓, ↑, ↓]
                @test QUBOTools.state(model, 3) == [↑, ↓, ↑, ↓, ↓, ↑, ↓, ↑]
                @test QUBOTools.state(model, 4) == [↓, ↑, ↓, ↑, ↑, ↓, ↑, ↓]

                @test QUBOTools.value(model, 1) == 4.0
                @test QUBOTools.value(model, 2) == 3.0
                @test QUBOTools.value(model, 3) == 2.0
                @test QUBOTools.value(model, 4) == 1.0

                @test QUBOTools.reads(model, 1) == 1
                @test QUBOTools.reads(model, 2) == 2
                @test QUBOTools.reads(model, 3) == 3
                @test QUBOTools.reads(model, 4) == 4

                @test QUBOTools.reads(model) == 10

                @test QUBOTools.start(model; domain = :bool) == Dict{Int,U}(
                    1 => 0,
                    2 => 1,
                    3 => 0,
                    4 => 1,
                    5 => 1,
                    6 => 0,
                    7 => 1,
                    8 => 0,
                )
            end
        end

        model_copy = copy(model)
        
        empty!(model)

        @testset "⋅ Empty" begin
            @test isempty(model)
        end

        copy!(model, model_copy)

        @testset "⋅ Copy" begin
            @test !isempty(model)
            @test !isempty(model_copy)

            @test _compare_models(model, model_copy; compare_solutions = true)
        end
    end

    return nothing
end
