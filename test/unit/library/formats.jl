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

                    if i == 2
                        @test length(QUBOTools.solution(src_model)) == 2
                        @test QUBOTools.state(src_model, 1) == [0, 1, 0]
                        @test QUBOTools.value(src_model, 1) ≈ 6.291
                        @test QUBOTools.state(src_model, 2) == [1, 0, 1]
                        @test QUBOTools.value(src_model, 2) ≈ 9.531
                    else
                        @test isempty(QUBOTools.solution(src_model))
                    end

                    QUBOTools.write_model(temp_path, src_model)

                    dst_model =
                        QUBOTools.map_variables(variables, QUBOTools.read_model(temp_path))

                    @test dst_model isa QUBOTools.Model

                    @test _compare_models(src_model, dst_model; compare_solutions = true)
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

                    if i == 2
                        @test length(QUBOTools.solution(src_model)) == 2
                        @test QUBOTools.state(src_model, 1) == [-1, 1, -1]
                        @test QUBOTools.value(src_model, 1) ≈ 6.291
                        @test QUBOTools.state(src_model, 2) == [1, -1, 1]
                        @test QUBOTools.value(src_model, 2) ≈ 9.531
                    else
                        @test isempty(QUBOTools.solution(src_model))
                    end

                    QUBOTools.write_model(temp_path, src_model)

                    dst_model =
                        QUBOTools.map_variables(variables, QUBOTools.read_model(temp_path))

                    @test dst_model isa QUBOTools.Model

                    @test _compare_models(src_model, dst_model; compare_solutions = true)
                end
            end
        end

        @testset "solution parsing and domain validation" begin
            # Unordered variable assignments and optional omitted evaluation
            bqpjson_payload = """
            {
              "version": "1.0.0",
              "id": 10,
              "variable_ids": [5, 1, 3],
              "variable_domain": "boolean",
              "scale": 2,
              "offset": 1,
              "linear_terms": [
                {"id": 1, "coeff": 1.5},
                {"id": 5, "coeff": -0.5}
              ],
              "quadratic_terms": [
                {"id_head": 3, "id_tail": 5, "coeff": 2.0}
              ],
              "metadata": {},
              "solutions": [
                {
                  "id": 0,
                  "assignment": [
                    {"id": 5, "value": 1},
                    {"id": 1, "value": 0},
                    {"id": 3, "value": 1}
                  ]
                }
              ]
            }
            """
            parsed_model = QUBOTools.read_model(IOBuffer(bqpjson_payload), QUBOTools.Format{:bqpjson}())
            @test QUBOTools.variables(parsed_model) == [1, 3, 5]
            @test length(QUBOTools.solution(parsed_model)) == 1
            @test QUBOTools.state(parsed_model, 1) == [0, 1, 1]
            @test QUBOTools.value(parsed_model, 1) ≈ QUBOTools.value(parsed_model, [0, 1, 1])

            # Invalid domain error branch in _parse_domain!
            err = try
                QUBOTools._parse_domain!(
                    Dict{Symbol,Any}(),
                    Dict{String,Any}("variable_domain" => "ternary"),
                    QUBOTools.Format{:bqpjson}(),
                )
                nothing
            catch e
                e
            end
            @test err isa QUBOTools.FormatError
            @test occursin("Inconsistent variable domain 'ternary'", sprint(showerror, err))

            # Version mismatch error branch in _parse_version!
            ver_err = try
                QUBOTools._parse_version!(
                    Dict{Symbol,Any}(),
                    Dict{String,Any}("version" => "0.1.0"),
                    QUBOTools.Format{:bqpjson}(),
                )
                nothing
            catch e
                e
            end
            @test ver_err isa QUBOTools.FormatError
            @test occursin("Invalid BQPJSON version '0.1.0'", sprint(showerror, ver_err))

            # Solution validation errors in _parse_solutions!
            base_data() = Dict{Symbol,Any}(
                :variable_set    => Set{Int}([1, 2]),
                :domain          => :bool,
                :linear_terms    => Dict{Int,Float64}(),
                :quadratic_terms => Dict{Tuple{Int,Int},Float64}(),
                :scale           => 1.0,
                :offset          => 0.0,
            )

            @test_throws QUBOTools.FormatError QUBOTools._parse_solutions!(
                base_data(),
                Dict{String,Any}(
                    "solutions" => [
                        Dict{String,Any}(
                            "id" => 0,
                            "assignment" => [
                                Dict{String,Any}("id" => 1, "value" => 0),
                                Dict{String,Any}("id" => 2, "value" => 1),
                            ],
                        ),
                        Dict{String,Any}(
                            "id" => 0,
                            "assignment" => [
                                Dict{String,Any}("id" => 1, "value" => 1),
                                Dict{String,Any}("id" => 2, "value" => 0),
                            ],
                        ),
                    ],
                ),
                QUBOTools.Format{:bqpjson}(),
            )

            @test_throws QUBOTools.FormatError QUBOTools._parse_solutions!(
                base_data(),
                Dict{String,Any}(
                    "solutions" => [
                        Dict{String,Any}(
                            "id" => 0,
                            "assignment" => [
                                Dict{String,Any}("id" => 1, "value" => 0),
                                Dict{String,Any}("id" => 99, "value" => 1),
                            ],
                        ),
                    ],
                ),
                QUBOTools.Format{:bqpjson}(),
            )

            @test_throws QUBOTools.FormatError QUBOTools._parse_solutions!(
                base_data(),
                Dict{String,Any}(
                    "solutions" => [
                        Dict{String,Any}(
                            "id" => 0,
                            "assignment" => [
                                Dict{String,Any}("id" => 1, "value" => 0),
                                Dict{String,Any}("id" => 1, "value" => 1),
                            ],
                        ),
                    ],
                ),
                QUBOTools.Format{:bqpjson}(),
            )

            @test_throws QUBOTools.FormatError QUBOTools._parse_solutions!(
                base_data(),
                Dict{String,Any}(
                    "solutions" => [
                        Dict{String,Any}(
                            "id" => 0,
                            "assignment" => [
                                Dict{String,Any}("id" => 1, "value" => 2),
                                Dict{String,Any}("id" => 2, "value" => 1),
                            ],
                        ),
                    ],
                ),
                QUBOTools.Format{:bqpjson}(),
            )

            @test_throws QUBOTools.FormatError QUBOTools._parse_solutions!(
                base_data(),
                Dict{String,Any}(
                    "solutions" => [
                        Dict{String,Any}(
                            "id" => 0,
                            "assignment" => [
                                Dict{String,Any}("id" => 1, "value" => 0),
                            ],
                        ),
                    ],
                ),
                QUBOTools.Format{:bqpjson}(),
            )
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

        @testset "Wishart synthesis metadata" begin
            n = 6
            m = 3

            src_model = @test_logs (:warn, r"Deprecation Warning:.*QUBOLib") QUBOTools.generate(
                Random.MersenneTwister(110),
                QUBOTools.Wishart(n, m),
            )
            synthesis = QUBOTools.metadata(src_model)["synthesis"]

            @test synthesis["model"] == "Wishart"
            @test synthesis["parameters"] == Dict{String,Any}(
                "n" => n,
                "m" => m,
            )

            _with_temp_path("wishart.bool.json") do temp_path
                QUBOTools.write_model(temp_path, src_model)

                dst_model = QUBOTools.read_model(temp_path)

                @test QUBOTools.metadata(dst_model)["synthesis"] == synthesis
            end
        end

        @testset "Generic synthesis metadata" begin
            n = 6
            μ = 5.0
            σ = 1E-3

            src_model = @test_logs (:warn, r"Deprecation Warning:.*QUBOLib") QUBOTools.generate(
                Random.MersenneTwister(111),
                QUBOTools.SK(n, μ, σ),
            )
            synthesis = QUBOTools.metadata(src_model)["synthesis"]

            @test synthesis["model"] == "Sherrington-Kirkpatrick"
            @test synthesis["parameters"] == Dict{String,Any}(
                "n"     => n,
                "mu"    => μ,
                "sigma" => σ,
            )

            _with_temp_path("sk.bool.json") do temp_path
                QUBOTools.write_model(temp_path, src_model)

                dst_model = QUBOTools.read_model(temp_path)

                @test QUBOTools.metadata(dst_model)["synthesis"] == synthesis
            end
        end

        @testset "Wishart synthesis schema validation" begin
            _with_temp_path("invalid-wishart.bool.json") do temp_path
                write(temp_path, """
                    {
                      "version": "1.0.0",
                      "id": 0,
                      "variable_ids": [1],
                      "variable_domain": "boolean",
                      "scale": 1.0,
                      "offset": 0.0,
                      "linear_terms": [],
                      "quadratic_terms": [],
                      "metadata": {
                        "synthesis": {
                          "model": "Wishart",
                          "parameters": {
                            "n": "6",
                            "m": 3
                          }
                        }
                      }
                    }
                    """)

                try
                    QUBOTools.read_model(temp_path)
                    @test false
                catch err
                    @test err isa QUBOTools.FormatError
                    @test occursin("[metadata][synthesis]", sprint(showerror, err))
                end
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

        @testset "unquoted and non-numeric comment metadata" begin
            dwave_qubo = """
            c name: demo_instance
            c note: generated by qbsolv
            c variables: x_0 x_1
            c tags: ["demo", "qubo"]
            c scale: 1.5
            c offset: -0.25
            c scale: non_numeric
            c offset: non_numeric
            c scale: Inf
            c offset: NaN
            p qubo 0 2 2 1
            0 0 -1.0
            1 1 -1.0
            0 1 2.0
            """
            dwave_model = QUBOTools.read_model(
                IOBuffer(dwave_qubo),
                QUBOTools.Format{:qubo}(; style = :dwave),
            )
            @test dwave_model isa QUBOTools.Model
            @test QUBOTools.dimension(dwave_model) == 2
            @test QUBOTools.scale(dwave_model) == 1.5
            @test QUBOTools.offset(dwave_model) == -0.25
            @test QUBOTools.metadata(dwave_model)["name"] == "demo_instance"
            @test QUBOTools.metadata(dwave_model)["note"] == "generated by qbsolv"
            @test QUBOTools.metadata(dwave_model)["variables"] == "x_0 x_1"
            @test QUBOTools.metadata(dwave_model)["tags"] == ["demo", "qubo"]

            mqlib_qubo = """
            # problem: maxcut
            # scale: non_numeric
            # offset: non_numeric
            2 3
            1 1 -1.0
            2 2 -1.0
            1 2 1.0
            """
            mqlib_model = QUBOTools.read_model(
                IOBuffer(mqlib_qubo),
                QUBOTools.Format{:qubo}(; style = :mqlib),
            )
            @test mqlib_model isa QUBOTools.Model
            @test QUBOTools.dimension(mqlib_model) == 2
            @test QUBOTools.scale(mqlib_model) == 1.0
            @test QUBOTools.offset(mqlib_model) == 0.0
            @test QUBOTools.metadata(mqlib_model)["problem"] == "maxcut"
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

                    dst_model = QUBOTools.read_model(temp_path)

                    @test dst_model isa QUBOTools.Model
                    @test QUBOTools.variables(dst_model) == variables

                    @test _compare_models(src_model, dst_model; compare_solutions = true)
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

                    dst_model = QUBOTools.read_model(temp_path)

                    @test dst_model isa QUBOTools.Model
                    @test QUBOTools.variables(dst_model) == variables

                    @test _compare_models(src_model, dst_model; compare_solutions = true)
                end
            end
        end

        @testset "standalone solution I/O and validation" begin
            sol = SampleSet{Float64,Int}(
                Sample{Float64,Int}[
                    Sample([0, 1, 0], -1.25, 4),
                    Sample([1, 0, 1], 0.5, 2),
                    Sample([1, 1, 0], 2.0, 1),
                    Sample([0, 0, 1], 3.75, 5),
                ];
                metadata = Dict{String,Any}("solver" => "qubin-test"),
                sense = :min,
                domain = :bool,
            )

            _with_temp_path("sol.qb") do temp_path
                QUBOTools.write_solution(temp_path, sol)

                dst_sol = QUBOTools.read_solution(temp_path)

                @test _compare_solutions(sol, dst_sol)
            end

            @test_throws QUBOTools.FormatError QUBOTools._parse_solution_data(
                zeros(Int, 3, 2),
                [1.0],
                [1],
            )
            @test_throws QUBOTools.FormatError QUBOTools._parse_model(
                QUBOTools.Form{Float64}(
                    2,
                    QUBOTools.SparseLinearForm{Float64}(spzeros(Float64, 2)),
                    QUBOTools.SparseQuadraticForm{Float64}(spzeros(Float64, 2, 2)),
                    1.0,
                    0.0;
                    sense = :min,
                    domain = :bool,
                ),
                QUBOTools._variable_map_from_indices([1, 2, 3]);
                metadata = Dict{String,Any}(),
                solution = SampleSet{Float64,Int}(),
            )
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

