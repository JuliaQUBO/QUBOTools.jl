function test_cast()
    @testset "Casting" begin
        L̄ = Dict{Int,Float64}(1 => 10, 2 => 11, 3 => 12)
        L = Dict{Int,Float64}(1 => -10, 2 => -11, 3 => -12)

        @test cast(Min, Min, L̄) == L̄
        @test cast(Max, Max, L̄) == L̄
        @test cast(Min, Min, L) == L
        @test cast(Max, Max, L) == L
        @test cast(Min, Max, L̄) == L
        @test cast(Max, Min, L̄) == L
        @test cast(Min, Max, L) == L̄
        @test cast(Max, Min, L) == L̄

        Q̄ = Dict{Tuple{Int,Int},Float64}((1, 1) => 1.0, (2, 2) => 2.0, (3, 3) => 3.0)
        Q = Dict{Tuple{Int,Int},Float64}((1, 1) => -1.0, (2, 2) => -2.0, (3, 3) => -3.0)

        @test cast(Min, Min, Q̄) == Q̄
        @test cast(Max, Max, Q̄) == Q̄
        @test cast(Min, Min, Q) == Q
        @test cast(Max, Max, Q) == Q
        @test cast(Min, Max, Q̄) == Q
        @test cast(Max, Min, Q̄) == Q
        @test cast(Min, Max, Q) == Q̄
        @test cast(Max, Min, Q) == Q̄

        ᾱ = 1.0
        α = 1.0

        β̄ = 1.0
        β = -1.0

        @test cast(Min, Min, L̄, Q̄, ᾱ, β̄) == (L̄, Q̄, ᾱ, β̄)
        @test cast(Max, Max, L̄, Q̄, ᾱ, β̄) == (L̄, Q̄, ᾱ, β̄)
        @test cast(Min, Min, L, Q, α, β) == (L, Q, α, β)
        @test cast(Max, Max, L, Q, α, β) == (L, Q, α, β)
        @test cast(Min, Max, L̄, Q̄, ᾱ, β̄) == (L, Q, α, β)
        @test cast(Max, Min, L̄, Q̄, ᾱ, β̄) == (L, Q, α, β)
        @test cast(Min, Max, L, Q, α, β) == (L̄, Q̄, ᾱ, β̄)
        @test cast(Max, Min, L, Q, α, β) == (L̄, Q̄, ᾱ, β̄)
    end

    # sampletest = QUBOTools.Sample([0, 1], 5.0, 3)
    # swappedsample = QUBOTools.cast(Min, Max, sampletest)

    # @test QUBOTools.value(sampletest) == -QUBOTools.value(swappedsample)


    # V = Symbol
    # U = Int
    # T = Float64

    # bool_states = [[0, 1], [0, 0], [1, 0], [1, 1]]

    # reads = [2, 1, 3, 4]
    # values = [0.0, 2.0, 4.0, 6.0]
    # bool_samples1 = [QUBOTools.Sample(s...) for s in zip(bool_states, values, reads)]
    # bool_samples2 = [QUBOTools.Sample(s...) for s in zip(bool_states, -values, reads)]

    # model1 = QUBOTools.Model{V,T,U}(
    #     Dict{V,T}(:x => 1.0, :y => -1.0),
    #     Dict{Tuple{V,V},T}((:x, :y) => 2.0);
    #     scale       = 2.0,
    #     offset      = 1.0,
    #     domain      = 𝔹,
    #     id          = 1,
    #     version     = v"0.1.0",
    #     description = "This is a Bool ModelWrapper",
    #     metadata    = Dict{String,Any}("meta" => "data", "type" => "bool"),
    #     sampleset   = QUBOTools.SampleSet(bool_samples1),
    # )


    # swappedmodel1 = QUBOTools.cast(Max, model1)

    # @test QUBOTools.offset(swappedmodel1) == -QUBOTools.offset(model1)
    # @test first(QUBOTools.qubo(swappedmodel1, Matrix)) ==
    #       -first(QUBOTools.qubo(model1, Matrix))

end

function test_generic()
    test_cast()
end