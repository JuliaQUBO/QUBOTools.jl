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

function test_interface_qubo_normal_forms(bool_model, spin_model)
    @testset "QUBO" begin

        let (L, Q, u, v, α, β) = QUBOTools.qubo(bool_model, Vector)
            @test L == [1.0, -1.0]
            @test Q == [2.0]
            @test u == [1]
            @test v == [2]
            @test α == 2.0
            @test β == 1.0
        end

        let (Q, α, β) = QUBOTools.qubo(bool_model, Matrix)
            @test Q == [
                1.0  2.0
                0.0 -1.0
            ]
            @test α == 2.0
            @test β == 1.0
        end

        let (Q, α, β) = QUBOTools.qubo(bool_model, SparseMatrixCSC)
            @test Q == sparse([
                1.0  2.0
                0.0 -1.0
            ])
            @test α == 2.0
            @test β == 1.0
        end

        @test QUBOTools.qubo(spin_model) == QUBOTools.qubo(spin_model, Dict)

        let (Q, α, β) = QUBOTools.qubo(spin_model, Dict)
            @test Q == Dict{Tuple{Int,Int},Float64}(
                (1, 1) => 1.0, (1, 2) => 2.0,
                               (2, 2) => -1.0
            )
            @test α == 2.0
            @test β == 1.0
        end

        let (L, Q, u, v, α, β) = QUBOTools.qubo(spin_model, Vector)
            @test L == [1.0, -1.0]
            @test Q == [2.0]
            @test u == [1]
            @test v == [2]
            @test α == 2.0
            @test β == 1.0
        end

        let (Q, α, β) = QUBOTools.qubo(spin_model, Matrix)
            @test Q == [1.0 2.0; 0.0 -1.0]
            @test α == 2.0
            @test β == 1.0
        end

        let (Q, α, β) = QUBOTools.qubo(spin_model, Matrix)
            @test Q == [1.0 2.0; 0.0 -1.0]
            @test α == 2.0
            @test β == 1.0
        end
    end

    return nothing
end

function test_interface_ising_normal_forms(bool_model, spin_model)
    @testset "Ising" begin
        @test QUBOTools.ising(bool_model) == QUBOTools.ising(bool_model, Dict)

        let (h, J, α, β) = QUBOTools.ising(bool_model, Dict)
            @test h == Dict{Int,Float64}(1 => 1.0, 2 => 0.0)
            @test J == Dict{Tuple{Int,Int},Float64}((1, 2) => 0.5)
            @test α == 2.0
            @test β == 1.5
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

            let (L, Q, u, v, α, β) = QUBOTools.qubo(h, J, u, v, α, β)
                @test L == [1.0, -1.0]
                @test Q == [2.0]
                @test u == [1]
                @test v == [2]
                @test α == 2.0
                @test β == 1.0
            end
        end

        @test QUBOTools.ising(spin_model) == QUBOTools.ising(spin_model, Dict)

        let (h, J, α, β) = QUBOTools.ising(spin_model, Matrix)
            @test h == [1.0, 0.0]
            @test J == [0.0 0.5; 0.0 0.0]
            @test α == 2.0
            @test β == 1.5
        end

    end
end

