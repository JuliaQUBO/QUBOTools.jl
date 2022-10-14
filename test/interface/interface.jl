struct Model{D} <: QUBOTools.AbstractQUBOModel{D}
    backend::Any
end

QUBOTools.backend(m::Model) = m.backend

function test_interface_setup(bool_model, spin_model, null_model)
    @testset "Setup" begin
        @test QUBOTools.backend(null_model) isa QUBOTools.StandardQUBOModel
        @test QUBOTools.backend(bool_model) isa QUBOTools.StandardQUBOModel
        @test QUBOTools.backend(spin_model) isa QUBOTools.StandardQUBOModel
        @test isempty(null_model)
        @test !isempty(bool_model)
        @test !isempty(spin_model)
        @test isvalid(bool_model)
        @test isvalid(spin_model)
    end

    return nothing
end

function test_interface_data_access(bool_model, spin_model, null_model)
    @testset "Data access" begin
        @test QUBOTools.scale(null_model) == 1.0
        @test QUBOTools.scale(bool_model) == 2.0
        @test QUBOTools.scale(spin_model) == 2.0
        @test QUBOTools.offset(null_model) == 0.0
        @test QUBOTools.offset(bool_model) == 1.0
        @test QUBOTools.offset(spin_model) == 1.5
    end

    return nothing
end

function test_interface_queries(bool_model, spin_model, null_model)
    @testset "Queries" begin
        @test QUBOTools.model_name(bool_model) == "Model{BoolDomain}"
        @test QUBOTools.model_name(spin_model) == "Model{SpinDomain}"
        @test QUBOTools.domain_name(bool_model) == "Bool"
        @test QUBOTools.domain_name(spin_model) == "Spin"
        @test QUBOTools.domain_size(null_model) == 0
        @test QUBOTools.domain_size(bool_model) == 2
        @test QUBOTools.domain_size(spin_model) == 2
        @test QUBOTools.linear_size(null_model) == 0
        @test QUBOTools.linear_size(bool_model) == 2
        @test QUBOTools.linear_size(spin_model) == 1
        @test QUBOTools.quadratic_size(null_model) == 0
        @test QUBOTools.quadratic_size(bool_model) == 1
        @test QUBOTools.quadratic_size(spin_model) == 1

        @test QUBOTools.density(null_model) |> isnan
        @test QUBOTools.density(bool_model) ≈ 1.0
        @test QUBOTools.density(spin_model) ≈ 0.75
        @test QUBOTools.linear_density(null_model) |> isnan
        @test QUBOTools.linear_density(bool_model) ≈ 1.0
        @test QUBOTools.linear_density(spin_model) ≈ 0.5
        @test QUBOTools.quadratic_density(null_model) |> isnan
        @test QUBOTools.quadratic_density(bool_model) ≈ 1.0
        @test QUBOTools.quadratic_density(spin_model) ≈ 1.0

        @test QUBOTools.variable_map(bool_model, :x) == 1
        @test QUBOTools.variable_map(spin_model, :x) == 1
        @test QUBOTools.variable_map(bool_model, :y) == 2
        @test QUBOTools.variable_map(spin_model, :y) == 2
        @test QUBOTools.variable_inv(bool_model, 1) == :x
        @test QUBOTools.variable_inv(spin_model, 1) == :x
        @test QUBOTools.variable_inv(bool_model, 2) == :y
        @test QUBOTools.variable_inv(spin_model, 2) == :y

        @test_throws Exception QUBOTools.variable_map(bool_model, :z)
        @test_throws Exception QUBOTools.variable_map(spin_model, :z)
        @test_throws Exception QUBOTools.variable_inv(bool_model, -1)
        @test_throws Exception QUBOTools.variable_inv(spin_model, -1)
    end

    return nothing
end

