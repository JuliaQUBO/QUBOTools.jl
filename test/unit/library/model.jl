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

        model = QUBOTools.Model(
            L,
            Q;
            scale       = 2.0,
            offset      = -1.0,
            sense       = :max,
            domain      = :spin,
            id          = 33,
            description = "A QUBO Model",
            solution    = SampleSet{T,U}(
                [
                    Sample{T,U}([↓, ↑, ↓, ↑, ↓, ↑, ↓, ↑], 4.0, 1),
                    Sample{T,U}([↑, ↓, ↑, ↓, ↑, ↓, ↑, ↓], 3.0, 2),
                    Sample{T,U}([↑, ↓, ↑, ↓, ↓, ↑, ↓, ↑], 2.0, 3),
                    Sample{T,U}([↓, ↑, ↓, ↑, ↑, ↓, ↑, ↓], 1.0, 4),
                ];
                sense  = :max,
                domain = :spin,
            ),
            start      = Dict{V,Int}(
                :w => ↓,
                :x => ↑,
                :y => ↓,
                :z => ↑,
                :α => ↑,
                :β => ↓,
                :γ => ↑,
                :ξ => ↓,
            )
        )

        @testset "⋅ Constructor" begin
            @test model isa QUBOTools.Model{V,T,U}

            let empty_model = QUBOTools.Model{V,T,U}()
                @test isempty(empty_model)
            end

            @testset "Sparse constructors" begin
                variables = V[:b, :a, :c]

                linear_indices = [1, 2, 2, 3]
                linear_values = T[2.0, 2.0, -2.0, 0.0]

                quadratic_rows = [1, 2, 1, 3, 3, 2]
                quadratic_cols = [2, 1, 1, 2, 2, 3]
                quadratic_values = T[3.0, 4.0, -1.0, 5.0, -5.0, 0.0]

                coo_model = QUBOTools.Model{V,T,U}(
                    variables,
                    linear_indices,
                    linear_values,
                    quadratic_rows,
                    quadratic_cols,
                    quadratic_values;
                    scale  = T(2.5),
                    offset = T(-0.75),
                    sense  = :max,
                    domain = :bool,
                )

                @test coo_model isa QUBOTools.Model{V,T,U,QUBOTools.SparseForm{T}}
                @test QUBOTools.variables(coo_model) == variables
                @test QUBOTools.index(coo_model, :b) == 1
                @test QUBOTools.index(coo_model, :a) == 2
                @test QUBOTools.index(coo_model, :c) == 3
                @test Dict(QUBOTools.linear_terms(coo_model)) == Dict{Int,T}(1 => 1.0)
                @test Dict(QUBOTools.quadratic_terms(coo_model)) ==
                    Dict{Tuple{Int,Int},T}((1, 2) => 7.0)
                @test QUBOTools.scale(coo_model) == T(2.5)
                @test QUBOTools.offset(coo_model) == T(-0.75)
                @test QUBOTools.sense(coo_model) === QUBOTools.Max
                @test QUBOTools.domain(coo_model) === QUBOTools.BoolDomain

                sparse_model = QUBOTools.Model{V,T,U}(
                    variables,
                    sparsevec(linear_indices, linear_values, 3),
                    sparse(quadratic_rows, quadratic_cols, quadratic_values, 3, 3);
                    scale  = T(2.5),
                    offset = T(-0.75),
                    sense  = :max,
                    domain = :bool,
                )

                @test _compare_models(coo_model, sparse_model)
                @test QUBOTools.Model(
                    variables,
                    sparsevec(linear_indices, linear_values, 3),
                    sparse(quadratic_rows, quadratic_cols, quadratic_values, 3, 3),
                ) isa QUBOTools.Model{V,T,Int}
                @test QUBOTools.Model(
                    variables,
                    linear_indices,
                    linear_values,
                    quadratic_rows,
                    quadratic_cols,
                    quadratic_values,
                ) isa QUBOTools.Model{V,T,Int}

                @test_throws ArgumentError QUBOTools.Model{V,T,U}(
                    V[:a, :a],
                    sparsevec(linear_indices, linear_values, 3),
                    sparse(quadratic_rows, quadratic_cols, quadratic_values, 3, 3),
                )
                @test_throws DimensionMismatch QUBOTools.Model{V,T,U}(
                    variables,
                    spzeros(T, 2),
                    sparse(quadratic_rows, quadratic_cols, quadratic_values, 3, 3),
                )
                @test_throws DimensionMismatch QUBOTools.Model{V,T,U}(
                    variables,
                    [1],
                    T[],
                    Int[],
                    Int[],
                    T[],
                )
                @test_throws ArgumentError QUBOTools.Model{V,T,U}(
                    variables,
                    [4],
                    T[1.0],
                    Int[],
                    Int[],
                    T[],
                )
            end
        end

        @testset "⋅ Queries" begin
            @testset "Data access" begin
                @test QUBOTools.dimension(model) == 8

                @test QUBOTools.indices(model)   == collect(1:8)
                @test QUBOTools.variables(model) == [:w, :x, :y, :z, :α, :β, :γ, :ξ]

                @test QUBOTools.hasvariable(model, :u) === false
                @test_throws Exception QUBOTools.index(model, :u)
                @test QUBOTools.hasvariable(model, :w) === true
                @test QUBOTools.index(model, :w) == 1
                @test QUBOTools.hasvariable(model, :x) === true
                @test QUBOTools.index(model, :x) == 2
                @test QUBOTools.hasvariable(model, :y) === true
                @test QUBOTools.index(model, :y) == 3
                @test QUBOTools.hasvariable(model, :δ) === false
                @test_throws Exception QUBOTools.index(model, :δ)

                @test QUBOTools.hasindex(model, 0) === false
                @test_throws Exception QUBOTools.variable(model, 0)
                @test QUBOTools.hasindex(model, 1) === true
                @test QUBOTools.variable(model, 1) == :w
                @test QUBOTools.hasindex(model, 2) === true
                @test QUBOTools.variable(model, 2) == :x
                @test QUBOTools.hasindex(model, 3) === true
                @test QUBOTools.variable(model, 3) == :y
                @test QUBOTools.hasindex(model, 9) === false
                @test_throws Exception QUBOTools.variable(model, 9)

                @test Dict(QUBOTools.linear_terms(model)) == Dict(
                    1 => -0.25,
                    2 => 1.00,
                    3 => 1.00,
                    4 => 2.00,
                )

                @test Dict(QUBOTools.quadratic_terms(model)) == Dict(
                    (1, 2) => 3.0,
                    (1, 4) => -2.0,
                    (2, 3) => 1.0,
                    (2, 4) => 2.0,
                    (3, 4) => -1.0,
                )

                @test QUBOTools.scale(model) == 2.0
                @test QUBOTools.offset(model) == -1.0

                @test QUBOTools.id(model) == 33
                @test QUBOTools.description(model) == "A QUBO Model"

                @test QUBOTools.state(model, 1) == [↓, ↑, ↓, ↑, ↓, ↑, ↓, ↑]
                @test QUBOTools.state(model, 2) == [↑, ↓, ↑, ↓, ↑, ↓, ↑, ↓]
                @test QUBOTools.state(model, 3) == [↑, ↓, ↑, ↓, ↓, ↑, ↓, ↑]
                @test QUBOTools.state(model, 4) == [↓, ↑, ↓, ↑, ↑, ↓, ↑, ↓]

                @test QUBOTools.value(model, 1) == 4.0
                @test QUBOTools.value(model, 2) == 3.0
                @test QUBOTools.value(model, 3) == 2.0
                @test QUBOTools.value(model, 4) == 1.0

                @test QUBOTools.reads(model, 1) == 1
                @test QUBOTools.reads(model, 2) == 2
                @test QUBOTools.reads(model, 3) == 3
                @test QUBOTools.reads(model, 4) == 4

                @test QUBOTools.reads(model) == 10

                @test QUBOTools.start(model; domain = :bool) == Dict{Int,U}(
                    1 => 0,
                    2 => 1,
                    3 => 0,
                    4 => 1,
                    5 => 1,
                    6 => 0,
                    7 => 1,
                    8 => 0,
                )
            end

            @testset "Form conversion" begin
                converted = QUBOTools.form(model, Matrix)
                ψ = QUBOTools.state(model, 1)

                @test converted isa QUBOTools.DenseForm{T}
                @test QUBOTools.sense(converted) === QUBOTools.Max
                @test QUBOTools.domain(converted) === QUBOTools.SpinDomain
                @test _compare_forms(
                    converted,
                    QUBOTools.form(model, QUBOTools.DenseForm{T});
                    atol = 0.0,
                )
                @test QUBOTools.value(ψ, converted) ≈ QUBOTools.value(ψ, QUBOTools.form(model))

                converted32 = QUBOTools.form(model, Matrix, Float32)

                @test converted32 isa QUBOTools.DenseForm{Float32}
                @test _compare_forms(
                    converted32,
                    QUBOTools.form(model, QUBOTools.DenseForm{Float32});
                    atol = 1E-6,
                )

                qubo_form = QUBOTools.qubo(model, Matrix)
                min_qubo = QUBOTools.qubo(model, Matrix; sense = :min)

                @test qubo_form isa QUBOTools.DenseForm{T}
                @test QUBOTools.sense(qubo_form) === QUBOTools.Max
                @test QUBOTools.domain(qubo_form) === QUBOTools.BoolDomain
                @test _compare_forms(
                    qubo_form,
                    QUBOTools.qubo(model, QUBOTools.DenseForm{T});
                    atol = 0.0,
                )
                @test QUBOTools.sense(min_qubo) === QUBOTools.Min
                @test QUBOTools.domain(min_qubo) === QUBOTools.BoolDomain
                @test _compare_forms(
                    min_qubo,
                    QUBOTools.qubo(model, QUBOTools.DenseForm{T}; sense = :min);
                    atol = 0.0,
                )

                ising_form = QUBOTools.ising(model, Matrix)

                @test ising_form isa QUBOTools.DenseForm{T}
                @test QUBOTools.sense(ising_form) === QUBOTools.Max
                @test QUBOTools.domain(ising_form) === QUBOTools.SpinDomain
                @test _compare_forms(
                    ising_form,
                    QUBOTools.ising(model, QUBOTools.DenseForm{T});
                    atol = 0.0,
                )

                for (spec, form_type) in (
                    SparseMatrixCSC => QUBOTools.SparseForm,
                    Dict            => QUBOTools.DictForm,
                )
                    converted_spec = QUBOTools.form(model, spec)
                    converted_spec32 = QUBOTools.form(model, spec, Float32)
                    min_bool_spec = QUBOTools.form(model, spec; sense = :min, domain = :bool)

                    @test converted_spec isa form_type{T}
                    @test _compare_forms(
                        converted_spec,
                        QUBOTools.form(model, form_type{T});
                        atol = 0.0,
                    )
                    @test QUBOTools.value(ψ, converted_spec) ≈ QUBOTools.value(ψ, QUBOTools.form(model))

                    @test converted_spec32 isa form_type{Float32}
                    @test _compare_forms(
                        converted_spec32,
                        QUBOTools.form(model, form_type{Float32});
                        atol = 1E-6,
                    )

                    @test QUBOTools.sense(min_bool_spec) === QUBOTools.Min
                    @test QUBOTools.domain(min_bool_spec) === QUBOTools.BoolDomain
                    @test _compare_forms(
                        min_bool_spec,
                        QUBOTools.form(model, form_type{T}; sense = :min, domain = :bool);
                        atol = 0.0,
                    )
                end
            end

            @testset "Metrics" begin
                @test QUBOTools.linear_density(model)    ≈ 4/8   # l / n
                @test QUBOTools.quadratic_density(model) ≈ 10/56 # 2q / (n² - n)
                @test QUBOTools.density(model)           ≈ 14/64 # (l + 2q) / n²
            end
        end

        model_copy = copy(model)
        
        empty!(model)

        @testset "⋅ Empty" begin
            @test isempty(model)
        end

        copy!(model, model_copy)

        @testset "⋅ Copy" begin
            @test !isempty(model)
            @test !isempty(model_copy)

            @test _compare_models(model, model_copy; compare_solutions = true)
        end

        @testset "⋅ Print" begin
            let io = IOBuffer()
                print(io, model)

                @test String(take!(io)) == """
                    QUBOTools Model
                    ▷ Sense ………………… Max
                    ▷ Domain ……………… SpinDomain
                    ▷ Variables ……… 8
                    
                    Density:
                    ▷ Linear ………………  50.00%
                    ▷ Quadratic ………  17.86%
                    ▷ Total …………………  21.88%
                    
                    Warm-start:
                    ▷ Sites ………………… 8/8
                    
                    Solutions:
                    ▷ Samples …………… 4
                    ▷ Best value …… 4.0
                    """
            end

            empty_model = QUBOTools.Model{V,T,U}(; sense = :min, domain = :bool)

            let io = IOBuffer()
                print(io, empty_model)

                @test String(take!(io)) == """
                    QUBOTools Model
                    ▷ Sense ………………… Min
                    ▷ Domain ……………… BoolDomain
                    
                    The model is empty.
                    """
            end
        end
    end

    return nothing
end
