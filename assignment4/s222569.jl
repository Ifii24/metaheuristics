# Assignment 4 — Sequential Ordering Problem (SOP)
# Algorithm: Tabu Search with route diversification
#
# Usage:
#   julia s222569.jl <instance.sop> <solution.sol> <time_limit_seconds>
# Example:
#   julia s222569.jl ESC47.sop ESC47.sol 60

start_time = time_ns()
import Random

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
    return [sortperm(cost[i, :]) for i in 1:dim]
end

function find_potential_neighbors(pred, visited, dim)
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
    total_dist        += cost[route[end], next_node]
    push!(route, next_node)
    visited[next_node] = true
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

function are_predecessors_met(city, i, route, pred)
    for p in pred[city]
        if !(p in route[1:i-1])
            return false
        end
    end
    return true
end

function is_swap_valid(route, swap_i, swap_j, pred, dim)
    modified       = deepcopy(route)
    modified[swap_i], modified[swap_j] = route[swap_j], route[swap_i]
    for i in 1:dim
        if !are_predecessors_met(modified[i], i, modified, pred)
            return false
        end
    end
    return true
end

function route_cost(route, cost)
    return sum(cost[route[i], route[i+1]] for i in 1:length(route)-1)
end

function best_two_opt_swap(dim, route, tabu_list, pred, cost)
    opt_cost  = Inf
    opt_i     = 0
    opt_j     = 0
    for i in 2:(length(route) - 1)
        route[i] in tabu_list && continue
        for j in (i + 1):length(route)
            route[j] in tabu_list && continue
            if is_swap_valid(route, i, j, pred, dim)
                temp        = deepcopy(route)
                temp[i], temp[j] = temp[j], temp[i]
                new_cost    = route_cost(temp, cost)
                if new_cost < opt_cost
                    opt_cost = new_cost
                    opt_i    = i
                    opt_j    = j
                end
            end
        end
    end
    return opt_cost, opt_i, opt_j
end

function update_tabu_list(tabu_list, counter, new_element)
    tabu_list[counter] = new_element
    return tabu_list, counter % length(tabu_list) + 1
end

function check_route_validity(route, pred, dim)
    for city_idx in 1:dim
        current_city = route[city_idx]
        for predecessor in pred[current_city]
            if isnothing(findfirst(==(predecessor), route[1:city_idx-1]))
                return false
            end
        end
    end
    return true
end

function route_diversification(route, pred, dim)
    diversified = deepcopy(route)
    while true
        diversified    = deepcopy(route)
        n_shuffle      = max(4, div(dim, 4))
        shuffle_idx    = collect(Set(Random.rand(1:dim) for _ in 1:n_shuffle*3))[1:n_shuffle]
        shuffled_idx   = Random.shuffle(shuffle_idx)
        for i in 1:length(shuffle_idx)
            diversified[shuffle_idx[i]] = route[shuffled_idx[i]]
        end
        check_route_validity(diversified, pred, dim) && break
    end
    return diversified
end

function elapsed_time(t)
    return round((time_ns() - t) / 1e9, digits=3)
end

function tabu_search(cost, dim, pred, init_route, init_cost, K, time_limit)
    tabu_list, tabu_counter = zeros(Int64, K), 1
    opt_route   = deepcopy(init_route)
    opt_cost    = deepcopy(init_cost)
    route       = deepcopy(init_route)
    no_impr     = 0
    threshold   = 100
    use_diversify = true

    while elapsed_time(start_time) < time_limit
        current_cost, swap_i, swap_j = best_two_opt_swap(dim, route, tabu_list, pred, cost)

        if swap_i != 0 && swap_j != 0
            tabu_list, tabu_counter = update_tabu_list(tabu_list, tabu_counter, opt_route[swap_i])
            tabu_list, tabu_counter = update_tabu_list(tabu_list, tabu_counter, opt_route[swap_j])
            route[swap_i], route[swap_j] = route[swap_j], route[swap_i]
        else
            tabu_list, tabu_counter = update_tabu_list(tabu_list, tabu_counter, 0)
            tabu_list, tabu_counter = update_tabu_list(tabu_list, tabu_counter, 0)
        end

        if current_cost < opt_cost
            opt_cost  = deepcopy(current_cost)
            opt_route = deepcopy(route)
            no_impr   = 0
        else
            no_impr += 1
        end

        if no_impr >= threshold
            if use_diversify
                route         = route_diversification(route, pred, dim)
                use_diversify = false
            else
                K             = 10
                tabu_list     = zeros(Int64, K)
                tabu_counter  = 1
                use_diversify = true
            end
            no_impr = 0
        end
    end
    return opt_route, opt_cost
end

function main(filename::String, solution_name::String, time_limit::Int64)
    name, UB, dim, cost = read_instance(filename)
    pred                 = generate_predecessor_table(cost, dim)
    sorted               = sort_cost_table(cost, dim)
    visited, route, total_dist, _ = find_first_node(dim, pred)
    init_route, init_cost = build_const_heuristic(pred, visited, route, cost, dim, sorted, total_dist)
    K                    = rand(4:div(dim, 2))
    opt_route, opt_cost  = tabu_search(cost, dim, pred, init_route, init_cost, K, time_limit)

    open(solution_name, "w") do f
        for i in 1:dim
            write(f, string(opt_route[i] - 1, " "))
        end
    end
end

main(ARGS[1], ARGS[2], parse(Int64, ARGS[3]))
