function test_form_cast(Φ̄::F, Φ::F, Ψ̄::F, Ψ::F) where {T,F<:QUBOTools.AbstractForm{T}}
    @testset "Casting" begin
        @testset "Sense" begin
            # no-op
            @test QUBOTools.cast((QUBOTools.Min => QUBOTools.Min), Φ̄) === Φ̄
            @test QUBOTools.cast((QUBOTools.Max => QUBOTools.Max), Φ) === Φ
            @test QUBOTools.cast((QUBOTools.Min => QUBOTools.Min), Ψ̄) === Ψ̄
            @test QUBOTools.cast((QUBOTools.Max => QUBOTools.Max), Ψ) === Ψ

            @test_throws AssertionError QUBOTools.cast((QUBOTools.Max => QUBOTools.Max), Φ̄)
            @test_throws AssertionError QUBOTools.cast((QUBOTools.Min => QUBOTools.Min), Φ)
            @test_throws AssertionError QUBOTools.cast((QUBOTools.Max => QUBOTools.Max), Ψ̄)
            @test_throws AssertionError QUBOTools.cast((QUBOTools.Min => QUBOTools.Min), Ψ)

            @test _compare_forms(QUBOTools.cast((QUBOTools.Min => QUBOTools.Max), Φ̄), Φ)
            @test _compare_forms(QUBOTools.cast((QUBOTools.Max => QUBOTools.Min), Φ), Φ̄)
            @test _compare_forms(QUBOTools.cast((QUBOTools.Min => QUBOTools.Max), Ψ̄), Ψ)
            @test _compare_forms(QUBOTools.cast((QUBOTools.Max => QUBOTools.Min), Ψ), Ψ̄)

            @test_throws AssertionError QUBOTools.cast((QUBOTools.Max => QUBOTools.Min), Φ̄)
            @test_throws AssertionError QUBOTools.cast((QUBOTools.Min => QUBOTools.Max), Φ)
            @test_throws AssertionError QUBOTools.cast((QUBOTools.Max => QUBOTools.Min), Ψ̄)
            @test_throws AssertionError QUBOTools.cast((QUBOTools.Min => QUBOTools.Max), Ψ)
        end

        @testset "Domain" begin
            # no-op
            @test QUBOTools.cast((QUBOTools.BoolDomain => QUBOTools.BoolDomain), Φ̄) === Φ̄
            @test QUBOTools.cast((QUBOTools.SpinDomain => QUBOTools.SpinDomain), Ψ̄) === Ψ̄
            @test QUBOTools.cast((QUBOTools.BoolDomain => QUBOTools.BoolDomain), Φ) === Φ
            @test QUBOTools.cast((QUBOTools.SpinDomain => QUBOTools.SpinDomain), Ψ) === Ψ

            @test_throws AssertionError QUBOTools.cast(
                (QUBOTools.BoolDomain => QUBOTools.BoolDomain),
                Ψ,
            )
            @test_throws AssertionError QUBOTools.cast(
                (QUBOTools.SpinDomain => QUBOTools.SpinDomain),
                Φ,
            )
            @test_throws AssertionError QUBOTools.cast(
                (QUBOTools.BoolDomain => QUBOTools.BoolDomain),
                Ψ̄,
            )
            @test_throws AssertionError QUBOTools.cast(
                (QUBOTools.SpinDomain => QUBOTools.SpinDomain),
                Φ̄,
            )

            @test _compare_forms(
                QUBOTools.cast((QUBOTools.BoolDomain => QUBOTools.SpinDomain), Φ̄),
                Ψ̄,
            )
            @test _compare_forms(
                QUBOTools.cast((QUBOTools.SpinDomain => QUBOTools.BoolDomain), Ψ̄),
                Φ̄,
            )
            @test _compare_forms(
                QUBOTools.cast((QUBOTools.BoolDomain => QUBOTools.SpinDomain), Φ),
                Ψ,
            )
            @test _compare_forms(
                QUBOTools.cast((QUBOTools.SpinDomain => QUBOTools.BoolDomain), Ψ),
                Φ,
            )
        end
    end

    return nothing
end

