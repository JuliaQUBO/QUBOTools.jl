function _test_data_path(case::Integer, path...)
    return abspath(__TEST_PATH__, "data", Printf.@sprintf("%02d", case), path...)
end

function test_format_hints()
    @testset "⋅ Format Hints" begin
        @test QUBOTools.infer_format([:bool, :json]) isa QUBOTools.Format{:bqpjson}
        @test QUBOTools.infer_format(; path = "file.bool.json") isa QUBOTools.Format{:bqpjson}

        @test QUBOTools.infer_format([:spin, :json]) isa QUBOTools.Format{:bqpjson}
        @test QUBOTools.infer_format(; path = "file.spin.json") isa QUBOTools.Format{:bqpjson}

        # @test QUBOTools.infer_format([:hfs]) isa QUBOTools.HFS
        # @test QUBOTools.infer_format(; path = "file.hfs") isa QUBOTools.HFS

        @test QUBOTools.infer_format([:qb]) isa QUBOTools.Format{:qubin}
        @test QUBOTools.infer_format(; path = "file.qb") isa QUBOTools.Format{:qubin}

        @test QUBOTools.infer_format([:qh]) isa QUBOTools.Format{:qubist}
        @test QUBOTools.infer_format(; path = "file.qh") isa QUBOTools.Format{:qubist}

        @test QUBOTools.infer_format([:qubo]) isa QUBOTools.Format{:qubo}
        @test QUBOTools.infer_format(; path = "file.qubo") isa QUBOTools.Format{:qubo}

        @test QUBOTools.infer_format([:rudy]) isa QUBOTools.Format{:rudy}
        @test QUBOTools.infer_format(; path = "file.rudy") isa QUBOTools.Format{:rudy}

        @test QUBOTools.infer_format([:mzn]) isa QUBOTools.Format{:minizinc}
        @test QUBOTools.infer_format(; path = "file.mzn") isa QUBOTools.Format{:minizinc}

        @test_throws QUBOTools.FormatInferenceError QUBOTools.infer_format([:xyz])
        @test_throws QUBOTools.FormatInferenceError QUBOTools.infer_format(; path = "file")
    end
end

function _with_temp_path(f::Function, suffix::AbstractString)
    temp_path = "$(tempname()).$(suffix)"

    try
        return f(temp_path)
    finally
        rm(temp_path; force = true)
    end
end

function test_bqpjson_format()
    @testset "⋅ BQPJSON" begin
        @testset "bool" begin
            for i = 0:2
                file_path = _test_data_path(i, "bool.json")

                _with_temp_path("bool.json") do temp_path
                    src_model = QUBOTools.read_model(file_path)
                    variables = QUBOTools.variables(src_model)

                    @test src_model isa QUBOTools.Model

                    QUBOTools.write_model(temp_path, src_model)

                    dst_model =
                        QUBOTools.map_variables(variables, QUBOTools.read_model(temp_path))

                    @test dst_model isa QUBOTools.Model

                    @test _compare_models(src_model, dst_model)
                end
            end
        end

        @testset "spin" begin
            for i = 0:2
                file_path = _test_data_path(i, "spin.json")

                _with_temp_path("spin.json") do temp_path
                    src_model = QUBOTools.read_model(file_path)
                    variables = QUBOTools.variables(src_model)

                    @test src_model isa QUBOTools.Model

                    QUBOTools.write_model(temp_path, src_model)

                    dst_model =
                        QUBOTools.map_variables(variables, QUBOTools.read_model(temp_path))

                    @test dst_model isa QUBOTools.Model

                    @test _compare_models(src_model, dst_model)
                end
            end
        end

        @testset "scientific notation" begin
            model = QUBOTools.Model{Int,Float64,Int}(
                Set{Int}(1:3),
                Dict{Int,Float64}(1 => 1.0e-3, 2 => -2.5e10),
                Dict{Tuple{Int,Int},Float64}((1, 2) => -3.195264750619755e-5);
                offset = 4.25e8,
                sense = :min,
                domain = :bool,
                metadata = Dict{String,Any}("source" => "scientific-notation-test"),
            )

            _with_temp_path("bool.qubo") do temp_path
                QUBOTools.write_model(temp_path, model)

                dst_model = QUBOTools.read_model(temp_path)

                @test _compare_models(model, dst_model)
                @test QUBOTools.value(model, [1, 1, 0]) ==
                      QUBOTools.value(dst_model, [1, 1, 0])
            end
        end
    end

    return nothing
end

