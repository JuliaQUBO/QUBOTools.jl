struct ModelWrapper
    backend::Any
end

QUBOTools.backend(m::ModelWrapper) = m.backend

function test_interface_setup(bool_model, spin_model, null_model)
    @testset "Setup" begin
        @test QUBOTools.backend(null_model) isa QUBOTools.Model
        @test QUBOTools.backend(bool_model) isa QUBOTools.Model
        @test QUBOTools.backend(spin_model) isa QUBOTools.Model
        @test isempty(QUBOTools.backend(null_model))
        @test !isempty(QUBOTools.backend(bool_model))
        @test !isempty(QUBOTools.backend(spin_model))
    end

    return nothing
end

function test_interface_data_access(bool_model, bool_samples, spin_model, spin_samples, null_model)
    @testset "Data Access" begin
        @test QUBOTools.model_name(bool_model) == "QUBO Model"
        @test QUBOTools.model_name(spin_model) == "QUBO Model"
        
        @test QUBOTools.domain(bool_model) == BoolDomain
        @test QUBOTools.domain(spin_model) == SpinDomain
        
        @test QUBOTools.domain_name(bool_model) == "Bool"
        @test QUBOTools.domain_name(spin_model) == "Spin"
        
        @test QUBOTools.scale(null_model) == 1.0
        @test QUBOTools.scale(bool_model) == 2.0
        @test QUBOTools.scale(spin_model) == 2.0
        
        @test QUBOTools.offset(null_model) == 0.0
        @test QUBOTools.offset(bool_model) == 1.0
        @test QUBOTools.offset(spin_model) == 1.5
        
        @test QUBOTools.id(null_model) == 0
        @test QUBOTools.id(bool_model) == 1
        @test QUBOTools.id(spin_model) == 2
        
        @test QUBOTools.version(null_model) == v"0.0.0"
        @test QUBOTools.version(bool_model) == v"0.1.0"
        @test QUBOTools.version(spin_model) == v"0.2.0"

        @test QUBOTools.description(null_model) == "This is a Null ModelWrapper"
        @test QUBOTools.description(bool_model) == "This is a Bool ModelWrapper"
        @test QUBOTools.description(spin_model) == "This is a Spin ModelWrapper"

        @test QUBOTools.metadata(null_model) == Dict{String,Any}(
            "meta" => "data",
            "type" => "null",
        )
        @test QUBOTools.metadata(bool_model) == Dict{String,Any}(
            "meta" => "data",
            "type" => "bool",
        )
        @test QUBOTools.metadata(spin_model) == Dict{String,Any}(
            "meta" => "data",
            "type" => "spin",
        )

        @test QUBOTools.sampleset(null_model) == SampleSet()
        @test QUBOTools.sampleset(bool_model) == QUBOTools.SampleSet(bool_samples)
        @test QUBOTools.sampleset(spin_model) == QUBOTools.SampleSet(spin_samples)

        @test QUBOTools.linear_terms(null_model) == Dict{Int,Float64}()
        @test QUBOTools.linear_terms(bool_model) == Dict{Int,Float64}(1 => 1.0, 2 => -1.0)
        @test QUBOTools.linear_terms(spin_model) == Dict{Int,Float64}(1 => 1.0)

        @test QUBOTools.explicit_linear_terms(null_model) == Dict{Int,Float64}()
        @test QUBOTools.explicit_linear_terms(bool_model) == Dict{Int,Float64}(1 => 1.0, 2 => -1.0)
        @test QUBOTools.explicit_linear_terms(spin_model) == Dict{Int,Float64}(1 => 1.0, 2 => 0.0)

        @test QUBOTools.quadratic_terms(null_model) == Dict{Tuple{Int,Int},Float64}()
        @test QUBOTools.quadratic_terms(bool_model) == Dict{Tuple{Int,Int},Float64}((1, 2) => 2.0)
        @test QUBOTools.quadratic_terms(spin_model) == Dict{Tuple{Int,Int},Float64}((1, 2) => 0.5)
        
        @test QUBOTools.indices(null_model) == Int[]
        @test QUBOTools.indices(bool_model) == Int[1, 2]
        @test QUBOTools.indices(spin_model) == Int[1, 2]

        @test QUBOTools.variables(null_model) == Symbol[]
        @test QUBOTools.variables(bool_model) == Symbol[:x, :y]
        @test QUBOTools.variables(spin_model) == Symbol[:x, :y]

        @test QUBOTools.variable_set(null_model) == Set{Symbol}([])
        @test QUBOTools.variable_set(bool_model) == Set{Symbol}([:x, :y])
        @test QUBOTools.variable_set(spin_model) == Set{Symbol}([:x, :y])

        @test QUBOTools.variable_map(bool_model, :x) == 1
        @test QUBOTools.variable_map(spin_model, :x) == 1
        @test QUBOTools.variable_map(bool_model, :y) == 2
        @test QUBOTools.variable_map(spin_model, :y) == 2
        
        @test QUBOTools.variable_inv(bool_model, 1) == :x
        @test QUBOTools.variable_inv(spin_model, 1) == :x
        @test QUBOTools.variable_inv(bool_model, 2) == :y
        @test QUBOTools.variable_inv(spin_model, 2) == :y

        @test_throws Exception QUBOTools.variable_map(null_model, :x)
        @test_throws Exception QUBOTools.variable_map(bool_model, :z)
        @test_throws Exception QUBOTools.variable_map(spin_model, :z)
        
        @test_throws Exception QUBOTools.variable_inv(null_model,  1)
        @test_throws Exception QUBOTools.variable_inv(bool_model, -1)
        @test_throws Exception QUBOTools.variable_inv(spin_model, -1)

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

        @test QUBOTools.adjacency(null_model) == Dict{Int, Set{Int}}()
        @test QUBOTools.adjacency(bool_model) == Dict{Int, Set{Int}}(
            1 => Set{Int}([2]),
            2 => Set{Int}([1]),
        )
        @test QUBOTools.adjacency(spin_model) == Dict{Int, Set{Int}}(
            1 => Set{Int}([2]),
            2 => Set{Int}([1]),
        )

        @test QUBOTools.adjacency(null_model, 1) == Set{Int}()
        @test QUBOTools.adjacency(bool_model, 1) == Set{Int}([2])
        @test QUBOTools.adjacency(spin_model, 1) == Set{Int}([2])

        @test QUBOTools.adjacency(null_model, 2) == Set{Int}()
        @test QUBOTools.adjacency(bool_model, 2) == Set{Int}([1])
        @test QUBOTools.adjacency(spin_model, 2) == Set{Int}([1])
    end

    return nothing
