struct Model{D} <: QUBOTools.AbstractQUBOModel{D}
    backend
end

QUBOTools.backend(m::Model) = m.backend

function test_interface()
    V = Symbol
    U = Int
    T = Float64
    D = BoolDomain

    @testset "-*- Interface" verbose = true begin
        model = Model{D}(QUBOTools.StandardQUBOModel{V,U,T,D}())

        @test QUBOTools.backend(model) isa QUBOTools.StandardQUBOModel
        @test isempty(model)
        @test isvalid(model)

        @testset "Data access" begin
            @test QUBOTools.scale(model) == one(T)
            @test QUBOTools.offset(model) == zero(T)
        end

        @testset "Queries" begin
            @test QUBOTools.model_name(model) == "Model"
            @test QUBOTools.domain_name(model) == "Bool"
            @test QUBOTools.linear_size(model) == 0
            @test QUBOTools.quadratic_size(model) == 0

            @test_throws Exception QUBOTools.variable_map(model, :x)
            @test_throws Exception QUBOTools.variable_inv(model, 0)
        end
    end
end