function test_moi()
    @testset "□ MathOptInterface" verbose = true begin
        test_moi_variables()
        test_moi_attributes()
        test_moi_model_parser()
    end

    return nothing
end

function test_moi_variables()
    @testset "⊛ Variables" begin
        @testset "→ varlt" begin
            # Check if the variable ordering of variables is behaving accordingly
            @test QUBOTools.varlt(VI(1), VI(1)) === false
            @test QUBOTools.varlt(VI(1), VI(2)) === true
            @test QUBOTools.varlt(VI(2), VI(1)) === false

            # This specific ordering follows as 1, 2, 3, ..., -1, -2, -3, ...
            @test QUBOTools.varlt(VI(1), VI(-1)) === true
            @test QUBOTools.varlt(VI(-1), VI(1)) === false
        end

        @testset "→ varshow" begin
            @test QUBOTools.varshow(VI(103)) == "x₁₀₃"
            @test QUBOTools.varshow(VI(-13)) == "x₋₁₃"
        end
    end

    return nothing
end

function test_moi_model_parser()
    @testset "⊛ QUBO Model Parser" verbose = true begin
        test_moi_bool_model_parser()
        test_moi_spin_model_parser()
    end

    return nothing
end

function test_moi_bool_model_parser()
    @testset "→ Bool" begin
        @testset "⋅ Linear" begin
            moi_model = MOI.Utilities.Model{Float64}()

            v = MOI.add_variables(moi_model, 3)

            MOI.set(
                moi_model,
                MOI.ObjectiveFunction{SAF{Float64}}(),
                SAF{Float64}(
                    SAT{Float64}[
                        SAT{Float64}(2.0, v[1]),
                        SAT{Float64}(4.0, v[2]),
                        SAT{Float64}(6.0, v[3]),
                    ],
                    9.9,
                ),
            )

            MOI.set(moi_model, MOI.ObjectiveSense(), MOI.MAX_SENSE)

            @test_throws Exception QUBOTools.Model{Float64}(moi_model)

            MOI.add_constraints(moi_model, v, fill(MOI.ZeroOne(), 3))

            let qt_model = QUBOTools.Model{Float64}(moi_model)
                n, L, Q, α, β, s, X = QUBOTools.qubo(qt_model, :dense)

                @test n == 3
                @test s == QUBOTools.sense(:max)
                @test X == QUBOTools.domain(:bool)
                @test L == [2.0, 4.0, 6.0]
                @test Q == [0.0 0.0 0.0; 0.0 0.0 0.0; 0.0 0.0 0.0]
                @test α ≈ 1.0
                @test β ≈ 9.9
            end

            @testset "⧫ Fixed Variables" begin
                MOI.add_constraints(moi_model, v[[1,3]], MOI.EqualTo{Float64}.([0, 1]))

                let qt_model = QUBOTools.Model{Float64}(moi_model)
                    n, L, Q, α, β, s, X = QUBOTools.qubo(qt_model, :dense)
    
                    @test n == 1
                    @test s == QUBOTools.sense(:max)
                    @test X == QUBOTools.domain(:bool)
                    @test L == [4.0]
                    @test Q == [0.0;;]
                    @test α ≈ 1.0
                    @test β ≈ 15.9
                end
            end
        end

        @testset "⋅ Quadratic" begin
            moi_model = MOI.Utilities.Model{Float64}()

            v = MOI.add_variables(moi_model, 3)

            MOI.set(
                moi_model,
                MOI.ObjectiveFunction{SQF{Float64}}(),
                SQF{Float64}(
                    SQT{Float64}[
                        SQT{Float64}(12.0, v[1], v[2]),
                        SQT{Float64}(13.0, v[1], v[3]),
                        SQT{Float64}(23.0, v[2], v[3]),
                        SQT{Float64}(-2.0, v[1], v[1]),
                        SQT{Float64}(-4.0, v[2], v[2]),
                        SQT{Float64}(-6.0, v[3], v[3]),
                    ],
                    SAT{Float64}[
                        SAT{Float64}(2.0, v[1]),
                        SAT{Float64}(4.0, v[2]),
                        SAT{Float64}(6.0, v[3]),
                    ],
                    9.9,
                ),
            )

            MOI.set(moi_model, MOI.ObjectiveSense(), MOI.MAX_SENSE)

            @test_throws Exception QUBOTools.Model{Float64}(moi_model)

            MOI.add_constraints(moi_model, v, fill(MOI.ZeroOne(), 3))

            let qt_model = QUBOTools.Model{Float64}(moi_model)
                n, L, Q, α, β, s, X = QUBOTools.qubo(qt_model, :dense)

                @test n == 3
                @test s == QUBOTools.sense(:max)
                @test X == QUBOTools.domain(:bool)
                @test L == [1.0, 2.0, 3.0]
                @test Q == [0.0 12.0 13.0; 0.0 0.0 23.0; 0.0 0.0 0.0]
                @test α ≈ 1.0
                @test β ≈ 9.9
            end

            @testset "⧫ Fixed Variables" begin
                MOI.add_constraints(moi_model, v[[1,3]], MOI.EqualTo{Float64}.([0, 1]))

                let qt_model = QUBOTools.Model{Float64}(moi_model)
                    n, L, Q, α, β, s, X = QUBOTools.qubo(qt_model, :dense)
    
                    @test n == 1
                    @test s == QUBOTools.sense(:max)
                    @test X == QUBOTools.domain(:bool)
                    @test L == [25.0]
                    @test Q == [0.0;;]
                    @test α ≈ 1.0
                    @test β ≈ 12.9
                end
            end
        end
    end

    return nothing
