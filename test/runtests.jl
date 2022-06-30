using Test
using BQPIO

function main()
    @testset "Domains" begin
        @test BQPIO.domain(BQPIO.QUBO{BQPIO.BoolDomain{Int}}) <: BQPIO.BoolDomain
        @test BQPIO.domain(BQPIO.QUBO{BQPIO.BoolDomain{Int}}()) <: BQPIO.BoolDomain
        @test BQPIO.domain(BQPIO.HFS{BQPIO.BoolDomain{Int}}) <: BQPIO.BoolDomain
        @test BQPIO.domain(BQPIO.HFS{BQPIO.BoolDomain{Int}}()) <: BQPIO.BoolDomain
        @test BQPIO.domain(BQPIO.Qubist{BQPIO.SpinDomain{Int}}) <: BQPIO.SpinDomain
        @test BQPIO.domain(BQPIO.Qubist{BQPIO.SpinDomain{Int}}()) <: BQPIO.SpinDomain
    end
end

main() # Here we go!