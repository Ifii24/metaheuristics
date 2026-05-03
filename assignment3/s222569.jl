# Assignment 3 — Flexible Job-Shop Scheduling
# Algorithm: Simulated Annealing with reheating
#
# Usage:
#   julia s222569.jl <instance.txt> <solution.txt> <time_limit_seconds>
# Example:
#   julia s222569.jl tai10_10_1.txt tai_sol_10_10_1.txt 60

function read_instance(filename::String)
    f = open(filename)
    readline(f)  # comment
    n_jobs, n_processors, UB = parse.(Int, split(readline(f)))
    readline(f)  # comment
    duration  = zeros(Int, n_jobs, n_processors)
    for i in 1:n_jobs
        duration[i, :] = parse.(Int, split(readline(f)))
    end
    readline(f)  # comment
    processor = zeros(Int, n_jobs, n_processors)
    for i in 1:n_jobs
        processor[i, :] = parse.(Int, split(readline(f)))
    end
    close(f)
    return n_jobs, n_processors, UB, duration, processor
end

function initial_solution(n_jobs, n_processors, processor, duration)
    operations      = [(j, o) for j in 1:n_jobs for o in 1:n_processors]
    P_AV_ST         = zeros(Int, n_processors)
    J_FT            = zeros(Int, n_jobs)
    ST              = zeros(Int, n_jobs, n_processors)
    FT              = zeros(Int, n_jobs, n_processors)
    schedule        = [Vector{Tuple{Int,Int}}() for _ in 1:n_processors]

    while !isempty(operations)
        for proc in 1:n_processors
            ops_for_proc = filter(op -> processor[op[1], op[2]] == proc, operations)
            isempty(ops_for_proc) && continue
            selected  = ops_for_proc[rand(1:length(ops_for_proc))]
            j, oper   = selected
            ST[j, oper]       = max(P_AV_ST[proc], J_FT[j])
            FT[j, oper]       = ST[j, oper] + duration[j, oper]
            P_AV_ST[proc]     = FT[j, oper]
            J_FT[j]           = FT[j, oper]
            push!(schedule[proc], (j, oper))
            operations = filter(o -> o != selected, operations)
        end
    end
    return schedule, ST, FT, maximum(FT)
end

function swap_and_evaluate(schedule, n_processors, n_jobs, processor, duration)
    proc       = rand(1:n_processors)
    ops        = collect(1:length(schedule[proc]))
    i, j       = rand(ops), rand(ops)
    while i == j
        j = rand(ops)
    end

    ST              = zeros(Int, n_processors, n_jobs)
    FT              = zeros(Int, n_processors, n_jobs)
    FT_last         = zeros(Int, n_processors)
    schedule[proc][i], schedule[proc][j] = schedule[proc][j], schedule[proc][i]

    for operation in 1:n_processors
        for job in 1:n_jobs
            jj, oper = schedule[job][operation]
            ft_proc  = FT_last[processor[jj, oper]]
            max_ft_j = maximum(FT[jj, :])
            ST[jj, oper]                    = max(ft_proc, max_ft_j)
            FT[jj, oper]                    = ST[jj, oper] + duration[jj, oper]
            FT_last[processor[jj, oper]]    = FT[jj, oper]
        end
    end
    return schedule, ST, FT, maximum(FT_last)
end

function elapsed_time(starttime)
    return round((time_ns() - starttime) / 1e9, digits=3)
end

function simulated_annealing(starttime, timelimit::Int64, n_jobs, n_processors, duration, processor)
    schedule, ST, FT, completion_time = initial_solution(n_jobs, n_processors, processor, duration)

    T            = 1000.0
    cooling_rate = 0.97
    iter         = 0
    best_ct      = completion_time
    best_schedule = deepcopy(schedule)
    best_ST      = deepcopy(ST)
    best_FT      = deepcopy(FT)

    while elapsed_time(starttime) < timelimit
        new_schedule, new_ST, new_FT, new_ct = swap_and_evaluate(schedule, n_processors, n_jobs, processor, duration)

        delta = new_ct - completion_time
        if delta < 0 || rand() < exp(-delta / T)
            FT              = new_FT
            ST              = new_ST
            schedule        = new_schedule
            completion_time = new_ct
            iter            = 0
            if completion_time <= best_ct
                best_ct       = completion_time
                best_ST       = copy(ST)
                best_FT       = copy(FT)
                best_schedule = copy(schedule)
            end
        else
            iter += 1
        end

        T *= cooling_rate

        # Reheat if stuck for too long
        if iter > 2000
            T    = 1000.0
        end
    end
    return best_ST, best_FT, best_ct, best_schedule
end

function main(instance_filename::String, solution_filename::String, timelimit::Int64)
    n_jobs, n_processors, UB, duration, processor = read_instance(instance_filename)
    starttime = time_ns()
    best_ST, best_FT, best_ct, best_schedule = simulated_annealing(starttime, timelimit, n_jobs, n_processors, duration, processor)

    open(solution_filename, "w") do f
        for i in 1:size(best_ST, 1)
            for j in 1:size(best_ST, 2)
                write(f, string(best_ST[i, j], " "))
            end
            write(f, "\n")
        end
    end
end

main(ARGS[1], ARGS[2], parse(Int64, ARGS[3]))