function test_form_topology(Φ̄::F, Φ::F, Ψ̄::F, Ψ::F) where {T,F<:QUBOTools.AbstractForm{T}}
    @testset "Topology" begin
        @test QUBOTools.topology(Φ) == QUBOTools.Graphs.Graph([
            QUBOTools.Graphs.Edge(1, 2),
            QUBOTools.Graphs.Edge(2, 3),
        ])

        @test QUBOTools.topology(Ψ) == QUBOTools.Graphs.Graph([
            QUBOTools.Graphs.Edge(1, 2),
            QUBOTools.Graphs.Edge(2, 3),
        ])

        @test QUBOTools.topology(Φ̄) == QUBOTools.Graphs.Graph([
            QUBOTools.Graphs.Edge(1, 2),
            QUBOTools.Graphs.Edge(2, 3),
        ])

        @test QUBOTools.topology(Ψ̄) == QUBOTools.Graphs.Graph([
            QUBOTools.Graphs.Edge(1, 2),
            QUBOTools.Graphs.Edge(2, 3),
        ])
    end

    return nothing
end

function _fix_variables_form(form_kind::Symbol, domain::QUBOTools.Domain)
    seed =
        (form_kind === :dict ? 11 : form_kind === :sparse ? 23 : 37) +
        (domain === QUBOTools.BoolDomain ? 0 : 100)
    rng = Random.MersenneTwister(seed)
    n = 6
    L = Float64.(rand(rng, -5:5, n))
    Q = zeros(Float64, n, n)

    for i in 1:n, j in i:n
        Q[i, j] = rand(rng, -3:3)
    end

    if form_kind === :dict
        return QUBOTools.DictForm{Float64}(
            n,
            Dict{Int,Float64}(i => L[i] for i in 1:n),
            Dict{Tuple{Int,Int},Float64}((i, j) => Q[i, j] for i in 1:n for j in i:n),
            1.5,
            -2.0;
            sense = :min,
            domain,
        )
    elseif form_kind === :sparse
        return QUBOTools.SparseForm{Float64}(n, sparse(L), sparse(Q), 1.5, -2.0; sense = :min, domain)
    else
        return QUBOTools.DenseForm{Float64}(n, L, Q, 1.5, -2.0; sense = :min, domain)
    end
end

function _fix_variables_values(domain::QUBOTools.Domain)
    return domain === QUBOTools.BoolDomain ? [0, 1] : [-1, 1]
end

function _fix_variables_states(values::Vector{Int}, n::Integer)
    n == 0 && return [Int[]]

    return [
        [values[1 + ((mask >> (i - 1)) & 1)] for i in 1:n] for
        mask in 0:(2^n - 1)
    ]
end

function test_form_fix_variables()
    @testset "Variable Fixing" begin
        for form_kind in (:dict, :sparse, :dense),
            domain in (QUBOTools.BoolDomain, QUBOTools.SpinDomain)

            @testset "$(form_kind) $(Symbol(domain))" begin
                Φ = _fix_variables_form(form_kind, domain)
                n = QUBOTools.dimension(Φ)
                values = _fix_variables_values(domain)
                fix = Dict(2 => values[2], 5 => values[1])

                Φ′, offset_delta, index_map = QUBOTools.fix_variables(Φ, fix)

                @test QUBOTools.dimension(Φ′) == n - length(fix)
                @test QUBOTools.scale(Φ′) == QUBOTools.scale(Φ)
                @test QUBOTools.offset(Φ′) ≈ QUBOTools.offset(Φ) + offset_delta
                @test QUBOTools.sense(Φ′) === QUBOTools.sense(Φ)
                @test QUBOTools.domain(Φ′) === QUBOTools.domain(Φ)
                @test index_map == Dict(1 => 1, 3 => 2, 4 => 3, 6 => 4)

                for reduced_state in _fix_variables_states(values, QUBOTools.dimension(Φ′))
                    full_state = QUBOTools.lift_state(reduced_state, fix, index_map, n)

                    @test QUBOTools.value(full_state, Φ) ≈ QUBOTools.value(reduced_state, Φ′)
                    @test full_state[2] == fix[2]
                    @test full_state[5] == fix[5]
                end

                Φ_identity, identity_delta, identity_map =
                    QUBOTools.fix_variables(Φ, Dict{Int,Int}())

                @test _compare_forms(Φ_identity, Φ)
                @test iszero(identity_delta)
                @test identity_map == Dict(i => i for i in 1:n)

                fix_all = Dict(i => values[1 + (i % 2)] for i in 1:n)
                Φ_empty, _, empty_map = QUBOTools.fix_variables(Φ, fix_all)
                full_state = [fix_all[i] for i in 1:n]

                @test QUBOTools.dimension(Φ_empty) == 0
                @test isempty(empty_map)
                @test QUBOTools.value(Int[], Φ_empty) ≈ QUBOTools.value(full_state, Φ)

                invalid_value = domain === QUBOTools.BoolDomain ? -1 : 0

                @test_throws ArgumentError QUBOTools.fix_variables(Φ, Dict(0 => values[1]))
                @test_throws ArgumentError QUBOTools.fix_variables(Φ, Dict(n + 1 => values[1]))
                @test_throws ArgumentError QUBOTools.fix_variables(Φ, Dict(1 => invalid_value))
                @test_throws ArgumentError QUBOTools.fix_variables([1], Φ)
                @test_throws ArgumentError QUBOTools.lift_state([values[1]], fix, index_map, n)
                @test_throws ArgumentError QUBOTools.lift_state(
                    fill(values[1], QUBOTools.dimension(Φ′) + 1),
                    fix,
                    index_map,
                    n,
                )
            end
        end
    end

    return nothing