function test_interface_normal_forms(bool_model, spin_model, null_model)
    @testset "Normal Forms" begin
        let (Q, α, β) = QUBOTools.qubo(bool_model, Dict)
            @test Q ==
                  Dict{Tuple{Int,Int},Float64}((1, 1) => 1.0, (1, 2) => 2.0, (2, 2) => -1.0)
            @test α == 2.0
            @test β == 1.0
        end

        let (L, Q, u, v, α, β) = QUBOTools.qubo(bool_model, Vector)
            @test L == [1.0, -1.0]
            @test Q == [2.0]
            @test u == [1]
            @test v == [2]
            @test α == 2.0
            @test β == 1.0
        end

        let (Q, α, β) = QUBOTools.qubo(bool_model, Matrix)
            @test Q == [1.0 2.0; 0.0 -1.0]
            @test α == 2.0
            @test β == 1.0
        end

        let (Q, α, β) = QUBOTools.qubo(bool_model, SparseMatrixCSC)
            @test Q == sparse([1.0 2.0; 0.0 -1.0])
            @test α == 2.0
            @test β == 1.0
        end

        let (h, J, α, β) = QUBOTools.ising(bool_model, Dict)
            @test h == Dict{Int,Float64}(1 => 1.0, 2 => 0.0)
            @test J == Dict{Tuple{Int,Int},Float64}((1, 2) => 0.5)
            @test α == 2.0
            @test β == 1.5
        end

        let (h, J, α, β) = QUBOTools.ising(bool_model, Matrix)
            @test h == [1.0, 0.0]
            @test J == [0.0 0.5; 0.0 0.0]
            @test α == 2.0
            @test β == 1.5
        end

        @test QUBOTools.qubo(bool_model) == QUBOTools.qubo(bool_model, Dict)
        @test QUBOTools.ising(bool_model) == QUBOTools.ising(bool_model, Dict)

        let (Q, α, β) = QUBOTools.qubo(spin_model, Dict)
            @test Q ==
                  Dict{Tuple{Int,Int},Float64}((1, 1) => 1.0, (1, 2) => 2.0, (2, 2) => -1.0)
            @test α == 2.0
            @test β == 1.0
        end

        let (Q, α, β) = QUBOTools.qubo(spin_model, Matrix)
            @test Q == [1.0 2.0; 0.0 -1.0]
            @test α == 2.0
            @test β == 1.0
        end

        let (h, J, α, β) = QUBOTools.ising(spin_model, Dict)
            @test h == Dict{Int,Float64}(1 => 1.0, 2 => 0.0)
            @test J == Dict{Tuple{Int,Int},Float64}((1, 2) => 0.5)
            @test α == 2.0
            @test β == 1.5
        end

        let (h, J, u, v, α, β) = QUBOTools.ising(spin_model, Vector)
            @test h == [1.0, 0.0]
            @test J == [0.5]
            @test u == [1]
            @test v == [2]
            @test α == 2.0
            @test β == 1.5
        end

        let (h, J, α, β) = QUBOTools.ising(spin_model, Matrix)
            @test h == [1.0, 0.0]
            @test J == [0.0 0.5; 0.0 0.0]
            @test α == 2.0
            @test β == 1.5
        end

        @test QUBOTools.qubo(spin_model) == QUBOTools.qubo(spin_model, Dict)
        @test QUBOTools.ising(spin_model) == QUBOTools.ising(spin_model, Dict)
    end

    return nothing
end

function test_interface_evaluation(bool_model, spin_model, null_model)
    @testset "Evaluation" begin
        bool_states = [[0, 0], [0, 1], [1, 0], [1, 1]]
        spin_states = [[↑, ↑], [↑, ↓], [↓, ↑], [↓, ↓]]

        energy_values = [2.0, 0.0, 4.0, 6.0]

        for (x, s, e) in zip(bool_states, spin_states, energy_values)
            @test QUBOTools.energy(bool_model, x) == e
            @test QUBOTools.energy(spin_model, s) == e
        end

        @test_throws AssertionError QUBOTools.energy(null_model, [0, 0])
    end

    return nothing
end

function test_interface()
    V = Symbol
    U = Int
    T = Float64
    B = BoolDomain
    S = SpinDomain

    null_model =
        Model{B}(QUBOTools.StandardQUBOModel{V,U,T,B}(Dict{V,T}(), Dict{Tuple{V,V},T}()))

    bool_model = Model{B}(
        QUBOTools.StandardQUBOModel{V,U,T,B}(
            Dict{V,T}(:x => 1.0, :y => -1.0),
            Dict{Tuple{V,V},T}((:x, :y) => 2.0);
            scale = 2.0,
            offset = 1.0,
        ),
    )

    spin_model = Model{S}(
        QUBOTools.StandardQUBOModel{V,U,T,S}(
            Dict{V,T}(:x => 1.0),
            Dict{Tuple{V,V},T}((:x, :y) => 0.5);
            scale = 2.0,
            offset = 1.5,
        ),
    )

    @testset "-*- Interface" verbose = true begin
        test_interface_setup(bool_model, spin_model, null_model)
        test_interface_data_access(bool_model, spin_model, null_model)
        test_interface_queries(bool_model, spin_model, null_model)
        test_interface_normal_forms(bool_model, spin_model, null_model)
        test_interface_evaluation(bool_model, spin_model, null_model)
    end
end