function test_interface_dict_normal_forms(bool_model, spin_model)
    @testset "Dict" begin
        # -*- :: QUBO :: -*- #
        Q̄ = Dict{Tuple{Int,Int},Float64}(
            (1, 1) => 1.0, (1, 2) =>  2.0,
                           (2, 2) => -1.0,
        )
        ᾱ = 2.0
        β̄ = 1.0

        # -*- :: Ising :: -*- #
        ĥ = Dict{Int,Float64}(1 => 1.0, 2 => 0.0)
        Ĵ = Dict{Tuple{Int,Int},Float64}((1, 2) => 0.5)
        α̂ = 2.0
        β̂ = 1.5

        # -*- :: QUBO :: -*- #
        @test QUBOTools.qubo(bool_model) == (Q̄, ᾱ, β̄)
        @test QUBOTools.qubo(bool_model, Dict) == (Q̄, ᾱ, β̄)
        @test QUBOTools.qubo(spin_model) == (Q̄, ᾱ, β̄)
        @test QUBOTools.qubo(spin_model, Dict) == (Q̄, ᾱ, β̄)
        @test QUBOTools.qubo(ĥ, Ĵ, α̂, β̂) == (Q̄, ᾱ, β̄)      
        
        # -*- :: Ising :: -*- #
        @test QUBOTools.ising(bool_model) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(bool_model, Dict) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(spin_model) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(spin_model, Dict) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(Q̄, ᾱ, β̄) == (ĥ, Ĵ, α̂, β̂) 
    end

    return nothing
end

function test_interface_vector_normal_forms(bool_model, spin_model)
    @testset "Vector" begin
        # -*- :: QUBO :: -*- #
        L̄ = [1.0, -1.0]
        Q̄ = [2.0]
        ᾱ = 2.0
        β̄ = 1.0

        # -*- :: Ising :: -*- #
        ĥ = [1.0, 0.0]
        Ĵ = [0.5]
        α̂ = 2.0
        β̂ = 1.5

        # -*- :: Both :: -*- #
        u = [1]
        v = [2]

        # -*- :: QUBO :: -*- #
        @test QUBOTools.qubo(bool_model, Vector) == (L̄, Q̄, u, v, ᾱ, β̄)
        @test QUBOTools.qubo(spin_model, Vector) == (L̄, Q̄, u, v, ᾱ, β̄)
        @test QUBOTools.qubo(ĥ, Ĵ, u, v, α̂, β̂) == (L̄, Q̄, u, v, ᾱ, β̄)
        
        # -*- :: Ising :: -*- #
        @test QUBOTools.ising(bool_model, Vector) == (ĥ, Ĵ, u, v, α̂, β̂)
        @test QUBOTools.ising(spin_model, Vector) == (ĥ, Ĵ, u, v, α̂, β̂)
        @test QUBOTools.ising(L̄, Q̄, u, v, ᾱ, β̄) == (ĥ, Ĵ, u, v, α̂, β̂) 
    end

    return nothing
end

function test_interface_matrix_normal_forms(bool_model, spin_model)
    @testset "Matrix" begin
        # -*- :: QUBO :: -*- #
        Q̄ = [1.0 2.0; 0.0 -1.0]
        ᾱ = 2.0
        β̄ = 1.0

        # -*- :: Ising :: -*- #
        ĥ = [1.0, 0.0]
        Ĵ = [0.0 0.5; 0.0 0.0]
        α̂ = 2.0
        β̂ = 1.5

        # -*- :: QUBO :: -*- #
        @test QUBOTools.qubo(bool_model, Matrix) == (Q̄, ᾱ, β̄)
        @test QUBOTools.qubo(spin_model, Matrix) == (Q̄, ᾱ, β̄)
        @test QUBOTools.qubo(ĥ, Ĵ, α̂, β̂) == (Q̄, ᾱ, β̄)
        
        # -*- :: Ising :: -*- #
        @test QUBOTools.ising(bool_model, Matrix) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(spin_model, Matrix) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(Q̄, ᾱ, β̄) == (ĥ, Ĵ, α̂, β̂) 
    end

    return nothing
end

