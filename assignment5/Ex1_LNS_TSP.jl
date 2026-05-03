# Assignment 5 — TSP with Large Neighbourhood Search (LNS)
# Algorithm: Nearest-neighbour construction + random destroy + greedy best-insert repair
#
# Usage: edit main() to point to your .tsp file, then run:
#   julia Ex1_LNS_TSP.jl

using Random

#***** Instance reader *********************************************************
# Arguments:
#     filename::String  The full path of the instance file
# Returns:
#     name::String  The name of the TSP instance
#     coord::Array{Float32,2} An array of coordinate pairs (x,y)
#     dim::Int32  The dimention of the coord array
#*******************************************************************************
function readInstance(filename)
    #open file for reading
    file = open(filename)
    #read the name of the instance
    name = split(readline(file))[2]
    #The next two lines are not interesting for us. Skip them
    readline(file);readline(file)
    #Read the size of the instance (the number of cities)
    dim = parse(Int32,split(readline(file))[2])
    #The next two lines are not interesting for us. Skip them
    readline(file);readline(file)
    #Create a Matrix (dim ⋅ 2) to hold the coordinates
    coord = zeros(Float32,dim,2)
    #Read coordinates
    for i in 1:dim
        data = parse.(Float32,split(readline(file)))
        coord[i,:]=data[2:3]
    end
    #Close the file
    close(file)
    #return the data we need
    return name,coord,dim
end

#***** Creates a distance matrix ***********************************************
# Arguments:
#     coord::Array{Float32,2}  An array of coordinate pairs (x,y)
#     dim::Int32  The dimention of the coord array
# Returns:
#     dist::Array{Float32,2} Distance matrix based on the straight line distance
#*******************************************************************************
function getDistanceMatrix(coord::Array{Float32,2},dim::Int32)
    dist = zeros(Int64,dim,dim)
    for i in 1:dim
       for j in 1:dim
            if i!=j
                dist[i,j]=round(sqrt((coord[i,1]-coord[j,1])^2+(coord[i,2]-coord[j,2])^2),digits=0)
            end
        end
    end
    return dist
end


# struct representing a solution
mutable struct TSPSolution
    # we represent a solution as a list of cities.
    route::Array{Int32,1}
    # placeholder for the objective value
    objective::Float32

    # remaininig cities to visit, not yet scheduled
    rem_cities::Array{Int32,1}

    # solution default constructor
    TSPSolution(dim) = new(zeros(Int32,dim),0,Array{Int32,1}[])
end

# given a distance matrix, and a list of visited cities
# returns the city closed to "city"
function get_nearest_neighbor(dist,visited,city)
    # variable to keep track of the smallest distance 
    distance = Inf
    # variable to keep track of the next city
    next =0
    # run through all the cities
    for i in 1:length(dist[city,:])
        # if city is not visited and the distance is smaller
        # than what we have seen
        if !visited[i] && distance>dist[city,i]
            # update the best distance and the next city
            distance = dist[city,i]
            next = i
        end
    end

    #return the next city
    return next
end

# Nearest neighbor construction heuristic
function nearest_neighbor_heuristic(dist,dim)
    # We initialize the empty solution
    sol = TSPSolution(dim)

    # keep track of whcih cities have been visited
    visited = zeros(Bool,dim)

    # we start by assigning the first city and flag it as visited
    sol.route[1] = 1
    visited[1] = true

    # we make a loop where i is the index of the last city inserted
    # since we will be assigning the next (i+1) city, we need to stop at dim-1
    for i in 1:dim-1
        # get the ID of the neighor closest to city in position i (the last one we added)
        j = get_nearest_neighbor(dist, visited, sol.route[i])
        # assign the neighbor to the solution and flag it as visited
        sol.route[i+1] = j
        visited[j]=true

        # update the objective value
        sol.objective += dist[sol.route[i],sol.route[i+1]]
    end
    # we need to remember to add cost between the last ans the first city
    # since we are building a cycle
    sol.objective+=dist[sol.route[1],sol.route[end]]
    
    return sol
end

#--------------------------------------------------------------------------
# LNS
#

function elapsed_time(startTime)
    return round((time_ns()-startTime)/1e9,digits=3)
end

function FullRouteDist(sol,dist)
    res=0
    for i=1:(length(sol.route)-1)
        res+=dist[sol.route[i],sol.route[i+1]]
    end
    res+=dist[sol.route[1],sol.route[end]]
end

