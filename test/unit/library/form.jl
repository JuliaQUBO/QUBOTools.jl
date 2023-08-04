function test_form_dict()
    @testset "Dict Form" begin
        L̄ = Dict{Int,Float64}(1 => 10.0, 2 => 11.0, 3 => 12.0)
        Q̄ = Dict{Tuple{Int,Int},Float64}(
            (1, 1) => 1.0, (2, 2) => 2.0, (3, 3) => 3.0,
            (1, 2) => 4.0, (2, 3) => 5.0,
        )
        Φ̄ = QUBOTools.DictForm{Float64}(3, L̄, Q̄, 1.0, 1.0)

        L = Dict{Int,Float64}(1 => -10.0, 2 => -11.0, 3 => -12.0)
        Q = Dict{Tuple{Int,Int},Float64}(
            (1, 1) => -1.0, (2, 2) => -2.0, (3, 3) => -3.0,
            (1, 2) => -4.0, (2, 3) => -5.0,
            )
        Φ = QUBOTools.DictForm{Float64}(3, L, Q, 1.0, -1.0)

        h̄ = Dict{Int,Float64}(1 => 6.25, 2 => 8.25, 3 => 8.0)
        J̄ = Dict{Tuple{Int,Int},Float64}(
            (1, 1) => 0.25, (2, 2) => 0.50, (3, 3) => 0.75,
            (1, 2) => 1.00, (2, 3) => 1.25,
        )
        Ψ̄ = QUBOTools.DictForm{Float64}(3, h̄, J̄, 1.0, 22.75) 

        h = Dict{Int,Float64}(1 => -6.25, 2 => -8.25, 3 => -8.0)
        J = Dict{Tuple{Int,Int},Float64}(
            (1, 1) => -0.25, (2, 2) => -0.50, (3, 3) => -0.75,
            (1, 2) => -1.00, (2, 3) => -1.25,
        )
        Ψ = QUBOTools.DictForm{Float64}(3, h, J, 1.0, -22.75) 
            
        @testset "Constructor" begin
            @test Φ̄ == QUBOTools.DictForm{Float64}(
                3,
                Dict{Int,Float64}(1 => 11.0, 2 => 13.0, 3 => 15.0),
                Dict{Tuple{Int,Int},Float64}((1, 2) => 4.0, (2, 3) => 5.0),
                1.0,
                1.0,
            )
            @test Φ == QUBOTools.DictForm{Float64}(
                3,
                Dict{Int,Float64}(1 => -11.0, 2 => -13.0, 3 => -15.0),
                Dict{Tuple{Int,Int},Float64}((1, 2) => -4.0, (2, 3) => -5.0),
                1.0,
                -1.0,
            )
            @test Ψ̄ == QUBOTools.DictForm{Float64}(
                3,
                Dict{Int,Float64}(1 => 6.5, 2 => 8.75, 3 => 8.75),
                Dict{Tuple{Int,Int},Float64}((1, 2) => 1.00, (2, 3) => 1.25),
                1.0,
                22.75,
            )
            @test Ψ == QUBOTools.DictForm{Float64}(
                3,
                Dict{Int,Float64}(1 => -6.5, 2 => -8.75, 3 => -8.75),
                Dict{Tuple{Int,Int},Float64}((1, 2) => -1.00, (2, 3) => -1.25),
                1.0,
                -22.75,
            )
        end
        
        @testset "Casting" begin
            @testset "Sense" begin
                # no-op
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Min, Φ̄) === Φ̄
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Max, Φ̄) === Φ̄
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Min, Φ) === Φ
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Max, Φ) === Φ
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Min, Ψ̄) === Ψ̄
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Max, Ψ̄) === Ψ̄
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Min, Ψ) === Ψ
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Max, Ψ) === Ψ

                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Max, Φ̄) ≈ Φ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Min, Φ̄) ≈ Φ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Max, Φ) ≈ Φ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Min, Φ) ≈ Φ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Max, Ψ̄) ≈ Ψ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Min, Ψ̄) ≈ Ψ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Max, Ψ) ≈ Ψ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Min, Ψ) ≈ Ψ̄ atol = 1E-10
            end

            @testset "Domain" begin
                # no-op
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.BoolDomain, Φ̄) === Φ̄
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.BoolDomain, Ψ̄) === Ψ̄
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.SpinDomain, Φ̄) === Φ̄
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.SpinDomain, Ψ̄) === Ψ̄
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.BoolDomain, Φ) === Φ
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.BoolDomain, Ψ) === Ψ
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.SpinDomain, Φ) === Φ
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.SpinDomain, Ψ) === Ψ

                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.SpinDomain, Φ̄) ≈ Ψ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.BoolDomain, Ψ̄) ≈ Φ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.SpinDomain, Φ) ≈ Ψ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.BoolDomain, Ψ) ≈ Φ atol = 1E-10
            end
        end
    end

    return nothing
