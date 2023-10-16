@doc raw"""
    NumberOfReads(ri::Integer)

MOI attribute for the number of reads of a given solution.
"""
struct NumberOfReads <: MOI.AbstractModelAttribute
    result_index::Int

    function NumberOfReads(result_index::Integer = 1)
        new(result_index)
    end
end

QUBOTools.__moi_num_reads() = NumberOfReads

function MOI.is_set_by_optimize(::NumberOfReads)
    return true
end

function MOI.supports(::MOI.ModelLike, ::NumberOfReads)
    return true
end

function MOI.get(model::MOI.ModelLike, attr::NumberOfReads)
    MOI.check_result_index_bounds(model, attr)

    # By default, solvers that do not implement their own method
    # will not account for solution multiplicity.
    return 1
end
