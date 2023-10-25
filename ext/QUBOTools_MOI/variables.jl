# This will fall back to the integer ordering method.
QUBOTools.varlt(u::VI, v::VI) = QUBOTools.varlt(u.value, v.value)

QUBOTools.varshow(v::VI) = QUBOTools.varshow(v.value)
