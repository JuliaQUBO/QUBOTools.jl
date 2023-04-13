function test_cast()
    @testset "Casting" begin
        L̄ = Dict{Int,Float64}(1 => 10, 2 => 11, 3 => 12)
        L = Dict{Int,Float64}(1 => -10, 2 => -11, 3 => -12)

        @test cast(Min => Min, L̄) == L̄
        @test cast(Max => Max, L̄) == L̄
        @test cast(Min => Min, L) == L
        @test cast(Max => Max, L) == L
        @test cast(Min => Max, L̄) == L
        @test cast(Max => Min, L̄) == L
        @test cast(Min => Max, L) == L̄
        @test cast(Max => Min, L) == L̄

        Q̄ = Dict{Tuple{Int,Int},Float64}((1, 1) => 1.0, (2, 2) => 2.0, (3, 3) => 3.0)
        Q = Dict{Tuple{Int,Int},Float64}((1, 1) => -1.0, (2, 2) => -2.0, (3, 3) => -3.0)

        @test cast(Min => Min, Q̄) == Q̄
        @test cast(Max => Max, Q̄) == Q̄
        @test cast(Min => Min, Q) == Q
        @test cast(Max => Max, Q) == Q
        @test cast(Min => Max, Q̄) == Q
        @test cast(Max => Min, Q̄) == Q
        @test cast(Min => Max, Q) == Q̄
        @test cast(Max => Min, Q) == Q̄

        ᾱ = 1.0
        α = 1.0

        β̄ = 1.0
        β = -1.0

        @test cast(Min => Min, L̄, Q̄, ᾱ, β̄) == (L̄, Q̄, ᾱ, β̄)
        @test cast(Max => Max, L̄, Q̄, ᾱ, β̄) == (L̄, Q̄, ᾱ, β̄)
        @test cast(Min => Min, L, Q, α, β) == (L, Q, α, β)
        @test cast(Max => Max, L, Q, α, β) == (L, Q, α, β)
        @test cast(Min => Max, L̄, Q̄, ᾱ, β̄) == (L, Q, α, β)
        @test cast(Max => Min, L̄, Q̄, ᾱ, β̄) == (L, Q, α, β)
        @test cast(Min => Max, L, Q, α, β) == (L̄, Q̄, ᾱ, β̄)
        @test cast(Max => Min, L, Q, α, β) == (L̄, Q̄, ᾱ, β̄)
    end
end

function test_generic()
    test_cast()
end