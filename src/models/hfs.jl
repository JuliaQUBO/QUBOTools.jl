@doc raw"""
""" struct HFS{D <: BoolDomain} <: Model{D}

    function HFS{D}() where D <: BoolDomain
        new{D}()
    end

    function HFS()
        HFS{BoolDomain}()
    end
end