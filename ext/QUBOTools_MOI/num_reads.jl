@doc raw"""
    NumberOfReads(ri::Integer)

MOI attribute for the number of reads of a given solution.
"""
struct NumberOfReads <: MOI.AbstractModelAttribute
    result_index::Int

    function NumberOfReads(result_index::Integer = 1)
        @assert result_index > 0

        new(result_index)
    end
end

function MOI.is_set_by_optimize(::NumberOfReads)
    return true
end

# The function takes no arguments and returns the NumberOfReads type.
# Other packages will assign its return value to a constant, e.g.,
#
#     const NumberOfReads = QUBOTools.__moi_num_reads()
#
QUBOTools.__moi_num_reads() = NumberOfReads