end

function test_moi_spin_model_parser()
    @testset "→ Spin" begin
        @testset "⋅ Linear" begin
            moi_model = QUBOModel{Float64,Spin}()

            v = MOI.add_variables(moi_model, 3)

            MOI.set(
                moi_model,
                MOI.ObjectiveFunction{SAF{Float64}}(),
                SAF{Float64}(
                    SAT{Float64}[
                        SAT{Float64}(2.0, v[1]),
                        SAT{Float64}(4.0, v[2]),
                        SAT{Float64}(6.0, v[3]),
                    ],
                    9.9,
                ),
            )

            MOI.set(moi_model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

            let qt_model = QUBOTools.Model{Float64}(moi_model)
                n, h, J, α, β, s, X = QUBOTools.ising(qt_model, :dense)

                @test n == 3
                @test s == QUBOTools.sense(:min)
                @test X == QUBOTools.domain(:spin)
                @test h == [2.0, 4.0, 6.0]
                @test J == [0.0 0.0 0.0; 0.0 0.0 0.0; 0.0 0.0 0.0]
                @test α ≈ 1.0
                @test β ≈ 9.9
            end

            @test_throws Exception MOI.add_constrained_variable(moi_model, MOI.ZeroOne())

            @testset "⧫ Fixed Variables" begin
                MOI.add_constraints(moi_model, v[[1,3]], MOI.EqualTo{Float64}.([-1, 1]))

                let qt_model = QUBOTools.Model{Float64}(moi_model)
                    n, h, J, α, β, s, X = QUBOTools.ising(qt_model, :dense)

                    @test n == 1
                    @test s == QUBOTools.sense(:min)
                    @test X == QUBOTools.domain(:spin)
                    @test h == [4.0]
                    @test J == [0.0;;]
                    @test α ≈ 1.0
                    @test β ≈ 13.9
                end
            end
        end

        @testset "⋅ Quadratic" begin
            moi_model = QUBOModel{Float64,Spin}()

            v = MOI.add_variables(moi_model, 3)

            MOI.set(
                moi_model,
                MOI.ObjectiveFunction{SQF{Float64}}(),
                SQF{Float64}(
                    SQT{Float64}[
                        SQT{Float64}(12.0, v[1], v[2]),
                        SQT{Float64}(13.0, v[1], v[3]),
                        SQT{Float64}(23.0, v[2], v[3]),
                        SQT{Float64}(-2.0, v[1], v[1]),
                        SQT{Float64}(-4.0, v[2], v[2]),
                        SQT{Float64}(-6.0, v[3], v[3]),
                    ],
                    SAT{Float64}[
                        SAT{Float64}(2.0, v[1]),
                        SAT{Float64}(4.0, v[2]),
                        SAT{Float64}(6.0, v[3]),
                    ],
                    9.9,
                ),
            )

            MOI.set(moi_model, MOI.ObjectiveSense(), MOI.MIN_SENSE)

            qt_model = QUBOTools.Model{Float64}(moi_model)

            n, h, J, α, β, s, X = QUBOTools.ising(qt_model, :dense)

            @test n == 3
            @test s == QUBOTools.sense(:min)
            @test X == QUBOTools.domain(:spin)
            @test h == [2.0, 4.0, 6.0]
            @test J == [0.0 12.0 13.0; 0.0 0.0 23.0; 0.0 0.0 0.0]
            @test α ≈ 1.0
            @test β ≈ 3.9

            @test_throws Exception MOI.add_constrained_variable(moi_model, MOI.ZeroOne())

            @testset "⧫ Fixed Variables" begin
                MOI.add_constraints(moi_model, v[[1,3]], MOI.EqualTo{Float64}.([-1, 1]))

                let qt_model = QUBOTools.Model{Float64}(moi_model)
                    n, h, J, α, β, s, X = QUBOTools.ising(qt_model, :dense)

                    @test n == 1
                    @test s == QUBOTools.sense(:min)
                    @test X == QUBOTools.domain(:spin)
                    @test h == [15.0]
                    @test J == [0.0;;]
                    @test α ≈ 1.0
                    @test β ≈ -5.1
                end
            end
        end
    end

    return nothing
end

function test_moi_attributes()
    @testset "⊛ Attributes" verbose = true begin
        @testset "→ NumberOfReads" begin
            
        end
    end

    return nothing
end