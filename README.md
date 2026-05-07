# Metaheuristics & Combinatorial Optimisation

![Julia](https://img.shields.io/badge/Julia-9558B2?style=for-the-badge&logo=julia&logoColor=white)
![Course](https://img.shields.io/badge/DTU-Metaheuristics-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=for-the-badge)

Semester assignments implementing classical metaheuristic algorithms in Julia. Three different combinatorial optimisation problems are studied, each solved with progressively more sophisticated algorithms.

---

## The Problems

### Problem A — Sequential Ordering Problem (SOP)
> Assignments 1, 4, 6

Find the minimum-cost path visiting every node exactly once, subject to **precedence constraints**: some nodes must be visited before others. Constraints are encoded in the cost matrix — a value of `-1` on edge `(i,j)` means node `j` must be visited before node `i`. This is an NP-hard extension of TSP. The challenge is that most local search moves (swaps, reversals) may violate precedence and must be checked before being accepted.

**Objective:** minimise total travel cost.

---

### Problem B — Flexible Job-Shop Scheduling
> Assignment 3

Schedule `n` jobs on `m` processors to minimise **makespan** (total completion time). Each job is a sequence of operations; each operation runs on a specific processor for a fixed duration. Two constraints must always hold: a processor handles one operation at a time, and a job's operations must run in order.

**Objective:** minimise the time at which the last operation finishes.

---

### Problem C — Travelling Salesman Problem (TSP)
> Assignment 5

Find the shortest tour visiting every city exactly once and returning to the start. No precedence constraints, but the focus is on efficient large-scale destroy-and-repair search.

**Objective:** minimise total tour length.

---

## Assignments

### Assignment 1 — SOP: Iterated Local Search

**Steps:**
1. **Construction** — start from the node with no predecessors. Greedily pick the cheapest unvisited node whose predecessors have all been visited.
2. **2-opt local search** — try all pairwise segment reversals, discard any that violate precedence, move to the best improving neighbour. Repeat until no improvement.
3. **Perturbation** — randomly shuffle 4 positions in the best known route. If feasible, re-apply 2-opt. Keep the result if it improves cost. Repeat within time limit.

```bash
julia assignment1/s222569.jl instance.sop solution.sol 60
```

---

### Assignment 2 — Production Scheduling: GRASP

**Problem:** Assign `n` orders to `k` production lines within time horizon `H`. Each order has a production time and earns revenue. Additional pairwise revenue is earned when two orders share a line. Maximise total revenue without exceeding any line's capacity.

**Steps:**
1. **Greedy randomised construction** — for each line, build a Restricted Candidate List (RCL) of orders whose incremental revenue is within `alpha = 0.13` of the best. Randomly pick from the RCL and add if it fits in `H`.
2. **Local search** — try all pairwise order swaps between lines. Accept only if both lines still fit in `H` and total revenue increases. Uses delta-evaluation to avoid full recalculation.
3. **Loop** — repeat construction + local search until time limit. Keep the best solution found.

```bash
julia assignment2/s222569.jl instance.txt solution.sol 60
```

---

### Assignment 3 — Job-Shop Scheduling: Simulated Annealing

**Steps:**
1. **Initial solution** — randomly assign operations to processors, computing start/finish times while respecting processor availability and job order.
2. **Move** — randomly pick a processor and swap two of its operations. Recompute all start/finish times and makespan.
3. **Acceptance** — always accept improvements. Accept a worse solution with probability `exp(-delta/T)`.
4. **Cooling** — multiply `T` by `0.97` each iteration (starts at `T = 1000`).
5. **Reheating** — if 2000 consecutive iterations produce no accepted move, reset `T = 1000` to escape the local region.

```bash
julia assignment3/s222569.jl instance.txt solution.txt 60
```

---

### Assignment 4 — SOP: Tabu Search

**Steps:**
1. **Construction** — same greedy nearest-neighbour heuristic as Assignment 1.
2. **Tabu Search** — find the best valid 2-opt node swap not involving any city in the tabu list. Apply it unconditionally. Add the two swapped cities to a circular tabu list of length `K`.
3. **Diversification** — if stuck for 100 iterations, randomly shuffle ~25% of route positions (checking feasibility) to escape the local region.
4. **Reset** — if still stuck, reset the tabu list with `K = 10` and continue.

```bash
julia assignment4/s222569.jl instance.sop solution.sol 60
```

---

### Assignment 5 — TSP: LNS and ALNS

Three progressively more sophisticated implementations. The core idea: instead of small local moves, **destroy** a chunk of the solution and **repair** it — allowing larger jumps through the search space. All start from a nearest-neighbour construction heuristic.

#### Ex1 — Basic LNS
1. Remove 2–30% of cities at random.
2. Re-insert greedily: at each step, insert the city whose best position gives the lowest cost increase.
3. Accept only improvements.

```bash
julia assignment5/Ex1_LNS_TSP.jl
```

#### Ex2 — ALNS (two destroy operators)
Extends Ex1 with **adaptive operator selection** between two destroy methods:
- `d1` — random removal
- `d2` — remove K seed cities plus their L nearest neighbours (clustered removal)

Each operator has a reward score updated based on solution quality. Better-performing operators are selected more often. Adds a **Simulated Annealing acceptance** criterion so non-improving solutions can occasionally be accepted.

```bash
julia assignment5/Ex2_ALNS_TSP.jl
```

#### Ex3 — Full ALNS (two destroy + two repair operators)
Extends Ex2 with a second repair operator:
- `r1` — greedy best insertion (same as Ex1/Ex2)
- `r2` — regret insertion: insert the city for which the gap between its best and second-best position is largest — prioritises cities that are hardest to place later

Both destroy and repair operators have independent reward and probability vectors, updated separately each iteration.

```bash
julia assignment5/Ex3_ALNS_full.jl
```

---


## Requirements

No external packages — uses Julia standard library only.