end

function test_form_dict()
    @testset "⋅ Dict" begin
        L̄ = Dict{Int,Float64}(1 => 10.0, 2 => 11.0, 3 => 12.0)
        Q̄ = Dict{Tuple{Int,Int},Float64}(
            (1, 1) => 1.0,
            (2, 2) => 2.0,
            (3, 3) => 3.0,
            (1, 2) => 4.0,
            (2, 3) => 5.0,
        )
        Φ̄ = QUBOTools.DictForm{Float64}(3, L̄, Q̄, 1.0, 1.0; sense = :min, domain = :bool)

        L = Dict{Int,Float64}(1 => -10.0, 2 => -11.0, 3 => -12.0)
        Q = Dict{Tuple{Int,Int},Float64}(
            (1, 1) => -1.0,
            (2, 2) => -2.0,
            (3, 3) => -3.0,
            (1, 2) => -4.0,
            (2, 3) => -5.0,
        )
        Φ = QUBOTools.DictForm{Float64}(3, L, Q, 1.0, -1.0; sense = :max, domain = :bool)

        h̄ = Dict{Int,Float64}(1 => 6.50, 2 => 8.75, 3 => 8.75)
        J̄ = Dict{Tuple{Int,Int},Float64}(
            (1, 1) => 0.25,
            (2, 2) => 0.50,
            (3, 3) => 0.75,
            (1, 2) => 1.00,
            (2, 3) => 1.25,
        )
        Ψ̄ = QUBOTools.DictForm{Float64}(3, h̄, J̄, 1.0, 21.25; sense = :min, domain = :spin)

        h = Dict{Int,Float64}(1 => -6.50, 2 => -8.75, 3 => -8.75)
        J = Dict{Tuple{Int,Int},Float64}(
            (1, 1) => -0.25,
            (2, 2) => -0.50,
            (3, 3) => -0.75,
            (1, 2) => -1.00,
            (2, 3) => -1.25,
        )
        Ψ = QUBOTools.DictForm{Float64}(3, h, J, 1.0, -21.25; sense = :max, domain = :spin)

        @testset "Constructor" begin
            @test _compare_forms(
                Φ̄,
                QUBOTools.DictForm{Float64}(
                    3,
                    Dict{Int,Float64}(1 => 11.0, 2 => 13.0, 3 => 15.0),
                    Dict{Tuple{Int,Int},Float64}((1, 2) => 4.0, (2, 3) => 5.0),
                    1.0,
                    1.0;
                    sense  = :min,
                    domain = :bool,
                );
                atol = 0.0,
            )
            @test _compare_forms(
                Φ,
                QUBOTools.DictForm{Float64}(
                    3,
                    Dict{Int,Float64}(1 => -11.0, 2 => -13.0, 3 => -15.0),
                    Dict{Tuple{Int,Int},Float64}((1, 2) => -4.0, (2, 3) => -5.0),
                    1.0,
                    -1.0;
                    sense  = :max,
                    domain = :bool,
                );
                atol = 0.0,
            )
            @test _compare_forms(
                Ψ̄,
                QUBOTools.DictForm{Float64}(
                    3,
                    Dict{Int,Float64}(1 => 6.5, 2 => 8.75, 3 => 8.75),
                    Dict{Tuple{Int,Int},Float64}((1, 2) => 1.00, (2, 3) => 1.25),
                    1.0,
                    22.75;
                    sense  = :min,
                    domain = :spin,
                );
                atol = 0.0,
            )
            @test _compare_forms(
                Ψ,
                QUBOTools.DictForm{Float64}(
                    3,
                    Dict{Int,Float64}(1 => -6.5, 2 => -8.75, 3 => -8.75),
                    Dict{Tuple{Int,Int},Float64}((1, 2) => -1.00, (2, 3) => -1.25),
                    1.0,
                    -22.75;
                    sense  = :max,
                    domain = :spin,
                );
                atol = 0.0,
            )
        end

        test_form_cast(Φ̄, Φ, Ψ̄, Ψ)

        test_form_topology(Φ̄, Φ, Ψ̄, Ψ)
    end

    return nothing
