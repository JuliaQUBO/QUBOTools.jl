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

QUBOTools.__moi_spin_set() = Spin