function test_qubo_format()
    @testset "⋅ QUBO" begin
        src_fmt = QUBOTools.Format{:qubo}(; style = :dwave)

        for i = 0:2
            file_path = _test_data_path(i, "bool.qubo")

            _with_temp_path("bool.qubo") do temp_path
                src_model = QUBOTools.read_model(file_path, src_fmt)
                variables = QUBOTools.variables(src_model)

                @test src_model isa QUBOTools.Model

                for style in (:dwave, :mqlib)
                    dst_fmt = QUBOTools.Format{:qubo}(; style)

                    QUBOTools.write_model(temp_path, src_model, dst_fmt)

                    dst_model = QUBOTools.map_variables(
                        variables,
                        QUBOTools.read_model(temp_path, dst_fmt),
                    )

                    @test dst_model isa QUBOTools.Model

                    @test _compare_models(src_model, dst_model)
                end
            end
        end
    end

    return nothing
end

function test_qubist_format()
    @testset "⋅ Qubist" begin
        for i = 0:2
            file_path = _test_data_path(i, "spin.qh")

            _with_temp_path("spin.qh") do temp_path
                src_model = QUBOTools.read_model(file_path)
                variables = QUBOTools.variables(src_model)

                @test src_model isa QUBOTools.Model

                QUBOTools.write_model(temp_path, src_model)

                dst_model =
                    QUBOTools.map_variables(variables, QUBOTools.read_model(temp_path))

                @test dst_model isa QUBOTools.Model

                @test _compare_models(src_model, dst_model)
            end
        end
    end

    return nothing
end

function test_qubin_format()
    @testset "⋅ QUBin" begin
        @testset "bool" begin
            for i = 0:2
                file_path = _test_data_path(i, "bool.qb")

                _with_temp_path("bool.qb") do temp_path
                    src_model = QUBOTools.read_model(file_path)
                    variables = QUBOTools.variables(src_model)

                    @test src_model isa QUBOTools.Model

                    QUBOTools.write_model(temp_path, src_model)

                    dst_model =
                        QUBOTools.map_variables(variables, QUBOTools.read_model(temp_path))

                    @test dst_model isa QUBOTools.Model

                    @test _compare_models(src_model, dst_model)
                end
            end
        end

        @testset "spin" begin
            for i = 0:2
                file_path = _test_data_path(i, "spin.qb")

                _with_temp_path("spin.qb") do temp_path
                    src_model = QUBOTools.read_model(file_path)
                    variables = QUBOTools.variables(src_model)

                    @test src_model isa QUBOTools.Model

                    QUBOTools.write_model(temp_path, src_model)

                    dst_model =
                        QUBOTools.map_variables(variables, QUBOTools.read_model(temp_path))

                    @test dst_model isa QUBOTools.Model

                    @test _compare_models(src_model, dst_model)
                end
            end
        end

        # Test sparse array dimensions are preserved when some variables have no terms.
        # Before the fix, the parser created sparse arrays with dimensions
        # inferred from max indices, giving a length-1 vector and (1,2) matrix
        # instead of the correct length-3 vector and (3,3) matrix.
        @testset "sparse dimensions" begin
            src_model = QUBOTools.Model{Int,Float64,Int}(
                Set{Int}([1, 2, 3]),  # Explicitly include all 3 variables
                Dict{Int,Float64}(1 => 1.0),  # Only variable 1 has linear term
                Dict{Tuple{Int,Int},Float64}((1, 2) => 2.0);  # Only (1,2) quadratic term
                sense  = :min,
                domain = :bool,
            )

            _with_temp_path("sparse_dim.qb") do temp_path
                QUBOTools.write_model(temp_path, src_model)

                dst_model = QUBOTools.read_model(temp_path)

                form_obj = QUBOTools.form(dst_model)
                L = QUBOTools.data(QUBOTools.linear_form(form_obj))
                Q = QUBOTools.data(QUBOTools.quadratic_form(form_obj))

                @test dst_model isa QUBOTools.Model
                @test QUBOTools.dimension(dst_model) == QUBOTools.dimension(src_model)
                @test _compare_models(src_model, dst_model)

                # Verify that the underlying sparse structures have the correct size.
                # Before the fix, length(L) == 1 and size(Q) == (1, 2) for this model.
                @test length(L) == 3
                @test size(Q) == (3, 3)
                @test L[3] == 0.0
                @test Q[3, 3] == 0.0

                # The critical test: before the parser fix, calling value() with a state
                # that includes variable 3 would throw DimensionMismatch because the
                # sparse vector/matrix had wrong dimensions after deserialization.
                @test QUBOTools.value(dst_model, [1, 0, 1]) == 1.0
                @test QUBOTools.value(dst_model, [1, 1, 1]) == 3.0
            end
        end
    end

    return nothing
end

