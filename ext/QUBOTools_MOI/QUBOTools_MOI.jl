module QUBOTools_MOI

import QUBOTools
import MathOptInterface as MOI

const MOIU = MOI.Utilities
const VI = MOI.VariableIndex

include("error.jl")
include("varlt.jl")
include("spin.jl")
include("sense.jl")
include("model.jl")

end