end

function test_form_sparse()
    @testset "⋅ Sparse" begin
        L̄ = sparse([10.0, 11.0, 12.0])
        Q̄ = sparse([
            1.0 4.0 0.0
            0.0 2.0 5.0
            0.0 0.0 3.0
        ])
        Φ̄ =
            QUBOTools.SparseForm{Float64}(3, L̄, Q̄, 1.0, 1.0; sense = :min, domain = :bool)

        L = sparse([-10.0, -11.0, -12.0])
        Q = sparse([
            -1.0 -4.0 -0.0
            -0.0 -2.0 -5.0
            -0.0 -0.0 -3.0
        ])
        Φ = QUBOTools.SparseForm{Float64}(3, L, Q, 1.0, -1.0; sense = :max, domain = :bool)

        h̄ = sparse([6.5, 8.75, 8.75])
        J̄ = sparse([
            0.25 1.00 0.00
            0.00 0.50 1.25
            0.00 0.00 0.75
        ])
        Ψ̄ = QUBOTools.SparseForm{Float64}(
            3,
            h̄,
            J̄,
            1.0,
            21.25;
            sense = :min,
            domain = :spin,
        )

        h = sparse([-6.5, -8.75, -8.75])
        J = sparse([
            -0.25 -1.00 -0.00
            -0.00 -0.50 -1.25
            -0.00 -0.00 -0.75
        ])
        Ψ = QUBOTools.SparseForm{Float64}(
            3,
            h,
            J,
            1.0,
            -21.25;
            sense = :max,
            domain = :spin,
        )

        @testset "Constructor" begin
            @test _compare_forms(
                Φ̄,
                QUBOTools.SparseForm{Float64}(
                    3,
                    sparse([11.0, 13.0, 15.0]),
                    sparse([
                        0.0 4.0 0.0
                        0.0 0.0 5.0
                        0.0 0.0 0.0
                    ]),
                    1.0,
                    1.0;
                    sense = :min,
                    domain = :bool,
                );
                atol = 1E-10,
            )
            @test _compare_forms(
                Φ,
                QUBOTools.SparseForm{Float64}(
                    3,
                    sparse([-11.0, -13.0, -15.0]),
                    sparse([
                        -0.0 -4.0 -0.0
                        -0.0 -0.0 -5.0
                        -0.0 -0.0 -0.0
                    ]),
                    1.0,
                    -1.0;
                    sense = :max,
                    domain = :bool,
                );
                atol = 1E-10,
            )
            @test _compare_forms(
                Ψ̄,
                QUBOTools.SparseForm{Float64}(
                    3,
                    sparse([6.50, 8.75, 8.75]),
                    sparse([
                        0.00 1.00 0.00
                        0.00 0.00 1.25
                        0.00 0.00 0.00
                    ]),
                    1.0,
                    22.75;
                    sense = :min,
                    domain = :spin,
                );
                atol = 1E-10,
            )
            @test _compare_forms(
                Ψ,
                QUBOTools.SparseForm{Float64}(
                    3,
                    sparse([-6.50, -8.75, -8.75]),
                    sparse([
                        -0.00 -1.00 -0.00
                        -0.00 -0.00 -1.25
                        -0.00 -0.00 -0.00
                    ]),
                    1.0,
                    -22.75;
                    sense = :max,
                    domain = :spin,
                );
                atol = 1E-10,
            )
        end

        test_form_cast(Φ̄, Φ, Ψ̄, Ψ)

        test_form_topology(Φ̄, Φ, Ψ̄, Ψ)
    end

    return nothing