function test_portable_interchange()
    @testset "⋅ Portable Interchange" begin
        variable_cases = (
            ("permuted Int", [10, 2, 1]),
            ("permuted String", ["x_10", "x_2", "x_1"]),
        )
        all_bool_states = [
            [0, 0, 0],
            [1, 0, 0],
            [0, 1, 0],
            [0, 0, 1],
            [1, 1, 0],
            [1, 0, 1],
            [0, 1, 1],
            [1, 1, 1],
        ]
        all_spin_states = [
            [-1, -1, -1],
            [1, -1, -1],
            [-1, 1, -1],
            [-1, -1, 1],
            [1, 1, -1],
            [1, -1, 1],
            [-1, 1, 1],
            [1, 1, 1],
        ]
        read_counts = [3, 1, 5, 2]

        for (label_desc, vars) in variable_cases,
            domain_sym in (:bool, :spin),
            sense_sym in (:min, :max)

            @testset "$(label_desc) ⋄ $(domain_sym) ⋄ $(sense_sym)" begin
                states = domain_sym === :bool ? all_bool_states : all_spin_states

                src_model = QUBOTools.Model(
                    vars,
                    [1, 2, 3],
                    [0.1, -2.3, 1.0 / 7.0],
                    [1, 1, 2],
                    [2, 3, 3],
                    [-3.125, 0.7, 2.2 / 3.0];
                    scale = 2.75,
                    offset = -0.15,
                    sense = sense_sym,
                    domain = domain_sym,
                    metadata = Dict{String,Any}(
                        "id" => 42,
                        "description" => "portable-interchange",
                        "subproblem" => label_desc,
                    ),
                )

                # Attach 4 distinct samples (m = 4 > n = 3) with reads > 1
                sample_states = states[1:4]
                samples = QUBOTools.Sample{Float64,Int}[
                    QUBOTools.Sample{Float64,Int}(
                        ψ,
                        QUBOTools.value(src_model, ψ),
                        r,
                    ) for (ψ, r) in zip(sample_states, read_counts)
                ]
                sol = QUBOTools.SampleSet{Float64,Int}(
                    samples;
                    metadata = Dict{String,Any}(
                        "origin" => "decomposition-worker",
                        "reads_total" => sum(read_counts),
                    ),
                    sense = sense_sym,
                    domain = domain_sym,
                )
                QUBOTools.attach!(src_model, sol)

                @test QUBOTools.variables(src_model) == vars
                @test QUBOTools.reads(QUBOTools.solution(src_model)) == sum(read_counts)
                @test QUBOTools.verify_objective_values(
                    src_model,
                    QUBOTools.solution(src_model);
                    atol = 1e-12,
                )

                # 1. QUBin (.qb): full lossless model + SampleSet round-trip
                _with_temp_path("$(domain_sym).qb") do qb_path
                    QUBOTools.write_model(qb_path, src_model)
                    qb_model = QUBOTools.read_model(qb_path)

                    @test QUBOTools.variables(qb_model) == vars
                    @test _compare_models(
                        src_model,
                        qb_model;
                        compare_solutions = true,
                        compare_solution_metadata = true,
                        atol = 1e-12,
                    )
                    @test QUBOTools.reads(QUBOTools.solution(qb_model)) == sum(read_counts)
                    @test QUBOTools.verify_objective_values(
                        qb_model,
                        QUBOTools.solution(qb_model);
                        atol = 1e-12,
                    )

                    for ψ in states
                        assignment_dict = Dict(vars[k] => ψ[k] for k in eachindex(vars))
                        @test QUBOTools.value(qb_model, ψ) == QUBOTools.value(src_model, ψ)
                        @test QUBOTools.objective_breakdown(qb_model, assignment_dict).offset_adjusted_value ==
                              QUBOTools.objective_breakdown(src_model, assignment_dict).offset_adjusted_value
                    end
                end

                # 2. BQPJSON (.json): JSON carrier + explicit map_variables (and sense cast for :max)
                _with_temp_path("$(domain_sym).json") do json_path
                    QUBOTools.write_model(json_path, src_model)
                    raw_json_model = QUBOTools.read_model(json_path)

                    @test QUBOTools.sense(raw_json_model) === QUBOTools.Min
                    @test QUBOTools.domain(raw_json_model) === QUBOTools.domain(domain_sym)
                    @test QUBOTools.reads(QUBOTools.solution(raw_json_model)) == sum(read_counts)
                    @test QUBOTools.verify_objective_values(
                        raw_json_model,
                        QUBOTools.solution(raw_json_model);
                        atol = 1e-12,
                    )

                    mapped_json_model = QUBOTools.map_variables(vars, raw_json_model)
                    json_model = if sense_sym === :max
                        QUBOTools.cast((QUBOTools.Min => QUBOTools.Max), mapped_json_model)
                    else
                        mapped_json_model
                    end

                    @test QUBOTools.variables(json_model) == vars
                    @test _compare_models(
                        src_model,
                        json_model;
                        compare_solutions = true,
                        compare_solution_metadata = false,
                        atol = 1e-12,
                    )
                    @test QUBOTools.reads(QUBOTools.solution(json_model)) == sum(read_counts)
                    @test QUBOTools.verify_objective_values(
                        json_model,
                        QUBOTools.solution(json_model);
                        atol = 1e-12,
                    )

                    for ψ in states
                        assignment_dict = Dict(vars[k] => ψ[k] for k in eachindex(vars))
                        @test QUBOTools.value(json_model, ψ) ≈ QUBOTools.value(src_model, ψ) atol = 1e-12
                        @test QUBOTools.objective_breakdown(json_model, assignment_dict).offset_adjusted_value ≈
                              QUBOTools.objective_breakdown(src_model, assignment_dict).offset_adjusted_value atol = 1e-12
                    end
                end

                # 3. Sample table (.csv): standalone SampleSet distribution carrier
                _with_temp_path("samples.csv") do csv_path
                    QUBOTools.write_samples(csv_path, src_model)
                    csv_sol = QUBOTools.read_samples(csv_path)

                    @test _compare_solutions(
                        QUBOTools.solution(src_model),
                        csv_sol;
                        compare_metadata = true,
                        atol = 1e-12,
                    )
                    @test QUBOTools.reads(csv_sol) == sum(read_counts)
                    @test QUBOTools.metadata(csv_sol)["origin"] == "decomposition-worker"
                    @test QUBOTools.verify_objective_values(src_model, csv_sol; atol = 1e-12)
                end
            end
        end

        @testset "map_variables uniqueness validation" begin
            model = QUBOTools.Model(Dict(1 => 1.0, 2 => 2.0), Dict{Tuple{Int,Int},Float64}())
            @test_throws ArgumentError QUBOTools.map_variables(["dup", "dup"], model)
        end

        @testset "numeric precision and conversion boundaries" begin
            # 1. Exact 64-bit integer beyond Float64 precision (2^53 + 1):
            #    preserved exactly in QUBin, rounded to Float64 in BQPJSON
            c_int = (Int64(1) << 53) + Int64(1)
            int_model = QUBOTools.Model{Int,Int64,Int}(
                [10, 2],
                [1, 2],
                Int64[c_int, -3],
                [1],
                [2],
                Int64[5];
                scale = Int64(1),
                offset = Int64(0),
                sense = :min,
                domain = :bool,
                solution = QUBOTools.SampleSet{Int64,Int}(
                    [QUBOTools.Sample{Int64,Int}([1, 0], c_int, 2)];
                    sense = :min,
                    domain = :bool,
                ),
            )

            _with_temp_path("int64.qb") do qb_path
                QUBOTools.write_model(qb_path, int_model)
                qb_dst = QUBOTools.read_model(qb_path)

                @test qb_dst isa QUBOTools.Model{Int,Int64,Int}
                @test QUBOTools.variables(qb_dst) == [10, 2]
                @test QUBOTools.value(qb_dst, [1, 0]) === c_int
                @test QUBOTools.value(qb_dst, 1) === c_int
                @test QUBOTools.reads(qb_dst, 1) == 2
            end

            _with_temp_path("int64.json") do json_path
                QUBOTools.write_model(json_path, int_model)
                json_dst = QUBOTools.read_model(json_path)

                @test json_dst isa QUBOTools.Model{Int,Float64,Int}
                @test QUBOTools.value(json_dst, [1, 0]) === Float64(c_int)
                @test QUBOTools.value(json_dst, 1) === Float64(c_int)
                @test Int64(QUBOTools.value(json_dst, 1)) == c_int - 1
            end

            # 2. Float32 model and sample values:
            #    preserved as Float32 in QUBin, converted to Float64 in CSV and BQPJSON
            f32_val = Float32(0.1)
            f32_model = QUBOTools.Model{String,Float32,Int}(
                ["x_2", "x_1"],
                [1],
                Float32[f32_val],
                Int[],
                Int[],
                Float32[];
                scale = Float32(1),
                offset = Float32(0),
                sense = :min,
                domain = :bool,
                solution = QUBOTools.SampleSet{Float32,Int}(
                    [QUBOTools.Sample{Float32,Int}([1, 0], f32_val, 3)];
                    sense = :min,
                    domain = :bool,
                ),
            )

            _with_temp_path("f32.qb") do qb_path
                QUBOTools.write_model(qb_path, f32_model)
                qb_dst = QUBOTools.read_model(qb_path)

                @test qb_dst isa QUBOTools.Model{String,Float32,Int}
                @test QUBOTools.value(qb_dst, 1) === f32_val
            end

            _with_temp_path("f32.csv") do csv_path
                QUBOTools.write_samples(csv_path, QUBOTools.solution(f32_model))
                csv_dst = QUBOTools.read_samples(csv_path)

                @test csv_dst isa QUBOTools.SampleSet{Float64,Int}
                @test QUBOTools.value(csv_dst, 1) === parse(Float64, string(f32_val))
                @test QUBOTools.reads(csv_dst, 1) == 3
            end

            # 3. BigFloat sample and model boundaries:
            #    converted to Float64 in CSV, rejected by HDF5 dataset creation in QUBin
            big_val = big"1.000000000000000000000000000001"
            big_sol = QUBOTools.SampleSet{BigFloat,Int}(
                [QUBOTools.Sample{BigFloat,Int}([1, 0], big_val, 2)];
                sense = :min,
                domain = :bool,
            )

            _with_temp_path("big.csv") do csv_path
                QUBOTools.write_samples(csv_path, big_sol)
                csv_dst = QUBOTools.read_samples(csv_path)

                @test csv_dst isa QUBOTools.SampleSet{Float64,Int}
                @test QUBOTools.value(csv_dst, 1) === 1.0
                @test QUBOTools.reads(csv_dst, 1) == 2
            end

            big_model = QUBOTools.Model{Int,BigFloat,Int}(
                [1, 2],
                [1],
                BigFloat[big_val],
                Int[],
                Int[],
                BigFloat[];
                scale = BigFloat(1),
                offset = BigFloat(0),
            )

            _with_temp_path("big.qb") do qb_path
                @test_throws MethodError QUBOTools.write_model(qb_path, big_model)
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
        test_portable_interchange()
    end

    return nothing
end
