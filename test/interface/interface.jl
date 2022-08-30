struct Model{D} <: QUBOTools.AbstractQUBOModel{D}
    backend
end

QUBOTools.backend(m::Model) = m.backend

function test_interface()
    V = Symbol
    U = Int
    T = Float64
    D = BoolDomain

    model = Model{D}(
        QUBOTools.StandardQUBOModel{V,U,T,D}(
            Dict{V,T}(:x => 1.0, :y => -1.0),
            Dict{Tuple{V,V},T}((:x, :y) => 2.0);
            scale=2.0,
            offset=1.0
        )
    )

    @testset "-*- Interface" verbose = true begin
        @test QUBOTools.backend(model) isa QUBOTools.StandardQUBOModel
        @test !isempty(model)
        @test isvalid(model)

        @testset "Data access" begin
            @test QUBOTools.scale(model) == 2.0
            @test QUBOTools.offset(model) == 1.0
        end

        @testset "Queries" begin
            @test QUBOTools.model_name(model) == "Model{BoolDomain}"
            @test QUBOTools.domain_name(model) == "Bool"
            @test QUBOTools.linear_size(model) == 2
            @test QUBOTools.quadratic_size(model) == 1

            @test_throws Exception QUBOTools.variable_map(model, :z)
            @test_throws Exception QUBOTools.variable_inv(model, -1)
        end

        @testset "Normal Forms" begin
            let (Q, α, β) = QUBOTools.qubo(Dict, T, model)
                @test Q == Dict{Tuple{Int,Int},T}((1, 1) => 1.0, (1, 2) => 2.0, (2, 2) => -1.0)
                @test α == 2.0
                @test β == 1.0
            end

            let (Q, α, β) = QUBOTools.qubo(Array, T, model)
                @test Q == [1.0 2.0; 0.0 -1.0]
                @test α == 2.0
                @test β == 1.0
            end

            let (h, J, α, β) = QUBOTools.ising(Dict, T, model)
                @test h == Dict{Int,T}(1 => 1.0, 2 => 0.0)
                @test J == Dict{Tuple{Int,Int},T}((1, 2) => 0.5)
                @test α == 2.0
                @test β == 1.5
            end

            let (h, J, α, β) = QUBOTools.ising(Array, T, model)
                @test h == [1.0, 0.0]
                @test J == [0.0 0.5; 0.0 0.0]
                @test α == 2.0
                @test β == 1.5
            end
        end
    end
end