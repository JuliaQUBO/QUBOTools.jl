# Model 1 ~ Simple model with linear terms

$$
\left\lbrace
\begin{align*}
f(x_2, x_4, x_6) & = 1.3 x_2 - 0.7 x_6 \\[1ex]
H(s_2, s_4, s_6) & = 0.65 s_2 - 0.35 s_6
\end{align*}
\right.
$$

## Status Table

| Format   | Domain | Status |
| :------- | :----: | :----: |
| BQPJSON  |  Bool  |   ✔️    |
| BQPJSON  |  Spin  |   ✔️    |
| MiniZinc |  Bool  |   ✔️    |
| MiniZinc |  Spin  |   ✔️    |
| QUBO     |  Bool  |   ✔️    |
| Qubist   |  Spin  |   ✔️    |