end

function test_form_sparse()
    @testset "Sparse Form" begin
        L̄ = sparse([10.0, 11.0, 12.0])
        Q̄ = sparse([
            1.0 4.0 0.0
            0.0 2.0 5.0
            0.0 0.0 3.0
        ])
        Φ̄ = QUBOTools.SparseForm{Float64}(3, L̄, Q̄, 1.0, 1.0)

        L = sparse([-10.0, -11.0, -12.0])
        Q = sparse([
            -1.0 -4.0 -0.0
            -0.0 -2.0 -5.0
            -0.0 -0.0 -3.0
        ])
        Φ = QUBOTools.SparseForm{Float64}(3, L, Q, 1.0, -1.0)

        h̄ = sparse([6.25, 8.25, 8.0])
        J̄ = sparse([
            0.25 1.00 0.00
            0.00 0.50 1.25
            0.00 0.00 0.75
        ])
        Ψ̄ = QUBOTools.SparseForm{Float64}(3, h̄, J̄, 1.0, 22.75) 

        h = sparse([-6.25, -8.25, -8.0])
        J = sparse([
            -0.25 -1.00 -0.00
            -0.00 -0.50 -1.25
            -0.00 -0.00 -0.75
        ])
        Ψ = QUBOTools.SparseForm{Float64}(3, h, J, 1.0, -22.75) 
            
        @testset "Constructor" begin
            @test Φ̄ ≈ QUBOTools.SparseForm{Float64}(
                3,
                sparse([11.0, 13.0, 15.0]),
                sparse([
                    0.0 4.0 0.0
                    0.0 0.0 5.0
                    0.0 0.0 0.0
                ]),
                1.0,
                1.0,
            ) atol = 1E-10

            @test Φ ≈ QUBOTools.SparseForm{Float64}(
                3,
                sparse([-11.0, -13.0, -15.0]),
                sparse([
                    -0.0 -4.0 -0.0
                    -0.0 -0.0 -5.0
                    -0.0 -0.0 -0.0
                ]),
                1.0,
                -1.0,
            ) atol = 1E-10

            @test Ψ̄ ≈ QUBOTools.SparseForm{Float64}(
                3,
                sparse([6.50, 8.75, 8.75]),
                sparse([
                    0.00 1.00 0.00
                    0.00 0.00 1.25
                    0.00 0.00 0.00
                ]),
                1.0,
                22.75,
            ) atol = 1E-10

            @test Ψ ≈ QUBOTools.SparseForm{Float64}(
                3,
                sparse([-6.50, -8.75, -8.75]),
                sparse([
                    -0.00 -1.00 -0.00
                    -0.00 -0.00 -1.25
                    -0.00 -0.00 -0.00
                ]),
                1.0,
                -22.75,
            ) atol = 1E-10
        end
        
        @testset "Casting" begin
            @testset "Sense" begin
                # no-op
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Min, Φ̄) === Φ̄
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Max, Φ̄) === Φ̄
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Min, Φ) === Φ
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Max, Φ) === Φ
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Min, Ψ̄) === Ψ̄
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Max, Ψ̄) === Ψ̄
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Min, Ψ) === Ψ
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Max, Ψ) === Ψ

                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Max, Φ̄) ≈ Φ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Min, Φ̄) ≈ Φ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Max, Φ) ≈ Φ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Min, Φ) ≈ Φ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Max, Ψ̄) ≈ Ψ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Min, Ψ̄) ≈ Ψ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Max, Ψ) ≈ Ψ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Min, Ψ) ≈ Ψ̄ atol = 1E-10
            end

            @testset "Domain" begin
                # no-op
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.BoolDomain, Φ̄) === Φ̄
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.BoolDomain, Ψ̄) === Ψ̄
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.SpinDomain, Φ̄) === Φ̄
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.SpinDomain, Ψ̄) === Ψ̄
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.BoolDomain, Φ) === Φ
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.BoolDomain, Ψ) === Ψ
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.SpinDomain, Φ) === Φ
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.SpinDomain, Ψ) === Ψ

                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.SpinDomain, Φ̄) ≈ Ψ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.BoolDomain, Ψ̄) ≈ Φ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.SpinDomain, Φ) ≈ Ψ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.BoolDomain, Ψ) ≈ Φ atol = 1E-10
            end
        end
    end

    return nothing