function test_interface_sparse_normal_forms(bool_model, spin_model)
    @testset "Sparse" begin
        # -*- :: QUBO :: -*- #
        Q̄ = sparse([1.0 2.0; 0.0 -1.0])
        ᾱ = 2.0
        β̄ = 1.0

        # -*- :: Ising :: -*- #
        ĥ = sparsevec([1.0, 0.0])
        Ĵ = sparse([0.0 0.5; 0.0 0.0])
        α̂ = 2.0
        β̂ = 1.5

        # -*- :: QUBO :: -*- #
        @test QUBOTools.qubo(bool_model, SparseMatrixCSC) == (Q̄, ᾱ, β̄)
        @test QUBOTools.qubo(spin_model, SparseMatrixCSC) == (Q̄, ᾱ, β̄)
        @test QUBOTools.qubo(ĥ, Ĵ, α̂, β̂) == (Q̄, ᾱ, β̄)
        
        # -*- :: Ising :: -*- #
        @test QUBOTools.ising(bool_model, SparseMatrixCSC) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(spin_model, SparseMatrixCSC) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(Q̄, ᾱ, β̄) == (ĥ, Ĵ, α̂, β̂) 
    end

    return nothing
end

function test_interface_normal_forms(bool_model, spin_model)
    @testset "Normal Forms" verbose = true begin
        test_interface_dict_normal_forms(bool_model, spin_model)
        test_interface_vector_normal_forms(bool_model, spin_model)
        test_interface_matrix_normal_forms(bool_model, spin_model)
        test_interface_sparse_normal_forms(bool_model, spin_model)
    end

    return nothing
end

function test_interface_evaluation(bool_model, bool_states, spin_model, spin_states, reads, values)
    @testset "Evaluation" begin
        n = 0

        for (i, x, s, k, e) in zip(1:4, bool_states, spin_states, reads, values)
            @test QUBOTools.state(bool_model, i) == x
            @test QUBOTools.state(spin_model, i) == s
            @test QUBOTools.reads(bool_model, i) == k
            @test QUBOTools.reads(spin_model, i) == k

            @test QUBOTools.energy(bool_model, x) == e
            @test QUBOTools.energy(spin_model, s) == e
            @test QUBOTools.energy(bool_model, i) == e
            @test QUBOTools.energy(spin_model, i) == e

            n += k
        end

        @test QUBOTools.reads(bool_model) == n
        @test QUBOTools.reads(spin_model) == n
    end

    return nothing
end

function test_interface()
    V = Symbol
    U = Int
    T = Float64
    B = BoolDomain
    S = SpinDomain

    bool_states = [[0, 1], [0, 0], [1, 0], [1, 1]]
    spin_states = [[↑, ↓], [↑, ↑], [↓, ↑], [↓, ↓]]
    reads       = [     2,      1,      3,      4]
    values      = [   0.0,    2.0,    4.0,    6.0]

    bool_samples = [QUBOTools.Sample(s...) for s in zip(bool_states, reads, values)]
    spin_samples = [QUBOTools.Sample(s...) for s in zip(spin_states, reads, values)]

    null_model = Model{B}(
        QUBOTools.StandardQUBOModel{V,U,T,B}(
            Dict{V,T}(),
            Dict{Tuple{V,V},T}()
        )
    )

    bool_model = Model{B}(
        QUBOTools.StandardQUBOModel{V,U,T,B}(
            Dict{V,T}(:x => 1.0, :y => -1.0),
            Dict{Tuple{V,V},T}((:x, :y) => 2.0);
            scale = 2.0,
            offset = 1.0,
            sampleset=QUBOTools.SampleSet(bool_samples),
        ),
    )

    spin_model = Model{S}(
        QUBOTools.StandardQUBOModel{V,U,T,S}(
            Dict{V,T}(:x => 1.0),
            Dict{Tuple{V,V},T}((:x, :y) => 0.5);
            scale = 2.0,
            offset = 1.5,
            sampleset=QUBOTools.SampleSet(spin_samples),
        ),
    )

    @testset "-*- Interface" verbose = true begin
        test_interface_setup(bool_model, spin_model, null_model)
        test_interface_data_access(bool_model, spin_model, null_model)
        test_interface_queries(bool_model, spin_model, null_model)
        test_interface_normal_forms(bool_model, spin_model)
        test_interface_evaluation(bool_model, bool_states, spin_model, spin_states, reads, values)
    end
end