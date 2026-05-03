# Assignment 1 — Sequential Ordering Problem (SOP)
# Algorithm: Greedy construction + 2-opt local search + ILS perturbation
#
# Usage:
#   julia s222569.jl <instance.sop> <solution.sol> <time_limit_seconds>
# Example:
#   julia s222569.jl br17.12.sop br17.12.sol 60

start = time_ns()
using Random

function read_instance(filename)
    f = open(filename)
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

function generate_predecessor_table(cost, dim)
    pred = Vector{Vector{Int64}}(undef, dim)
    for i in 1:dim
        pred[i] = findall(x -> x == -1, cost[i, :])
    end
    return pred
end

function find_first_node(dim, pred)
    initial_node = 0
    for i in 1:dim
        if isempty(pred[i])
            initial_node = i
            break
        end
    end
    visited               = zeros(Bool, dim)
    route                 = Int[]
    visited[initial_node] = true
    push!(route, initial_node)
    return visited, route, 0, 0
end

function sort_cost_table(cost, dim)
    # For each city, sorted indices of all cities by ascending travel cost
    return [sortperm(cost[i, :]) for i in 1:dim]
end

function find_potential_neighbors(pred, visited, dim)
    # A node is feasible if unvisited and all its predecessors are visited
    return [(!visited[i] && all(j -> visited[j], pred[i])) for i in 1:dim]
end

function choose_neighbor(visited, route, sorted, potential_neighbor, dim)
    for i in 1:dim
        candidate = sorted[route[end]][i]
        if !visited[candidate] && potential_neighbor[candidate]
            return candidate
        end
    end
    return nothing
end

function update_route(route, total_dist, cost, next_node, visited)
    total_dist         += cost[route[end], next_node]
    push!(route, next_node)
    visited[next_node]  = true
    return total_dist, route
end

function build_const_heuristic(pred, visited, route, cost, dim, sorted, total_dist)
    while length(route) < dim
        potential_neighbor = find_potential_neighbors(pred, visited, dim)
        next_node          = choose_neighbor(visited, route, sorted, potential_neighbor, dim)
        total_dist, route  = update_route(route, total_dist, cost, next_node, visited)
    end
    return copy(route), copy(total_dist)
end

function is_allowed(route, dim, pred)
    for i in 1:dim
        node_loc = findfirst(x -> x == i, route)
        for j in pred[i]
            pred_loc = findfirst(x -> x == j, route)
            if isnothing(node_loc) || isnothing(pred_loc) || node_loc < pred_loc
                return false
            end
        end
    end
    return true
end

function two_opt_swap(route, i, j)
    new_route = copy(route)
    reverse!(new_route, i, j)
    return new_route
end

function two_opt(dim, route, cost, pred)
    neighborhood = Vector{Vector{Int64}}()
    dist         = Vector{Float64}()
    for i in 2:dim-1
        for j in i+1:dim
            neighbor = two_opt_swap(route, i, j)
            if is_allowed(neighbor, dim, pred)
                d = sum(cost[neighbor[k], neighbor[k+1]] for k in 1:dim-1)
                push!(neighborhood, neighbor)
                push!(dist, d)
            end
        end
    end
    return neighborhood, dist
end

function select_best_neighbor(neighborhood, dist, best_route, best_dist)
    min_idx  = findmin(dist)[2]
    min_dist = dist[min_idx]
    if min_dist < best_dist
        return min_dist, neighborhood[min_idx]
    end
    return best_dist, best_route
end

function local_search(dim, cost, pred, route, dist)
    neighborhood, dists = two_opt(dim, route, cost, pred)
    new_dist, new_route = select_best_neighbor(neighborhood, dists, route, dist)
    if new_dist < dist
        return local_search(dim, cost, pred, new_route, new_dist)
    end
    return dist, route
end

function perturbation(best_route, dim, cost, pred, best_dist, time_limit)
    while time_limit > round((time_ns() - start) / 1e9, digits=3)
        perturbed             = copy(best_route)
        idx                   = randperm(dim)[1:4]
        perturbed[idx]        = perturbed[idx[randperm(4)]]
        if is_allowed(perturbed, dim, pred)
            p_dist            = sum(cost[perturbed[i], perturbed[i % dim + 1]] for i in 1:dim)
            new_dist, new_route = local_search(dim, cost, pred, perturbed, p_dist)
            if new_dist < best_dist
                best_route = new_route
                best_dist  = new_dist
            end
        end
    end
    return best_dist, best_route
end

function main(filename::String, solution_name::String, time_limit::Int64)
    name, upper_bound, dim, cost = read_instance(filename)
    pred                          = generate_predecessor_table(cost, dim)
    sorted                        = sort_cost_table(cost, dim)
    visited, route, total_dist, _ = find_first_node(dim, pred)
    init_route, init_dist         = build_const_heuristic(pred, visited, route, cost, dim, sorted, total_dist)
    best_dist, best_route         = local_search(dim, cost, pred, init_route, init_dist)
    best_dist, best_route         = perturbation(best_route, dim, cost, pred, best_dist, time_limit)

    open(solution_name, "w") do f
        for i in 1:dim
            write(f, string(best_route[i] - 1, " "))
        end
    end
end

main(ARGS[1], ARGS[2], parse(Int64, ARGS[3]))
