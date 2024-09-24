using Test
using Printf
using Pkg
using Pkg.Types: PkgError
using SparseArrays
using Statistics
using RecipesBase
using QUBOTools
using Graphs
using MathOptInterface

# using QUBODrivers
# using ToQUBO
# using QUBO

const MOI    = MathOptInterface
const MOIU   = MOI.Utilities
const VI     = MOI.VariableIndex
const SAF{T} = MOI.ScalarAffineFunction{T}
const SAT{T} = MOI.ScalarAffineTerm{T}
const SQF{T} = MOI.ScalarQuadraticFunction{T}
const SQT{T} = MOI.ScalarQuadraticTerm{T}

const QUBOTools_MOI = Base.get_extension(QUBOTools, :QUBOTools_MOI)
const Spin          = QUBOTools_MOI.Spin
const QUBOModel     = QUBOTools_MOI.QUBOModel
const NumberOfReads = QUBOTools_MOI.NumberOfReads

const __TEST_PATH__ = @__DIR__

# Include assets
include("assets/comparison.jl")
include("assets/foreign_tests.jl")

# Include test functions
include("unit/unit.jl")
include("integration/integration.jl")

function test_main()
    @testset "◈ ◈ ◈ QUBOTools.jl Test Suite ◈ ◈ ◈" verbose = true begin
        test_unit()
        test_integration()
    end

    return nothing
end

test_main() # Here we go!