end

function test_interface_dict_normal_forms(bool_model, spin_model)
    @testset "▷ Dict" begin
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
        @test QUBOTools.qubo(bool_model)       == (Q̄, ᾱ, β̄)
        @test QUBOTools.qubo(bool_model, Dict) == (Q̄, ᾱ, β̄)
        @test QUBOTools.qubo(spin_model)       == (Q̄, ᾱ, β̄)
        @test QUBOTools.qubo(spin_model, Dict) == (Q̄, ᾱ, β̄)
        @test QUBOTools.qubo(ĥ, Ĵ, α̂, β̂)       == (Q̄, ᾱ, β̄)      
        
        # -*- :: Ising :: -*- #
        @test QUBOTools.ising(bool_model)       == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(bool_model, Dict) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(spin_model)       == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(spin_model, Dict) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(Q̄, ᾱ, β̄)          == (ĥ, Ĵ, α̂, β̂) 
    end

    return nothing
end

function test_interface_vector_normal_forms(bool_model, spin_model)
    @testset "▷ Vector" begin
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
        @test QUBOTools.qubo(ĥ, Ĵ, u, v, α̂, β̂)   == (L̄, Q̄, u, v, ᾱ, β̄)
        
        # -*- :: Ising :: -*- #
        @test QUBOTools.ising(bool_model, Vector) == (ĥ, Ĵ, u, v, α̂, β̂)
        @test QUBOTools.ising(spin_model, Vector) == (ĥ, Ĵ, u, v, α̂, β̂)
        @test QUBOTools.ising(L̄, Q̄, u, v, ᾱ, β̄)   == (ĥ, Ĵ, u, v, α̂, β̂) 
    end

    return nothing
end

function test_interface_matrix_normal_forms(bool_model, spin_model)
    @testset "▷ Matrix" begin
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
        @test QUBOTools.qubo(ĥ, Ĵ, α̂, β̂)         == (Q̄, ᾱ, β̄)
        
        # -*- :: Ising :: -*- #
        @test QUBOTools.ising(bool_model, Matrix) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(spin_model, Matrix) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(Q̄, ᾱ, β̄)            == (ĥ, Ĵ, α̂, β̂) 
    end

    return nothing
end

