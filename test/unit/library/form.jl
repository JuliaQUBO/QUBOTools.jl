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

function test_form_topology_isolates()
    @testset "Topology with isolated variables" begin
        fixtures = (
            (
                "Trailing isolates",
                [1.0, 0.0, 0.0, 2.0, -1.0],
                sparse([1, 2], [2, 3], [1.0, -1.0], 5, 5),
                Set([(1, 2), (2, 3)]),
                Set([(1, 2, 3), (4,), (5,)]),
            ),
            (
                "Internal isolates",
                [0.0, 2.0, 0.0, 0.0, 0.0],
                sparse([1, 3], [3, 5], [1.0, -1.0], 5, 5),
                Set([(1, 3), (3, 5)]),
                Set([(1, 3, 5), (2,), (4,)]),
            ),
            (
                "Diagonal only",
                zeros(3),
                sparse([1, 2, 3], [1, 2, 3], [1.0, -2.0, 3.0], 3, 3),
                Set{Tuple{Int,Int}}(),
                Set([(1,), (2,), (3,)]),
            ),
            (
                "All zero",
                zeros(3),
                spzeros(3, 3),
                Set{Tuple{Int,Int}}(),
                Set([(1,), (2,), (3,)]),
            ),
            (
                "Dimension zero",
                zeros(0),
                spzeros(0, 0),
                Set{Tuple{Int,Int}}(),
                Set{Tuple}(),
            ),
        )

        form_types = (QUBOTools.DictForm{Float64}, QUBOTools.SparseForm{Float64}, QUBOTools.DenseForm{Float64})

        for F in form_types,
            sense in (:min, :max), domain in (:bool, :spin)

            @testset "$F $sense $domain" begin
                for (name, L, Q, expected_edges, expected_components) in fixtures
                    @testset "$name" begin
                        n = length(L)
                        Φ = F(QUBOTools.DenseForm{Float64}(n, L, Matrix(Q); sense, domain))
                        graph = QUBOTools.topology(Φ)
                        components = Graphs.connected_components(graph)

                        @test graph isa Graphs.SimpleGraph{Int}
                        @test Graphs.nv(graph) == QUBOTools.dimension(Φ) == n
                        @test collect(Graphs.vertices(graph)) == collect(1:n)
                        @test Set(
                            (Graphs.src(e), Graphs.dst(e)) for e in Graphs.edges(graph)
                        ) == expected_edges
                        @test Set(Tuple(sort(c)) for c in components) == expected_components
                        @test sort(reduce(vcat, components; init = Int[])) == collect(1:n)

                        labels = [:z, :a, :middle, :linear, :unused][1:n]
                        variable_map = QUBOTools.VariableMap{Symbol}(
                            Dict(i => v for (i, v) in enumerate(labels)),
                        )
                        model = QUBOTools.Model{Symbol,Float64,Int}(variable_map, Φ)
                        @test QUBOTools.topology(model) == graph
                        @test Set(QUBOTools.variable(model, i) for c in components for i in c) == Set(labels)
                        @test all(QUBOTools.index(model, labels[i]) == i for i in Graphs.vertices(graph))
                    end
                end
            end
        end
    end

    return nothing
end

