function test_synthesis()
    @testset "→ Synthesis" verbose = true begin
        test_wishart()
        test_sherrington_kirkpatrick()
    end

    return nothing
end

function test_wishart()
    @testset "⋅ Wishart" begin
        let n = 100
            m = 10

            model = @test_logs (:warn, r"Deprecation Warning:.*QUBOLib") QUBOTools.generate(
                QUBOTools.Wishart(n, m),
            )

            @test QUBOTools.dimension(model) == n
            @test QUBOTools.density(model) ≈ 1.0 atol = 1E-8
            
            let sol = QUBOTools.solution(model)
                @test length(sol) > 0
            end
        end
    end

    return nothing
end

function test_sherrington_kirkpatrick()
    @testset "⋅ Sherrington-Kirkpatrick" begin
        let n = 100
            μ = 5.0
            σ = 1E-3
        
            model = @test_logs (:warn, r"Deprecation Warning:.*QUBOLib") QUBOTools.generate(
                QUBOTools.SK(n, μ, σ),
            )
            
            @test QUBOTools.dimension(model) == n
            @test QUBOTools.density(model) ≈ 1.0 atol = 1E-8

            @test mean(last, QUBOTools.linear_terms(model))    ≈ 2μ * (1 - n) atol = 10σ
            @test mean(last, QUBOTools.quadratic_terms(model)) ≈ 4μ           atol = 10σ
            @test QUBOTools.is_gauge_invariant(model; atol = 1e-10)
            @test QUBOTools.metadata(model)["synthesis"]["parameters"]["normalize"] == false
            @test QUBOTools.metadata(model)["synthesis"]["parameters"]["gauge_invariant"] == true
        end

        # Seeded comparison of normalize and gauge_invariant options
        let n = 16, μ = 0.25, σ = 1.5
            m_raw = @test_logs (:warn, r"Deprecation Warning:.*QUBOLib") QUBOTools.generate(
                Random.MersenneTwister(99),
                QUBOTools.SK(n, μ, σ; normalize = false, gauge_invariant = true),
            )
            m_norm = @test_logs (:warn, r"Deprecation Warning:.*QUBOLib") QUBOTools.generate(
                Random.MersenneTwister(99),
                QUBOTools.SK(n, μ, σ; normalize = true, gauge_invariant = true),
            )
            m_naive = @test_logs (:warn, r"Deprecation Warning:.*QUBOLib") QUBOTools.generate(
                Random.MersenneTwister(99),
                QUBOTools.SK(n, μ, σ; normalize = false, gauge_invariant = false),
            )

            @test QUBOTools.is_gauge_invariant(m_raw; atol = 1e-12)
            @test QUBOTools.is_gauge_invariant(m_norm; atol = 1e-12)
            @test !QUBOTools.is_gauge_invariant(m_naive; atol = 1e-6)
            @test QUBOTools.linear_size(m_naive) == 0
            @test QUBOTools.offset(m_naive) == 0.0
            @test collect(QUBOTools.quadratic_terms(m_naive)) == collect(QUBOTools.quadratic_terms(m_raw))

            q_raw = Dict(QUBOTools.quadratic_terms(m_raw))
            q_norm = Dict(QUBOTools.quadratic_terms(m_norm))
            for (k, v) in q_raw
                @test q_norm[k] ≈ v / sqrt(n) rtol = 1e-12
            end

            # Edge cases n = 0 and n = 1 preserve declared dimension
            m0 = @test_logs (:warn, r"Deprecation Warning:.*QUBOLib") QUBOTools.generate(
                QUBOTools.SK(0; normalize = true),
            )
            m1 = @test_logs (:warn, r"Deprecation Warning:.*QUBOLib") QUBOTools.generate(
                QUBOTools.SK(1; normalize = true),
            )
            @test QUBOTools.dimension(m0) == 0
            @test QUBOTools.dimension(m1) == 1
            @test_throws ArgumentError QUBOTools.SK(-1)
        end
    end

    return nothing
end
