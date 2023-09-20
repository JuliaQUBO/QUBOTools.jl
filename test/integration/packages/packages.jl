include("qubodrivers.jl")
include("toqubo.jl")
include("qubo.jl")

function test_packages()
    @testset "▶ Packages" verbose = true begin
        test_qubodrivers_jl()
        test_toqubo_jl()
        test_qubo_jl()
    end

    return nothing
end