@doc raw"""
    AbstractForm{T}
"""
abstract type AbstractForm{T} end

@doc raw"""
    form
"""
function form end

@doc raw"""
    linear_form
"""
function linear_form end

@doc raw"""
    quadratic_form
"""
function quadratic_form end
