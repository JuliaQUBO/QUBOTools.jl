using Test
using Printf
using SparseArrays
using QUBOTools
import QUBOTools: ↑, ↓, 𝔹, 𝕊
import QUBOTools: Sample, SampleSet, SampleError, sample_error
import QUBOTools: CodecError, codec_error
import QUBOTools: state, value, reads
import QUBOTools: backend

# ~*~ Include test functions ~*~
include("tools/tools.jl")
include("unit/unit.jl")
include("integration/integration.jl")

function test_main()
    @testset "◈ ◈ QUBOTools.jl Test Suite ◈ ◈" verbose = true begin
        test_unit()
        test_integration()
    end
end

test_main() # Here we go!