end

function test_form_dense()
    @testset "Dense Form" begin
        L̄ = [10.0, 11.0, 12.0]
        Q̄ = [
            1.0 4.0 0.0
            0.0 2.0 5.0
            0.0 0.0 3.0
        ]
        Φ̄ = QUBOTools.DenseForm{Float64}(3, L̄, Q̄, 1.0, 1.0)

        L = [-10.0, -11.0, -12.0]
        Q = [
            -1.0 -4.0 -0.0
            -0.0 -2.0 -5.0
            -0.0 -0.0 -3.0
        ]
        Φ = QUBOTools.DenseForm{Float64}(3, L, Q, 1.0, -1.0)

        h̄ = [6.25, 8.25, 8.0]
        J̄ = [
            0.25 1.00 0.00
            0.00 0.50 1.25
            0.00 0.00 0.75
        ]
        Ψ̄ = QUBOTools.DenseForm{Float64}(3, h̄, J̄, 1.0, 22.75) 

        h = [-6.25, -8.25, -8.0]
        J = [
            -0.25 -1.00 -0.00
            -0.00 -0.50 -1.25
            -0.00 -0.00 -0.75
        ]
        Ψ = QUBOTools.DenseForm{Float64}(3, h, J, 1.0, -22.75) 
            
        @testset "Constructor" begin
            @test Φ̄ ≈ QUBOTools.DenseForm{Float64}(
                3,
                [11.0, 13.0, 15.0],
                [
                    0.0 4.0 0.0
                    0.0 0.0 5.0
                    0.0 0.0 0.0
                ],
                1.0,
                1.0,
            ) atol = 1E-10

            @test Φ ≈ QUBOTools.DenseForm{Float64}(
                3,
                [-11.0, -13.0, -15.0],
                [
                    -0.0 -4.0 -0.0
                    -0.0 -0.0 -5.0
                    -0.0 -0.0 -0.0
                ],
                1.0,
                -1.0,
            ) atol = 1E-10

            @test Ψ̄ ≈ QUBOTools.DenseForm{Float64}(
                3,
                [6.50, 8.75, 8.75],
                [
                    0.00 1.00 0.00
                    0.00 0.00 1.25
                    0.00 0.00 0.00
                ],
                1.0,
                22.75,
            ) atol = 1E-10

            @test Ψ ≈ QUBOTools.DenseForm{Float64}(
                3,
                [-6.50, -8.75, -8.75],
                [
                    -0.00 -1.00 -0.00
                    -0.00 -0.00 -1.25
                    -0.00 -0.00 -0.00
                ],
                1.0,
                -22.75,
            ) atol = 1E-10
        end
        
        @testset "Casting" begin
            @testset "Sense" begin
                # no-op
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Min, Φ̄) === Φ̄
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Max, Φ̄) === Φ̄
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Min, Φ) === Φ
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Max, Φ) === Φ
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Min, Ψ̄) === Ψ̄
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Max, Ψ̄) === Ψ̄
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Min, Ψ) === Ψ
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Max, Ψ) === Ψ

                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Max, Φ̄) ≈ Φ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Min, Φ̄) ≈ Φ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Max, Φ) ≈ Φ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Min, Φ) ≈ Φ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Max, Ψ̄) ≈ Ψ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Min, Ψ̄) ≈ Ψ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Min => QUBOTools.Max, Ψ) ≈ Ψ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.Max => QUBOTools.Min, Ψ) ≈ Ψ̄ atol = 1E-10
            end

            @testset "Domain" begin
                # no-op
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.BoolDomain, Φ̄) === Φ̄
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.BoolDomain, Ψ̄) === Ψ̄
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.SpinDomain, Φ̄) === Φ̄
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.SpinDomain, Ψ̄) === Ψ̄
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.BoolDomain, Φ) === Φ
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.BoolDomain, Ψ) === Ψ
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.SpinDomain, Φ) === Φ
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.SpinDomain, Ψ) === Ψ

                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.SpinDomain, Φ̄) ≈ Ψ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.BoolDomain, Ψ̄) ≈ Φ̄ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.BoolDomain => QUBOTools.SpinDomain, Φ) ≈ Ψ atol = 1E-10
                @test QUBOTools.cast(QUBOTools.SpinDomain => QUBOTools.BoolDomain, Ψ) ≈ Φ atol = 1E-10
            end
        end
    end

    return nothing
end

function test_form()
    @testset "→ Form" begin
        test_form_dict()
        test_form_sparse()
        test_form_dense()
    end
    
    return nothing
end