function test_interface_sparse_normal_forms(bool_model, spin_model)
    @testset "▷ Sparse" begin
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
        @test QUBOTools.qubo(ĥ, Ĵ, α̂, β̂)                  == (Q̄, ᾱ, β̄)
        
        # -*- :: Ising :: -*- #
        @test QUBOTools.ising(bool_model, SparseMatrixCSC) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(spin_model, SparseMatrixCSC) == (ĥ, Ĵ, α̂, β̂)
        @test QUBOTools.ising(Q̄, ᾱ, β̄)                     == (ĥ, Ĵ, α̂, β̂) 
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

            @test QUBOTools.value(bool_model, x) == e
            @test QUBOTools.value(spin_model, s) == e
            @test QUBOTools.value(bool_model, i) == e
            @test QUBOTools.value(spin_model, i) == e

            let (Q, α, β) = QUBOTools.qubo(bool_model, Dict)
                @test QUBOTools.value(Q, x, α, β) ≈ e atol=1E-8
            end

            let (Q, α, β) = QUBOTools.qubo(spin_model, Dict)
                @test QUBOTools.value(Q, x, α, β) ≈ e atol=1E-8
            end

            let (h, J, α, β) = QUBOTools.ising(bool_model, Dict)
                @test QUBOTools.value(h, J, s, α, β) ≈ e atol=1E-8
            end

            let (h, J, α, β) = QUBOTools.ising(spin_model, Dict)
                @test QUBOTools.value(h, J, s, α, β) ≈ e atol=1E-8
            end

            let (L, Q, u, v, α, β) = QUBOTools.qubo(bool_model, Vector)
                @test QUBOTools.value(L, Q, u, v, x, α, β) ≈ e atol=1E-8
            end

            let (L, Q, u, v, α, β) = QUBOTools.qubo(spin_model, Vector)
                @test QUBOTools.value(L, Q, u, v, x, α, β) ≈ e atol=1E-8
            end

            let (h, J, u, v, α, β) = QUBOTools.ising(bool_model, Vector)
                @test QUBOTools.value(h, J, u, v, s, α, β) ≈ e atol=1E-8
            end

            let (h, J, u, v, α, β) = QUBOTools.ising(spin_model, Vector)
                @test QUBOTools.value(h, J, u, v, s, α, β) ≈ e atol=1E-8
            end

            let (Q, α, β) = QUBOTools.qubo(bool_model, Matrix)
                @test QUBOTools.value(Q, x, α, β) ≈ e atol=1E-8
            end

            let (Q, α, β) = QUBOTools.qubo(spin_model, Matrix)
                @test QUBOTools.value(Q, x, α, β) ≈ e atol=1E-8
            end

            let (h, J, α, β) = QUBOTools.ising(bool_model, Matrix)
                @test QUBOTools.value(h, J, s, α, β) ≈ e atol=1E-8
            end

            let (h, J, α, β) = QUBOTools.ising(spin_model, Matrix)
                @test QUBOTools.value(h, J, s, α, β) ≈ e atol=1E-8
            end

            let (Q, α, β) = QUBOTools.qubo(bool_model, SparseMatrixCSC)
                @test QUBOTools.value(Q, x, α, β) ≈ e atol=1E-8
            end

            let (Q, α, β) = QUBOTools.qubo(spin_model, SparseMatrixCSC)
                @test QUBOTools.value(Q, x, α, β) ≈ e atol=1E-8
            end

            let (h, J, α, β) = QUBOTools.ising(bool_model, SparseMatrixCSC)
                @test QUBOTools.value(h, J, s, α, β) ≈ e atol=1E-8
            end

            let (h, J, α, β) = QUBOTools.ising(spin_model, SparseMatrixCSC)
                @test QUBOTools.value(h, J, s, α, β) ≈ e atol=1E-8
            end

            n += k
        end

        @test QUBOTools.reads(bool_model) == n
        @test QUBOTools.reads(spin_model) == n
    end

    return nothing
end

function test_interface()
    V = Symbol
    T = Float64
    U = Int

    bool_states = [[0, 1], [0, 0], [1, 0], [1, 1]]
    spin_states = [[↑, ↓], [↑, ↑], [↓, ↑], [↓, ↓]]
    reads       = [     2,      1,      3,      4]
    values      = [   0.0,    2.0,    4.0,    6.0]

    bool_samples = [QUBOTools.Sample(s...) for s in zip(bool_states, values, reads)]
    spin_samples = [QUBOTools.Sample(s...) for s in zip(spin_states, values, reads)]

    null_model = ModelWrapper(
        QUBOTools.Model{V,T,U}(
            Dict{V,T}(),
            Dict{Tuple{V,V},T}();
            id          = 0,
            domain      = 𝔹,
            version     = v"0.0.0",
            description = "This is a Null ModelWrapper",
            metadata    = Dict{String,Any}(
                "meta" => "data",
                "type" => "null",
            ),
        )
    )

    bool_model = ModelWrapper(
        QUBOTools.Model{V,T,U}(
            Dict{V,T}(:x => 1.0, :y => -1.0),
            Dict{Tuple{V,V},T}((:x, :y) => 2.0);
            scale       = 2.0,
            offset      = 1.0,
            domain      = 𝔹,
            id          = 1,
            version     = v"0.1.0",
            description = "This is a Bool ModelWrapper",
            metadata    = Dict{String,Any}(
                "meta" => "data",
                "type" => "bool",
            ),
            sampleset   = QUBOTools.SampleSet(bool_samples),
        ),
    )

    spin_model = ModelWrapper(
        QUBOTools.Model{V,T,U}(
            Dict{V,T}(:x => 1.0),
            Dict{Tuple{V,V},T}((:x, :y) => 0.5);
            scale       = 2.0,
            offset      = 1.5,
            domain      = 𝕊,
            id          = 2,
            version     = v"0.2.0",
            description = "This is a Spin ModelWrapper",
            metadata    = Dict{String,Any}(
                "meta" => "data",
                "type" => "spin",
            ),
            sampleset   = QUBOTools.SampleSet(spin_samples),
        ),
    )

    @testset "◈ Interface ◈" verbose = true begin
        test_interface_setup(bool_model, spin_model, null_model)
        test_interface_data_access(bool_model, bool_samples, spin_model, spin_samples, null_model)
        # test_interface_normal_forms(bool_model, spin_model)
        test_interface_evaluation(bool_model, bool_states, spin_model, spin_states, reads, values)
    end
end