function test_minizinc_format()
    @testset "⋅ MiniZinc" begin
        @testset "bool" begin
            let model = QUBOTools.Model{Int,Float64,Int}(
                    Dict{Int,Float64}(1 => 1.0, 2 => 2.0, 3 => 3.0),
                    Dict{Tuple{Int,Int},Float64}(
                        (1, 2) => -12.0,
                        (1, 3) => -13.0,
                        (2, 3) => -23.0,
                    );
                    scale  = 2.0,
                    offset = -1.0,
                    sense  = :min,
                    domain = :bool,
                )

                let io = IOBuffer()
                    QUBOTools.write_model(io, model, QUBOTools.Format{:minizinc}())

                    @test String(take!(io)) == """
                        set of int: Domain = {0,1};
                        var Domain: x1;
                        var Domain: x2;
                        var Domain: x3;
                        float: scale = 2.0;
                        float: offset = -1.0;
                        var float: objective = scale * (1.0*x1 + 2.0*x2 + 3.0*x3 + -12.0*x1*x2 + -13.0*x1*x3 + -23.0*x2*x3 + offset);
                        solve minimize objective;
                        """
                end
            end
        end

        @testset "spin" begin
            let model = QUBOTools.Model{Int,Float64,Int}(
                    Dict{Int,Float64}(1 => 1.0, 2 => 2.0, 3 => 3.0),
                    Dict{Tuple{Int,Int},Float64}(
                        (1, 2) => -12.0,
                        (1, 3) => -13.0,
                        (2, 3) => -23.0,
                    );
                    scale  = 2.0,
                    offset = -1.0,
                    sense  = :max,
                    domain = :spin,
                )

                let io = IOBuffer()
                    QUBOTools.write_model(io, model, QUBOTools.Format{:minizinc}())

                    @test String(take!(io)) == """
                        set of int: Domain = {-1,1};
                        var Domain: x1;
                        var Domain: x2;
                        var Domain: x3;
                        float: scale = 2.0;
                        float: offset = -1.0;
                        var float: objective = scale * (1.0*x1 + 2.0*x2 + 3.0*x3 + -12.0*x1*x2 + -13.0*x1*x3 + -23.0*x2*x3 + offset);
                        solve maximize objective;
                        """
                end
            end
        end
    end

    return nothing
end

function test_rudy_format()
    @testset "⋅ Rudy" begin
        @testset "read" begin
            file_path = _test_data_path(5, "spin.rudy")
            model = QUBOTools.read_model(file_path)

            @test model isa QUBOTools.Model
            @test QUBOTools.dimension(model) == 10
            @test QUBOTools.linear_size(model) == 10
            @test QUBOTools.quadratic_size(model) == 5
            @test QUBOTools.offset(model) == 66363.47
            @test haskey(QUBOTools.metadata(model), "timestamp")
        end

        @testset "write/read round-trip" begin
            model = QUBOTools.Model{Int,Float64,Int}(
                Set{Int}(1:4),
                Dict{Int,Float64}(1 => -1.5, 3 => 2.25),
                Dict{Tuple{Int,Int},Float64}((1, 2) => 4.0, (2, 4) => -7.5);
                offset = 3.5,
                sense = :min,
                domain = :spin,
            )
            fmt = QUBOTools.Format{:rudy}(; domain = :spin)

            _with_temp_path("spin.rudy") do temp_path
                QUBOTools.write_model(temp_path, model, fmt)

                dst_model = QUBOTools.read_model(temp_path, fmt)

                @test _compare_models(model, dst_model)
            end
        end

        @testset "scientific notation write/read round-trip" begin
            model = QUBOTools.Model{Int,Float64,Int}(
                Set{Int}(1:3),
                Dict{Int,Float64}(1 => 1.0e-5, 2 => -2.5e10),
                Dict{Tuple{Int,Int},Float64}((1, 3) => 3.195264750619755e-5);
                offset = 4.25e8,
                sense = :min,
                domain = :spin,
            )
            fmt = QUBOTools.Format{:rudy}(; domain = :spin)

            _with_temp_path("spin.rudy") do temp_path
                QUBOTools.write_model(temp_path, model, fmt)

                dst_model = QUBOTools.read_model(temp_path, fmt)

                @test _compare_models(model, dst_model)
                @test QUBOTools.value(model, [1, -1, 1]) ==
                      QUBOTools.value(dst_model, [1, -1, 1])
            end
        end
    end

    return nothing
end

function test_formats()
    @testset "→ Formats" verbose = true begin
        test_format_hints()
        test_bqpjson_format()
        test_qubin_format()
        test_qubo_format()
        test_qubist_format()
        test_minizinc_format()
        test_rudy_format()
    end

    return nothing
end
