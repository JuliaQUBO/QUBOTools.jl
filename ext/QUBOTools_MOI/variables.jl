# This will fall back to the integer ordering method.
QUBOTools.varlt(u::VI, v::VI) = QUBOTools.varlt(u.value, v.value)

QUBOTools.varshow(io::IO, v::VI) = QUBOTools.varshow(io, v.value)
