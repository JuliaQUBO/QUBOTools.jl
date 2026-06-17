using Test
using Random
using QUBOTools

include("scale.jl")

if _scale_tests_enabled()
    test_scale()
else
    @info "Set QUBOTOOLS_SCALE_TESTS=true to run the scale-test tier"
end