end

function test_form_dense()
    @testset "⋅ Dense" begin
        L̄ = ([10.0, 11.0, 12.0])
        Q̄ = ([
            1.0 4.0 0.0
            0.0 2.0 5.0
            0.0 0.0 3.0
        ])
        Φ̄ =
            QUBOTools.DenseForm{Float64}(3, L̄, Q̄, 1.0, 1.0; sense = :min, domain = :bool)

        L = ([-10.0, -11.0, -12.0])
        Q = ([
            -1.0 -4.0 -0.0
            -0.0 -2.0 -5.0
            -0.0 -0.0 -3.0
        ])
        Φ = QUBOTools.DenseForm{Float64}(3, L, Q, 1.0, -1.0; sense = :max, domain = :bool)

        h̄ = ([6.5, 8.75, 8.75])
        J̄ = ([
            0.25 1.00 0.00
            0.00 0.50 1.25
            0.00 0.00 0.75
        ])
        Ψ̄ = QUBOTools.DenseForm{Float64}(
            3,
            h̄,
            J̄,
            1.0,
            21.25;
            sense = :min,
            domain = :spin,
        )

        h = ([-6.5, -8.75, -8.75])
        J = ([
            -0.25 -1.00 -0.00
            -0.00 -0.50 -1.25
            -0.00 -0.00 -0.75
        ])
        Ψ = QUBOTools.DenseForm{Float64}(
            3,
            h,
            J,
            1.0,
            -21.25;
            sense = :max,
            domain = :spin,
        )

        @testset "Constructor" begin
            @test _compare_forms(
                Φ̄,
                QUBOTools.DenseForm{Float64}(
                    3,
                    ([11.0, 13.0, 15.0]),
                    ([
                        0.0 4.0 0.0
                        0.0 0.0 5.0
                        0.0 0.0 0.0
                    ]),
                    1.0,
                    1.0;
                    sense = :min,
                    domain = :bool,
                );
                atol = 1E-10,
            )
            @test _compare_forms(
                Φ,
                QUBOTools.DenseForm{Float64}(
                    3,
                    ([-11.0, -13.0, -15.0]),
                    ([
                        -0.0 -4.0 -0.0
                        -0.0 -0.0 -5.0
                        -0.0 -0.0 -0.0
                    ]),
                    1.0,
                    -1.0;
                    sense = :max,
                    domain = :bool,
                );
                atol = 1E-10,
            )
            @test _compare_forms(
                Ψ̄,
                QUBOTools.DenseForm{Float64}(
                    3,
                    ([6.50, 8.75, 8.75]),
                    ([
                        0.00 1.00 0.00
                        0.00 0.00 1.25
                        0.00 0.00 0.00
                    ]),
                    1.0,
                    22.75;
                    sense = :min,
                    domain = :spin,
                );
                atol = 1E-10,
            )
            @test _compare_forms(
                Ψ,
                QUBOTools.DenseForm{Float64}(
                    3,
                    ([-6.50, -8.75, -8.75]),
                    ([
                        -0.00 -1.00 -0.00
                        -0.00 -0.00 -1.25
                        -0.00 -0.00 -0.00
                    ]),
                    1.0,
                    -22.75;
                    sense = :max,
                    domain = :spin,
                );
                atol = 1E-10,
            )
        end

        test_form_cast(Φ̄, Φ, Ψ̄, Ψ)

        test_form_topology(Φ̄, Φ, Ψ̄, Ψ)
    end

    return nothing
end

function test_form()
    @testset "→ Form" verbose = true begin
        test_form_dict()
        test_form_sparse()
        test_form_dense()
        test_form_fix_variables()
    end

    return nothing
end
