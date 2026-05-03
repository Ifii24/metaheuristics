# Assignment 2 — Production Scheduling (PlastOut)
# Algorithm: GRASP — greedy randomised construction + pairwise swap local search
#
# Usage:
#   julia s222569.jl <instance.txt> <solution.sol> <time_limit_seconds>
# Example:
#   julia s222569.jl jeu_100_25_3_1.txt jeu_100_25_3_1.sol 60

function read_instance(filename)
    f        = open(filename)
    name     = readline(f)
    size     = parse(Int32, readline(f))
    LB       = parse(Int32, readline(f))
    rev      = parse.(Int32, split(readline(f)))
    rev_pair = zeros(Int32, size, size)
    for i in 1:size-1
        data = parse.(Int32, split(readline(f)))
        j = i + 1
        for d in data
            rev_pair[i, j] = d
            rev_pair[j, i] = d
            j += 1
        end
    end
    readline(f)
    k = parse(Int32, readline(f))
    H = parse(Int32, readline(f))
    p = parse.(Int32, split(readline(f)))
    close(f)
    return name, size, LB, rev, rev_pair, k, H, p
end

mutable struct PlastOut
    prodTime::Int32
    orders::Vector{Int32}
    revenue::Int32
end

# Incremental revenue gained by adding next_prod to the given production line
function incremental_revenue(rev, rev_pair, next_prod, prod_lines, line_idx)
    add_rev = rev[next_prod]
    for j in prod_lines[line_idx].orders
        add_rev += rev_pair[j, next_prod]
    end
    return add_rev
end

# GRASP construction: fill each production line greedily with randomisation via RCL
function generate_initial_solution(k, rev, rev_pair, size, alpha, H, p)
    prod_lines = [PlastOut(0, [], 0) for _ in 1:k]
    assigned   = fill(false, size)

    for line_idx in 1:k
        full = false
        while !full
            unassigned = [i for i in 1:size if !assigned[i]]
            inc_rev    = [incremental_revenue(rev, rev_pair, prod, prod_lines, line_idx) for prod in unassigned]
            c_max      = maximum(inc_rev)
            c_min      = minimum(inc_rev)
            RCL        = [unassigned[i] for i in 1:length(unassigned) if inc_rev[i] >= c_max - alpha * (c_max - c_min)]

            if isempty(RCL)
                full = true
            else
                next_prod = RCL[rand(1:length(RCL))]
                if prod_lines[line_idx].prodTime + p[next_prod] <= H
                    assigned[next_prod] = true
                    push!(prod_lines[line_idx].orders, next_prod)
                    prod_lines[line_idx].prodTime += p[next_prod]
                    prod_lines[line_idx].revenue  += incremental_revenue(rev, rev_pair, next_prod, prod_lines, line_idx)
                else
                    full = true
                end
            end
        end
    end
    return prod_lines
end

function can_swap(prod_lines, i, j, prod_i, prod_j, p, H)
    new_time_i = prod_lines[i].prodTime - p[prod_i] + p[prod_j]
    new_time_j = prod_lines[j].prodTime - p[prod_j] + p[prod_i]
    if new_time_i <= H && new_time_j <= H
        return true, new_time_i, new_time_j
    end
    return false, new_time_i, new_time_j
end

function do_swap!(prod_lines, line_i, line_j, idx_i, idx_j, i, j, rev, rev_pair, p, H)
    allowed, new_time_i, new_time_j = can_swap(prod_lines, i, j, line_i.orders[idx_i], line_j.orders[idx_j], p, H)
    if !allowed
        return
    end
    # Delta-evaluate: subtract each order's contribution before swapping
    line_i.revenue -= incremental_revenue(rev, rev_pair, line_i.orders[idx_i], prod_lines, i)
    line_j.revenue -= incremental_revenue(rev, rev_pair, line_j.orders[idx_j], prod_lines, j)
    # Perform the swap
    line_i.orders[idx_i], line_j.orders[idx_j] = line_j.orders[idx_j], line_i.orders[idx_i]
    # Add new contributions after swap
    line_i.revenue += incremental_revenue(rev, rev_pair, line_i.orders[idx_i], prod_lines, i)
    line_j.revenue += incremental_revenue(rev, rev_pair, line_j.orders[idx_j], prod_lines, j)
    # Update production times
    line_i.prodTime = new_time_i
    line_j.prodTime = new_time_j
end

function local_search(prod_lines, k, H, p, rev, rev_pair)
    total_rev = sum(prod_lines[l].revenue for l in 1:k)
    for i in 1:(k-1)
        for j in (i+1):k
            line_i = prod_lines[i]
            line_j = prod_lines[j]
            for idx_i in 1:length(line_i.orders)
                for idx_j in 1:length(line_j.orders)
                    do_swap!(prod_lines, line_i, line_j, idx_i, idx_j, i, j, rev, rev_pair, p, H)
                    new_rev = sum(prod_lines[l].revenue for l in 1:k)
                    if total_rev > new_rev
                        # Swap worsened revenue — swap back
                        do_swap!(prod_lines, line_i, line_j, idx_i, idx_j, i, j, rev, rev_pair, p, H)
                    else
                        total_rev = new_rev
                    end
                end
            end
        end
    end
    return prod_lines
end

function elapsed_time(start_time)
    return round((time_ns() - start_time) / 1e9, digits=3)
end

function main(filename::String, solution_name::String, timelimit::Int64)
    name, size, LB, rev, rev_pair, k, H, p = read_instance(filename)

    alpha     = 0.13  # RCL greediness parameter (tuned empirically)
    best_rev  = 0
    best_sol  = [PlastOut(0, [], 0) for _ in 1:k]
    start_time = time_ns()

    while elapsed_time(start_time) < timelimit
        sol     = generate_initial_solution(k, rev, rev_pair, size, alpha, H, p)
        sol     = local_search(sol, k, H, p, rev, rev_pair)
        sol_rev = sum(sol[l].revenue for l in 1:k)
        if sol_rev > best_rev
            best_sol = sol
            best_rev = sol_rev
        end
    end

    open(solution_name, "w") do f
        write(f, " ")
        for line in best_sol
            write(f, join(string.(line.orders), " ") * "\n")
        end
    end
end

main(ARGS[1], ARGS[2], parse(Int64, ARGS[3]))
