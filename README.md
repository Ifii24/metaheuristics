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