# Remove: move city with idx from route to rem_cities
function remove(dist,sol,idx)
    (idx>=1 && idx <=length(sol.route)) || (println("wrong index"); exit(0))
    if idx==1
        prior=length(sol.route)
        next=idx+1
        sol.objective = sol.objective + dist[sol.route[next],sol.route[prior]] - dist[sol.route[prior],sol.route[idx]] - dist[sol.route[idx],sol.route[next]]
    elseif idx==length(sol.route)
        prior=idx-1
        next=1
        sol.objective = sol.objective + dist[sol.route[next],sol.route[prior]] - dist[sol.route[prior],sol.route[idx]] - dist[sol.route[idx],sol.route[next]]
    else
        prior=idx-1
        next=idx+1
        sol.objective = sol.objective + dist[sol.route[prior],sol.route[next]] - dist[sol.route[prior],sol.route[idx]] - dist[sol.route[idx],sol.route[next]]
    end
    city=splice!(sol.route, idx)
    push!(sol.rem_cities,city)
end

function insert_cost(dist,sol,idx,c)
    # cost of inserting city c in position idx
    if idx==1
        return sol.objective + dist[c,sol.route[end]] +dist[c,sol.route[1]] - dist[sol.route[1],sol.route[end]]
    end

    prior=idx-1
    return  sol.objective + dist[sol.route[prior],c]+dist[c,sol.route[idx]] - dist[sol.route[prior],sol.route[idx]]
end

# find the best insert index for city c, return city and index
function best_insert_city(dist,sol,city)
    b_cost=insert_cost(dist,sol,1,city)
    b_idx=1
    for i=2:length(sol.route)
        this_insert_cost=insert_cost(dist,sol,i,city)
        if this_insert_cost<b_cost
            b_cost=this_insert_cost
            b_idx=i
        end
    end
    return (b_cost,b_idx)
end

# destruct function, move random cities from sol.route to sol.rem_cities
function d(dist,sol,no_cities_to_destroy)
    for i=1:no_cities_to_destroy
        idx=rand(1:length(sol.route))
        remove(dist,sol,idx)
    end

    return sol
end


                 
function r(dist,sol)
    while length(sol.rem_cities)>0
        (total_cb_cost,total_cbest_insert_idx)=best_insert_city(dist,sol,sol.rem_cities[1])
        total_rem_cities_idx=1
        for c=2:length(sol.rem_cities)
            (cb_cost,cb_idx)=best_insert_city(dist,sol,sol.rem_cities[c])
            if cb_cost<total_cb_cost
                total_cb_cost=cb_cost
                total_cbest_insert_idx=cb_idx 
                total_rem_cities_idx=c
            end
        end
        sol_before=deepcopy(sol)
        city_to_insert=splice!(sol.rem_cities,total_rem_cities_idx)
        insert!(sol.route,total_cbest_insert_idx,city_to_insert)
        sol.objective=total_cb_cost
    end
    
    return sol
end

function random_solution(dim,dist)
    sol = TSPSolution(dim)
    sol.route=randcycle(MersenneTwister(42), dim)
    for i in 1:dim-1
        sol.objective += dist[sol.route[i],sol.route[i+1]]
    end
    sol.objective+=dist[sol.route[1],sol.route[end]]
    
    return sol
end

function LNS(dist,dim,timelimit)
    startTime=time_ns()

    sol = nearest_neighbor_heuristic(dist,dim)

    # interval for removal, notice problem dependent
    min_delete=2
    max_delete=ceil(dim*0.3)
    if max_delete<=min_delete
        max_delete=min_delete+1
    end
    println("Destroy interval: [", min_delete, " , ", max_delete, "]")
    it=1
    
    while elapsed_time(startTime)<timelimit

        # destroy current solution, moving a number of cities to rem_cities
        sol_t = d(dist,deepcopy(sol),rand(min_delete:max_delete) )

        # repair current solution, re-inserting rem_cities into the route
        sol_t = r(dist,sol_t)

        # if better, change to the new solution
        if sol_t.objective < sol.objective
            sol=sol_t
        end

        # report progress
        if mod(it,1000)==0
            println("it: ", it, "  time: ", elapsed_time(startTime), " < ",timelimit, " obj: ", sol.objective)
        end

        it+=1
    end
    return sol
end

function main()
#    name, coord, dim = readInstance("../Data/tsp_toy.tsp")
#    name, coord, dim = readInstance("../Data/berlin52_7542.tsp")
    name, coord, dim = readInstance("../Data/lin318_42029.tsp")
    
    dist = getDistanceMatrix(coord,dim)

    sol=LNS(dist,dim,60)

    println("Route: ",sol.route)
    println("Objective: ",sol.objective)
end

main()

