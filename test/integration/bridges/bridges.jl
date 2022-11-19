function test_bridges()
    graph = Dict{Type,Vector{Type}}()

    for (A, N) in QUBOTools.bridges()
        src_cases = get(TEST_CASES, A, nothing)

        if isnothing(src_cases) || isempty(src_cases)
            continue
        end

        for B in N
            dst_cases = get(TEST_CASES, B, nothing)

            if isnothing(dst_cases) || isempty(dst_cases)
                continue
            end

            if !haskey(graph, A)
                graph[A] = Type[]
            end

            push!(graph[A], B)
        end
    end

    @testset "⦷ Bridges ⦷" verbose = true begin
        for (A, N) in graph
            @testset "$(A)" verbose = true begin
                for B in N
                    @testset "→ $(B)" begin
                        src_cases = TEST_CASES[A]
                        dst_cases = TEST_CASES[B]
                        all_cases = collect(intersect(src_cases, dst_cases))
                        src_paths = TEST_DATA_PATH[A].(all_cases)
                        dst_paths = TEST_DATA_PATH[B].(all_cases)

                        for (src_path, dst_path) in zip(src_paths, dst_paths)
                            src_model = read(src_path, A)
                            dst_model = read(dst_path, B)

                            @test _isvalidbridge(
                                convert(B, src_model),
                                dst_model,
                                A;
                                atol = 1E-6,
                            )
                        end
                    end
                end
            end
        end
    end
end
