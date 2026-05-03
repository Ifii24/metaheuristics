# Assignment 5 — TSP with Adaptive LNS (two destroy operators)
# Algorithm: NN construction + ALNS with d1 (random) and d2 (cluster) destroy, SA acceptance
#
# Usage: edit main() to point to your .tsp file, then run:
#   julia Ex2_ALNS_TSP.jl

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

# for each city, list the neighbors in order
function neighbourMatrix(dist,dim)
    dist2=deepcopy(dist)
    neigh = zeros(Int64,dim,dim)
    for i in 1:dim
        neigh[i,i]=dim+1
        dist2[i,i]=100000000
        for n in 1:(dim-1)
            cur_min=100000000-1
            cur_min_idx=-1
            for j in 1:dim
                if i!=j && dist2[i,j]<cur_min
                    cur_min=dist2[i,j]
                    cur_min_idx=j
                end
            end
            if cur_min_idx<0
                println("error")
                exit(0)
            end
            neigh[i,cur_min_idx]=n
            dist2[i,cur_min_idx]=100000000-1
        end
    end

    return neigh
end

# struct representing a solution
mutable struct TSPSolution
    # we represent a solution as a list of cities.
    route::Array{Int32,1}
    # placeholder for the objective value
    objective::Float32

    # remaininig cities to visit, not yet scheduled
    rem_cities::Array{Int32,1}

    # Solution default constructor
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
# ALNS
#

# Random solution construction
function random_solution(dist,dim)
    sol = TSPSolution(dim)
#    sol.route=randcycle(MersenneTwister(42), dim)
    sol.route=randcycle(dim)
    for i in 1:dim-1
        sol.objective += dist[sol.route[i],sol.route[i+1]]
    end
    sol.objective+=dist[sol.route[1],sol.route[end]]
    
    return sol
end

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

# Remove: move all cities from cityset from route to rem_cities
function removeCities(dist,sol,city_set)
    idx=1
    while idx<=length(sol.route)
        if city_set[sol.route[idx]]
            remove(dist,sol,idx)
        else
            idx+=1
        end
    end
end



function insert_cost(dist,sol,idx,c)
    # cost of inserting city c in position idx
    prior=(idx > 1 ? idx-1 : length(sol.route))
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
function d1(dist,sol,no_cities_to_destroy)
    for i=1:no_cities_to_destroy
        idx=rand(1:length(sol.route))
        remove(dist,sol,idx)
    end

    return sol
end

# destroy K cities and their L nearest neighbors
function d2(dist,dim,neigh,sol,K,L)
    (K*L<dim) || (println("too big K and L"); exit(0) )          
    dest=falses(dim) # destroy cities, dsv. move to 
    for k=1:K
        c=rand(1:dim)
        while dest[c]
            c=rand(1:dim)
        end
        dest[c]=true
        for i=1:dim
            if neigh[c,i]<=L
                dest[i]=true
            end
        end
    end
    removeCities(dist,sol,dest)

    return sol
end

# repair solution greedily inserting the cities                 
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

# set the probabilities according to rho
function SetProb(rho,prob)
    for i=1:length(prob)
        prob[i]=rho[i]/sum(rho[:])
    end
    
    return prob
end

# given a probability array, select a destroy method
function SelectDestroy(prob)
    chosen=rand()
    next_prob=0
    for i=1:length(prob)
        next_prob+=prob[i]
        if chosen <= next_prob
            return i
        end
    end
    println("we should never get here, chosen: ", chosen, "  prob: ", prob)
    exit(0)
end

function ALNS(dist,dim,timelimit,neigh)
    startTime=time_ns()

    sol = nearest_neighbor_heuristic(dist,dim) #random_solution(dist,dim) #
    best_sol = deepcopy(sol) 
    min_delete::Int64=2
    max_delete::Int64=ceil(dim*0.3)
    if max_delete<=min_delete
        max_delete=min_delete+1
    end
    println("Destroy interval: [", min_delete, " , ", max_delete, "]")

    # initial definitions
    it=1

    # reward vector
    rho=ones(2)

    # probability vector
    prob=zeros(2)

    # set the initial probability
    prob=SetProb(rho,prob)

    # reward constants
    W1=10 # global best
    W2=5  # better than current
    W3=1  # accepted
    W4=0  # not-accepted

    # decay constant
    gamma=0.9

    # initial temperature
    T=1000

    # temperature decay parameter
    alpha=0.999

    # main loop
    while elapsed_time(startTime)<timelimit

        # update the probability vector in intervals
        if mod(it,10)==0
            prob=SetProb(rho,prob)
        end

        # find the destroy method
        selected_destroy=SelectDestroy(prob)
        if selected_destroy==1
            sol_t = d1(dist,deepcopy(sol),rand(min_delete:max_delete) )
        else
            sol_t = d2(dist,dim,neigh,deepcopy(sol),6,6)
        end

        # repair the destroyed solution
        sol_t = r(dist,sol_t)

        WW=W4
        if sol_t.objective < sol.objective
            # improving current solution
            sol=sol_t
            WW=W2
        else
            # not improving
            if rand() < exp(-( sol_t.objective - sol.objective ) /T )
                # but we will take it anyway
                sol=sol_t
                WW=W3
            end
        end
        if sol_t.objective < best_sol.objective
            # best solution seen sofar, remember it 
            best_sol=deepcopy(sol_t)
            WW=W1
        end

        # update rho vector for selected destroy
        rho[selected_destroy]=gamma*rho[selected_destroy] + (1-gamma)*WW

        # report progress
        if mod(it,100)==0
            println("it: ", it, "  time: ", elapsed_time(startTime), " < ",timelimit, " obj: ", sol.objective, "  prob: ", prob,   "  rho: ", rho)
        end

        # re-calculate temperature
        T=alpha*T
        it+=1
    end
    return best_sol
end
    




function main()
#    name, coord, dim = readInstance("../Data/tsp_toy.tsp")
#    name, coord, dim = readInstance("../Data/berlin52_7542.tsp")
    name, coord, dim = readInstance("../Data/lin318_42029.tsp")
#    rng = MersenneTwister(seed);
    dist = getDistanceMatrix(coord,dim)

    neigh=neighbourMatrix(dist,dim)

    sol=ALNS(dist,dim,60,neigh)

    println("Route: ",sol.route)
    println("Objective: ",sol.objective)
end

main()



