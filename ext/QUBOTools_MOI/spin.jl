@doc raw"""
    Spin()

The set ``\left\lbrace{}{\pm 1}\right\rbrace{}``.
"""
struct Spin <: MOI.AbstractScalarSet end

function MOIU._to_string(options::MOIU._PrintOptions, ::Spin)
    return string(MOIU._to_string(options, ∈), " {±1}")
end

function MOIU._to_string(::MOIU._PrintOptions{MIME"text/latex"}, ::Spin)
    return raw"\in \left\lbrace{}{\pm 1}\right\rbrace{}"
end

# Since extensions do not allow new types to be defined and exported (only
# methods), we can still provide a type by first defining an empty function
# and then defining an "argless" method to retrive it, requiring that the
# packages call it, assigning its return value to a constant, e.g.,
# 
#     const Spin = QUBOTools.__moi_spin_set()

QUBOTools.__moi_spin_set() = Spin
