# Metaheuristics & Combinatorial Optimisation

![Julia](https://img.shields.io/badge/Julia-9558B2?style=for-the-badge&logo=julia&logoColor=white)
![Course](https://img.shields.io/badge/DTU-Metaheuristics-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=for-the-badge)

Semester assignments implementing classical metaheuristic algorithms in Julia. Each assignment targets a different combinatorial optimisation problem, progressively building from construction heuristics to adaptive search.

---

## Overview

| Assignment | Problem | Algorithm |
|------------|---------|-----------|
| [1 — SOP](#assignment-1--sequential-ordering-problem) | Sequential Ordering Problem | Greedy construction + 2-opt local search + ILS perturbation |
| [2 — Plastic Ordering](#assignment-2--production-scheduling) | Multi-line production scheduling | GRASP (greedy randomised + local search) |
| [3 — Cloud Computing](#assignment-3--flexible-job-shop) | Flexible job-shop scheduling | Simulated Annealing with reheating |
| [4 — SOP Tabu](#assignment-4--sequential-ordering-with-tabu-search) | Sequential Ordering Problem | Tabu Search with diversification |
| [5 — TSP LNS/ALNS](#assignment-5--travelling-salesman-lnsalns) | Travelling Salesman Problem | LNS and Adaptive LNS |
| [6 — SOP Final](#assignment-6--sop-final-submission) | Sequential Ordering Problem | Tabu Search (final submission) |

All scripts accept three command-line arguments: `instance_file`, `solution_file`, `time_limit_seconds`.

```bash
julia s222569.jl instance.sop solution.sol 60
```

---

## Assignment 1 — Sequential Ordering Problem

**Problem:** Find the minimum-cost Hamiltonian path through a set of nodes where some nodes must appear before others (precedence constraints encoded as -1 in the cost matrix).

**Implementation:**
1. **Construction heuristic** — builds an initial feasible route using a nearest-neighbour greedy approach that respects precedence. Starts from the only node with no predecessors, and at each step selects the cheapest unvisited node whose predecessors have all been visited.
2. **2-opt local search** — generates all pairwise segment reversals, filters out those that violate precedence, and repeatedly moves to the best improving neighbour until no improvement is found.
3. **Iterated Local Search (ILS)** — within the time limit, randomly shuffles 4 positions of the best known route (perturbation), checks feasibility, then re-applies 2-opt. Keeps the improvement if it reduces total cost.

---

## Assignment 2 — Production Scheduling

**Problem:** Assign production orders to k manufacturing lines within a planning horizon H to maximise total revenue. Revenue has two components: per-order revenue and pairwise revenue for orders scheduled on the same line.

**Implementation:**
1. **GRASP construction** — for each production line, builds an order schedule using a Restricted Candidate List (RCL). The RCL contains all unassigned orders whose incremental revenue (individual + all pair bonuses with already-scheduled orders) falls within `alpha` of the best. A random order is selected from the RCL and added if it fits within the time horizon. `alpha = 0.13` was tuned empirically.
2. **Local search** — performs all pairwise order swaps between different production lines. A swap is accepted only if it does not violate the time horizon on either line and increases total revenue. Uses delta-evaluation to update revenues without full recalculation.
3. **GRASP loop** — repeats construction + local search until the time limit, keeping the best solution found.

---

## Assignment 3 — Flexible Job-Shop Scheduling

**Problem:** Schedule n jobs across m processors (flexible job-shop) to minimise makespan. Each job has operations that must be processed in order, each on a specific processor.

**Implementation:**
1. **Random initial solution** — assigns operations to processors in random order, computing start/finish times respecting both processor availability and job precedence.
2. **Simulated Annealing** — at each iteration, randomly selects a processor and swaps two of its scheduled operations. Recalculates start/finish times and makespan. Accepts improvements always; accepts worsening moves with probability `exp(-delta/T)`.
3. **Cooling schedule** — temperature starts at 1000 with a cooling rate of 0.97 per iteration.
4. **Reheating** — if 2000 consecutive iterations produce no accepted move, temperature resets to 1000 to escape local optima.

---

## Assignment 4 — Sequential Ordering with Tabu Search

**Problem:** Same as Assignment 1 (SOP) but solved with Tabu Search instead of ILS.

**Implementation:**
1. **Construction** — same greedy nearest-neighbour heuristic as Assignment 1.
2. **Tabu Search** — at each iteration, finds the best valid 2-opt swap (node pair exchange) not involving any city currently in the tabu list. Applies the swap unconditionally (aspiration not implemented). The two swapped cities are added to the circular tabu list of length K.
3. **Diversification** — if 100 iterations pass without improvement, randomly shuffles ~25% of the route positions (checking feasibility) to escape the local region.
4. **Tabu list reset** — alternates between diversification and resetting K to 10 when stagnation persists.

---

## Assignment 5 — Travelling Salesman: LNS/ALNS

Three progressively more sophisticated implementations for the TSP. All start from a nearest-neighbour construction heuristic.

### Ex1 — Basic LNS
Destroy-repair loop: randomly removes 2–30% of cities from the route, then re-inserts them using a greedy best-insertion repair (the city with the best insertion position across all remaining cities is inserted first). Accepts only improvements.

### Ex2 — ALNS with two destroy operators
Extends LNS with adaptive operator selection across two destroy methods:
- **d1** — random removal of cities
- **d2** — removal of K seed cities plus their L nearest neighbours (clustered removal)

Operator selection probabilities are updated using a reward-decay scheme (rho vector). A Simulated Annealing acceptance criterion replaces pure improvement-only acceptance, allowing non-improving moves to escape local optima.

### Ex3 — Full ALNS with two destroy + two repair operators
Extends Ex2 with a second repair operator:
- **r1** — greedy best insertion (same as Ex1/Ex2)
- **r2** — regret-based insertion: inserts the city for which the cost difference between its best and second-best position is largest, prioritising cities that are hardest to place later

Both destroy and repair operators have independent probability and reward vectors, updated separately at each iteration.

---

## Assignment 6 — SOP Final Submission

**Problem:** Sequential Ordering Problem, final graded submission.

**Implementation:** Tabu Search combining systematic and random neighbourhood search. Builds an initial feasible route with a greedy construction heuristic respecting precedence. Iterates between full exhaustive swap search (checking all i,j pairs) and random swap search (for diversification when stuck for >100 iterations without improvement). All visited solutions are stored in a tabu set to avoid revisiting. Best solution found within the time limit is written to the output file.

---

## Requirements

```julia
# No external packages required — uses Julia standard library only
julia s222569.jl <instance> <solution> <timelimit>
```
