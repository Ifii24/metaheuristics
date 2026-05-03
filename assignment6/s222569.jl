# Assignment 6 — Sequential Ordering Problem (SOP) — Final Submission
# Algorithm: Tabu Search with systematic + random neighbourhood search
#
# Usage:
#   julia s222569.jl <instance.sop> <solution.sol> <time_limit_seconds>
# Example:
#   julia s222569.jl ft53.2.sop ft53.2.sol 60

function read_instance(filename)
    f           = open(filename)
    name        = split(readline(f))[2]
    upper_bound = parse(Int64, split(readline(f))[2])
    readline(f); readline(f)              # type, comment
    dim         = parse(Int64, split(readline(f))[2])
    readline(f); readline(f); readline(f); readline(f)  # Edge1-3, dimension 2
    cost = zeros(Int64, dim, dim)
    for i in 1:dim
        cost[i, :] = parse.(Int64, split(readline(f)))
    end
    close(f)
    return name, upper_bound, dim, cost
end

function route_cost(route, cost, n)
    total = 0.0
    for i in 1:n-1
        total += cost[route[i], route[i+1]]
    end
    return total
end

# Greedy construction respecting precedence constraints (cost[i,j] == -1 means j must precede i)
function build_initial_route(dim, costs)
    route    = []
    possible = []

    while length(route) < dim
        for _ in 1:dim
            for i in 1:dim
                if !(i in route)
                    # Check all predecessors are already in the route
                    feasible = all(j -> !(costs[i, j] == -1 && !(j in route)), 1:dim)
                    feasible && push!(possible, i)
                end
            end

            if length(route) > 0
                best_city = possible[1]
                best_dist = Inf
                for k in 1:length(possible)
                    if costs[route[end], possible[k]] < best_dist
                        best_dist = costs[route[end], possible[k]]
                        best_city = possible[k]
                    end
                end
                push!(route, best_city)
            else
                push!(route, possible[1])
            end
            possible = []
        end
    end
    return route
end

# Check if swapping positions i and j keeps all precedence constraints satisfied
function is_swap_feasible(route, cost, i, j)
    if i > j
        i, j = j, i
    end
    for k in 1:(j - i)
        if cost[route[j], route[j-k]] == -1 || cost[route[i+k], route[i]] == -1
            return false
        end
    end
    return true
end

# Exhaustive swap search over all (i, j) pairs — systematic neighbourhood
function swap_search(cost, route, n, tabu_list)
    best       = copy(route)
    best_found = []
    cost_found = Inf

    for i in 2:n-1
        for j in 2:n-1
            i == j && continue
            if is_swap_feasible(best, cost, i, j)
                best[j], best[i] = best[i], best[j]
                if !(best in tabu_list)
                    copy_best = copy(best)
                    push!(tabu_list, copy_best)
                    current_cost = route_cost(copy_best, cost, n)
                    if current_cost < cost_found
                        best_found = copy(best)
                        cost_found = copy(current_cost)
                    end
                end
                best[j], best[i] = best[i], best[j]  # undo swap
            end
        end
    end
    return best_found, cost_found, tabu_list
end

# Random swap search — used for diversification when stuck
function swap_search_rand(cost, route, n, tabu_list)
    best       = copy(route)
    best_found = []
    cost_found = Inf
    count      = 0

    while count < (n - 1) / 2
        i = rand(1:n)
        j = rand([1:(i-1); (i+1):n])
        if is_swap_feasible(best, cost, i, j)
            best[j], best[i] = best[i], best[j]
            if !(best in tabu_list)
                copy_best    = copy(best)
                push!(tabu_list, copy_best)
                current_cost = route_cost(copy_best, cost, n)
                if current_cost < cost_found
                    best_found = copy(best)
                    cost_found = copy(current_cost)
                end
            end
        end
        count += 1
    end
    return best_found, cost_found, tabu_list
end

function elapsed_time(startTime)
    return round((time_ns() - startTime) / 1e9, digits=3)
end

function main(instance_filename::String, solution_filename::String, timelimit::Int64)
    name, upper_bound, dim, cost = read_instance(instance_filename)

    initial_sol  = build_initial_route(dim, cost)
    initial_cost = route_cost(initial_sol, cost, dim)

    sol       = initial_sol
    sol_cost  = initial_cost
    best_sol  = copy(sol)
    best_cost = sol_cost

    tabu_list  = Set()
    push!(tabu_list, copy(sol))
    startTime  = time_ns()
    count      = 0
    last_count = 0

    while elapsed_time(startTime) < timelimit
        # Switch to random search for diversification when stuck for 100 iterations
        if count - last_count > 100
            sol, sol_cost, tabu_list = swap_search_rand(cost, sol, dim, tabu_list)
            last_count = count
        else
            sol, sol_cost, tabu_list = swap_search(cost, sol, dim, tabu_list)
        end

        isempty(sol) && break

        if sol_cost < best_cost
            best_sol   = copy(sol)
            best_cost  = sol_cost
            last_count = count
        end
        count += 1
    end

    best_sol .-= 1
    open(solution_filename, "w") do f
        write(f, join(best_sol, " "))
    end
end

main(ARGS[1], ARGS[2], parse(Int64, ARGS[3]))
