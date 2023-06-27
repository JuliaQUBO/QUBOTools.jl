function test_model_constructors(V = Symbol, T = Float64, U = Int)
    L = Dict{V,T}(
        :x => 0.5,
        :y => 1.0,
        :z => 2.0,
        :w => -0.25,
        :ξ => 0.0,
        :γ => 1.0,
    )

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

    @testset "Constructors" begin
        model = QUBOTools.Model(
            L, Q;
            scale  = 2.0,
            offset = -1.0,
            sense  = :max,
            domain = :spin,
        )

        @test model isa QUBOTools.Model{V,T,U}

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

        @test QUBOTools.variable_inv(model) == [
            :w,
            :x,
            :y,
            :z,
            :α,
            :β,
            :γ,
            :ξ,
        ]

        @test Dict(QUBOTools.linear_terms(model)) == Dict(
            2 =>  1.00,
            3 =>  1.00,
            4 =>  2.00,
            1 => -0.25,
        )

        @test Dict(QUBOTools.quadratic_terms(model)) == Dict(
            (1, 2) =>  3.0,
            (1, 4) => -2.0,
            (2, 3) =>  1.0,
            (2, 4) =>  2.0,
            (3, 4) => -1.0,
        )
    end

    return nothing
end

function test_model()
    @testset "→ Model" begin
        test_model_constructors()
    end

    return nothing
end
