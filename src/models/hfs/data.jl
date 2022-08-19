struct CHIMERA_CELL_SIZE <: QUBOAttribute end

QUBOTools._defaultattr(::HFS, ::CHIMERA_CELL_SIZE) = 8

struct CHIMERA_PRECISION <: QUBOAttribute end

QUBOTools._defaultattr(::HFS, ::CHIMERA_PRECISION) = 5