function _fix_variables_form(form_kind::Symbol, domain::QUBOTools.Domain, sense::Symbol)
    seed =
        (form_kind === :dict ? 11 : form_kind === :sparse ? 23 : 37) +
        (domain === QUBOTools.BoolDomain ? 0 : 100)
    rng = Random.MersenneTwister(seed)
    n = 7
    L = Float64.(rand(rng, -5:5, n))
    L[n] = 0.0 # A surviving isolated variable must still have a reduced index.
    Q = zeros(Float64, n, n)

    for i in 1:(n-1), j in i:(n-1)
        Q[i, j] = rand(rng, -3:3)
    end

    Φ = if form_kind === :dict
        QUBOTools.DictForm{Float64}(
            n,
            Dict{Int,Float64}(i => L[i] for i in 1:n),
            Dict{Tuple{Int,Int},Float64}((i, j) => Q[i, j] for i in 1:n for j in i:n),
            1.5,
            -2.0;
            sense,
            domain,
        )
    elseif form_kind === :sparse
        QUBOTools.SparseForm{Float64}(n, sparse(L), sparse(Q), 1.5, -2.0; sense, domain)
    else
        QUBOTools.DenseForm{Float64}(n, L, Q, 1.5, -2.0; sense, domain)
    end

    # Evaluate the original input polynomial, including diagonal terms, without
    # calling value, inspecting normalized terms, or reproducing conditioning.
    energy(x) = 1.5 * (-2.0 + sum(L[i] * x[i] for i in 1:n) +
                      sum(Q[i, j] * x[i] * x[j] for i in 1:n for j in i:n))

    return Φ, energy
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
            domain in (QUBOTools.BoolDomain, QUBOTools.SpinDomain),
            sense in (:min, :max)

            @testset "$(form_kind) $(Symbol(domain)) $(sense)" begin
                Φ, energy = _fix_variables_form(form_kind, domain, sense)
                n = QUBOTools.dimension(Φ)
                values = _fix_variables_values(domain)
                fix = Dict(2 => values[2], 5 => values[1])

                Φ′, offset_delta, index_map = QUBOTools.fix_variables(Φ, fix)

                @test QUBOTools.dimension(Φ′) == n - length(fix)
                @test QUBOTools.scale(Φ′) == QUBOTools.scale(Φ)
                @test QUBOTools.offset(Φ′) ≈ QUBOTools.offset(Φ) + offset_delta
                @test QUBOTools.sense(Φ′) === QUBOTools.sense(Φ)
                @test QUBOTools.domain(Φ′) === QUBOTools.domain(Φ)
                @test index_map == Dict(1 => 1, 3 => 2, 4 => 3, 6 => 4, 7 => 5)

                # Enumerate all choices for both fixed variables and all free
                # states: together these cover every valid original state.
                for fixed_state in _fix_variables_states(values, 2)
                    boundary = Dict(2 => fixed_state[1], 5 => fixed_state[2])
                    conditioned, _, map = QUBOTools.fix_variables(Φ, boundary)
                    @test map == index_map
                    @test iszero(QUBOTools.linear_form(conditioned)[map[n]])
                    @test all(i != map[n] && j != map[n] for ((i, j), _) in QUBOTools.quadratic_terms(conditioned))

                    for reduced_state in _fix_variables_states(values, QUBOTools.dimension(conditioned))
                        full_state = QUBOTools.lift_state(reduced_state, boundary, map, n)
                        expected_state = [haskey(boundary, i) ? boundary[i] : reduced_state[map[i]] for i in 1:n]

                        @test full_state == expected_state
                        @test QUBOTools.value(full_state, Φ) ≈ energy(expected_state)
                        @test QUBOTools.value(reduced_state, conditioned) ≈ energy(expected_state)
                    end
                end

                Φ_identity, identity_delta, identity_map =
                    QUBOTools.fix_variables(Φ, Dict{Int,Int}())

                @test _compare_forms(Φ_identity, Φ)
                @test iszero(identity_delta)
                @test identity_map == Dict(i => i for i in 1:n)
                @test QUBOTools.lift_state(fill(values[1], n), Dict{Int,Int}(), identity_map, n) == fill(values[1], n)

                fix_all = Dict(i => values[1 + (i % 2)] for i in 1:n)
                Φ_empty, _, empty_map = QUBOTools.fix_variables(Φ, fix_all)
                full_state = [fix_all[i] for i in 1:n]

                @test QUBOTools.dimension(Φ_empty) == 0
                @test isempty(empty_map)
                @test QUBOTools.value(Int[], Φ_empty) ≈ energy(full_state)
                @test QUBOTools.lift_state(Int[], fix_all, empty_map, n) == full_state

                # Conditioning a form that was empty from the outset.
                F = QUBOTools.formtype(Val(form_kind), Float64)
                empty_form = F(QUBOTools.DictForm{Float64}(
                    0, Dict{Int,Float64}(), Dict{Tuple{Int,Int},Float64}(), 1.5, -2.0;
                    sense, domain,
                ))
                empty_reduced, empty_delta, empty_index_map = QUBOTools.fix_variables(empty_form, Dict{Int,Int}())
                @test QUBOTools.dimension(empty_reduced) == 0
                @test iszero(empty_delta)
                @test isempty(empty_index_map)
                @test QUBOTools.value(Int[], empty_reduced) == -3.0
                @test QUBOTools.lift_state(Int[], Dict{Int,Int}(), empty_index_map, 0) == Int[]

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

                @testset "Worked example and public label mapping" begin
                    # E(x) = 2*(5 - 3*x1 + 2*x2 - x3 + 4*x1*x2 - 2*x2*x3).
                    # Index 4 is isolated, and labels deliberately differ from
                    # indices and their sorted order.
                    worked_form = F(QUBOTools.DictForm{Float64}(
                        4, Dict(1 => -3.0, 2 => 2.0, 3 => -1.0),
                        Dict((1, 2) => 4.0, (2, 3) => -2.0), 2.0, 5.0;
                        sense, domain,
                    ))
                    labels = [40, 10, 90, 20]
                    variable_map = QUBOTools.VariableMap{Int}(Dict(i => v for (i, v) in enumerate(labels)))
                    model = QUBOTools.Model{Int,Float64,Int}(variable_map, worked_form)
                    fixed_value = domain === QUBOTools.BoolDomain ? 1 : -1
                    fixed_labels = Dict(10 => fixed_value)
                    fixed_indices = Dict(QUBOTools.index(model, label) => v for (label, v) in fixed_labels)
                    reduced, delta, map = QUBOTools.fix_variables(QUBOTools.form(model), fixed_indices)
                    label_map = Dict(QUBOTools.variable(model, i) => j for (i, j) in map)

                    @test [QUBOTools.variable(model, i) for i in 1:4] == labels
                    @test all(QUBOTools.index(model, label) == i for (i, label) in enumerate(labels))
                    @test map == Dict(1 => 1, 3 => 2, 4 => 3)
                    @test label_map == Dict(40 => 1, 90 => 2, 20 => 3)
                    @test delta == 2.0 * fixed_value
                    @test QUBOTools.offset(reduced) == 5.0 + delta

                    for state in _fix_variables_states(values, 3)
                        reduced_labels = Dict(90 => state[2], 20 => state[3], 40 => state[1])
                        y = Vector{Int}(undef, 3)
                        for (label, j) in label_map
                            y[j] = reduced_labels[label]
                        end
                        x = QUBOTools.lift_state(y, fixed_indices, map, 4)
                        full_labels = Dict(QUBOTools.variable(model, i) => x[i] for i in 1:4)
                        @test full_labels == merge(reduced_labels, fixed_labels)
                        @test [full_labels[QUBOTools.variable(model, i)] for i in 1:4] == x

                        expected = 2 * (5 - 3*state[1] + 2*fixed_value - state[2] +
                                        4*state[1]*fixed_value - 2*fixed_value*state[2])
                        worked_reduced = domain === QUBOTools.BoolDomain ?
                            2 * (7 + state[1] - 3*state[2]) :
                            2 * (3 - 7*state[1] + state[2])
                        @test worked_reduced == expected
                        @test QUBOTools.value(model, x) == expected
                        @test QUBOTools.value(y, reduced) == expected
                    end
                end
            end
        end

        @testset "Invalid lifting maps" begin
            # These structural checks do not depend on form storage or domain.
            fix = Dict(2 => 1, 5 => 0)
            index_map = Dict(1 => 1, 3 => 2, 4 => 3, 6 => 4)
            state = [0, 1, 0, 1]

            @test QUBOTools.lift_state(state, fix, index_map, 6) == [0, 1, 1, 0, 0, 1]
            @test_throws ArgumentError QUBOTools.lift_state(state, fix, index_map, -1)
            @test_throws ArgumentError QUBOTools.lift_state(state, Dict(2 => 1, 7 => 0), index_map, 6)
            @test_throws ArgumentError QUBOTools.lift_state(state, fix, Dict(1 => 1, 3 => 2, 4 => 3, 9 => 4), 6)
            @test_throws ArgumentError QUBOTools.lift_state(state, fix, Dict(1 => 1, 2 => 2, 4 => 3, 6 => 4), 6)
            @test_throws ArgumentError QUBOTools.lift_state(state, fix, Dict(1 => 1, 3 => 2, 4 => 3, 6 => 5), 6)
            @test_throws ArgumentError QUBOTools.lift_state(state, fix, Dict(1 => 1, 3 => 1, 4 => 3, 6 => 4), 6)
            @test_throws ArgumentError QUBOTools.lift_state(state, Dict(2 => 1), index_map, 6)
            @test QUBOTools.lift_state(fill(7, 4), fix, index_map, 6) == [7, 1, 7, 7, 0, 7]
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
        test_form_topology_isolates()
        test_form_fix_variables()
    end

    return nothing
end
