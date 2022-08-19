QUBOTools.energy(state, model) = QUBOTools.energy(state, QUBOTools.backend(model))

QUBOTools.qubo(model) = QUBOTools.qubo(QUBOTools.backend(model))
QUBOTools.ising(model) = QUBOTools.ising(QUBOTools.backend(model))