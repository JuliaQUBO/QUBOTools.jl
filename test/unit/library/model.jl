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

        sol = SampleSet{T,U}([
            Sample{T,U}([↑, ↓, ↑, ↓, ↑, ↓, ↑, ↓], 4.0, 1),
            Sample{T,U}([↓, ↑, ↓, ↑, ↓, ↑, ↓, ↑], 3.0, 2),
            Sample{T,U}([↓, ↑, ↓, ↑, ↑, ↓, ↑, ↓], 2.0, 3),
            Sample{T,U}([↑, ↓, ↑, ↓, ↓, ↑, ↓, ↑], 1.0, 4),
        ])

        model = QUBOTools.Model(
            L,
            Q;
            scale       = 2.0,
            offset      = -1.0,
            sense       = :max,
            domain      = :spin,
            id          = 33,
            description = "A QUBO Model",
            solution    = sol,
        )

        @testset "⋅ Constructor" begin
            @test model isa QUBOTools.Model{V,T,U}
        end

        @testset "⋅ Queries" begin
            @testset "Data access" begin
                @test QUBOTools.dimension(model) == 8

                @test QUBOTools.variable_map(model) == Dict{V,Int}(
                    :w => 1,
                    :x => 2,
                    :y => 3,
                    :z => 4,
                    :α => 5,
                    :β => 6,
                    :γ => 7,
                    :ξ => 8,
                )

                @test QUBOTools.variable_inv(model) == [:w, :x, :y, :z, :α, :β, :γ, :ξ]

                @test Dict(QUBOTools.linear_terms(model)) ==
                      Dict(2 => 1.00, 3 => 1.00, 4 => 2.00, 1 => -0.25)

                @test Dict(QUBOTools.quadratic_terms(model)) == Dict(
                    (1, 2) => 3.0,
                    (1, 4) => -2.0,
                    (2, 3) => 1.0,
                    (2, 4) => 2.0,
                    (3, 4) => -1.0,
                )

                @test_throws Exception QUBOTools.variable_map(model, :u)
                @test QUBOTools.variable_map(model, :w) == 1
                @test QUBOTools.variable_map(model, :x) == 2
                @test QUBOTools.variable_map(model, :y) == 3
                @test_throws Exception QUBOTools.variable_map(model, :δ)

                @test_throws Exception QUBOTools.variable_inv(model, 0)
                @test QUBOTools.variable_inv(model, 1) == :w
                @test QUBOTools.variable_inv(model, 2) == :x
                @test QUBOTools.variable_inv(model, 3) == :y
                @test_throws Exception QUBOTools.variable_inv(model, 9)

                @test QUBOTools.variables(model) == [:w, :x, :y, :z, :α, :β, :γ, :ξ]
                @test QUBOTools.variable_set(model) ==
                      Set{V}([:w, :x, :y, :z, :α, :β, :γ, :ξ])

                @test QUBOTools.scale(model) == 2.0
                @test QUBOTools.offset(model) == -1.0

                @test QUBOTools.id(model) == 33
                @test QUBOTools.description(model) == "A QUBO Model"
            end
        end
    end
    return nothing
end
