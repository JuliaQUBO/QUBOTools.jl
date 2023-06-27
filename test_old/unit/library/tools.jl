function test_tools()
    @testset "Tools" begin
        

        L̄, Q̄, variable_set = QUBOTools._normal_form(L̄, Q̄)

        variable_map, variable_inv = QUBOTools._build_mapping(variable_set)

        L, Q = QUBOTools._map_terms(L̄, Q̄, variable_map)

        @test variable_map == Dict{Symbol,Int}(
            :w => 1,
            :x => 2,
            :y => 3,
            :z => 4,
            :α => 5,
            :β => 6,
            :γ => 7,
            :ξ => 8,
        )

        @test variable_inv == Dict{Int,Symbol}(
            1 => :w,
            2 => :x,
            3 => :y,
            4 => :z,
            5 => :α,
            6 => :β,
            7 => :γ,
            8 => :ξ,
        )

        @test L == Dict{Int,Float64}(1 => -0.25, 2 => 1.0, 3 => 1.0, 4 => 2.0)

        @test Q == Dict{Tuple{Int,Int},Float64}(
            (2, 3) => 1.0,
            (2, 4) => 2.0,
            (1, 2) => 3.0,
            (3, 4) => -1.0,
            (1, 4) => -2.0,
        )

        __linear_terms, __quadratic_terms = QUBOTools._inv_terms(L, Q, variable_inv)

        @test __linear_terms ==
              Dict{Symbol,Float64}(:x => 1.0, :y => 1.0, :z => 2.0, :w => -0.25)

        @test __quadratic_terms == Dict{Tuple{Symbol,Symbol},Float64}(
            (:x, :y) => 1.0,
            (:x, :z) => 2.0,
            (:w, :x) => 3.0,
            (:y, :z) => -1.0,
            (:w, :z) => -2.0,
        )

        # ~*~ Type inference ~*~ #
        @test QUBOTools.format(:bool, :json) isa QUBOTools.BQPJSON
        @test QUBOTools.format("file.bool.json") isa QUBOTools.BQPJSON

        @test QUBOTools.format(:spin, :json) isa QUBOTools.BQPJSON
        @test QUBOTools.format("file.spin.json") isa QUBOTools.BQPJSON

        @test QUBOTools.format(:hfs) isa QUBOTools.HFS
        @test QUBOTools.format("file.hfs") isa QUBOTools.HFS

        @test QUBOTools.format(:bool, :mzn) isa QUBOTools.MiniZinc
        @test QUBOTools.format("file.bool.mzn") isa QUBOTools.MiniZinc

        @test QUBOTools.format(:spin, :mzn) isa QUBOTools.MiniZinc
        @test QUBOTools.format("file.spin.mzn") isa QUBOTools.MiniZinc

        @test QUBOTools.format(:qh) isa QUBOTools.Qubist
        @test QUBOTools.format("file.qh") isa QUBOTools.Qubist

        @test QUBOTools.format(:qubo) isa QUBOTools.QUBO
        @test QUBOTools.format("file.qubo") isa QUBOTools.QUBO

        @test_throws Exception QUBOTools.format(:xyz)
        @test_throws Exception QUBOTools.format("file")
    end

    @testset "Raw Model Queries" begin
        Q = Dict{Tuple{Int,Int},Float64}(
            (1, 1) => 1.0,
            (1, 2) => 1.0,
            (1, 3) => 1.0,
            (2, 2) => 1.0,
            (3, 3) => 1.0, 
        )

        h = Dict{Int,Float64}(1 => 1.0, 2 => 0.0, 3 => -1.0)

        J = Dict{Tuple{Int,Int},Float64}((1, 2) => 2.0, (1, 3) => -4.0, (2, 3) => -8.0)

        # ~ value ~ #
        X = [
            [0, 0, 0] => 0.0,
            [1, 0, 0] => 1.0,
            [0, 1, 0] => 1.0,
            [0, 0, 1] => 1.0,
            [1, 1, 0] => 3.0,
            [1, 0, 1] => 3.0,
            [0, 1, 1] => 2.0,
            [1, 1, 1] => 5.0,
        ]

        for (x, e) in X
            @test QUBOTools.value(Q, x) == e
        end

        S = [
            [↑, ↑, ↑] => -10.0,
            [↓, ↑, ↑] => -4.0,
            [↑, ↓, ↑] => 2.0,
            [↑, ↑, ↓] => 12.0,
            [↓, ↓, ↑] => 16.0,
            [↓, ↑, ↓] => 2.0,
            [↑, ↓, ↓] => -8.0,
            [↓, ↓, ↓] => -10.0,
        ]

        for (s, e) in S
            @test QUBOTools.value(h, J, s) == e
        end

        # ~ adjacency ~ #
        A = Dict{Int,Set{Int}}(
            1 => Set{Int}([2, 3]),
            2 => Set{Int}([1]),
            3 => Set{Int}([1]),
        )

        B = Dict{Int,Set{Int}}(
            1 => Set{Int}([2, 3]),
            2 => Set{Int}([1, 3]),
            3 => Set{Int}([1, 2]),
        )

        @test QUBOTools.adjacency(Q) == A
        @test QUBOTools.adjacency(Q, 1) == A[1]
        @test QUBOTools.adjacency(Q, 2) == A[2]
        @test QUBOTools.adjacency(Q, 3) == A[3]

        @test QUBOTools.adjacency(J) == B
        @test QUBOTools.adjacency(J, 1) == B[1]
        @test QUBOTools.adjacency(J, 2) == B[2]
        @test QUBOTools.adjacency(J, 3) == B[3]
    end

    return nothing
end