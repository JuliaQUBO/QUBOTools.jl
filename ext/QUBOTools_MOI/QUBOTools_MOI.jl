module QUBOTools_MOI

import QUBOTools
import MathOptInterface as MOI

const MOIU    = MOI.Utilities
const VI      = MOI.VariableIndex
const CI{F,S} = MOI.ConstraintIndex{F,S}
const SAF{T}  = MOI.ScalarAffineFunction{T}
const SAT{T}  = MOI.ScalarAffineTerm{T}
const SQF{T}  = MOI.ScalarQuadraticFunction{T}
const SQT{T}  = MOI.ScalarQuadraticTerm{T}

include("error.jl")
include("varlt.jl")
include("spin_set.jl")
include("qubo_model.jl")
include("sense.jl")
include("model_parser.jl")

end