cd("/home/toker/Downloads/julia/wordle")
pwd()

s = open("solutions.txt") do file
    read(file, String)
end
s = replace(s, '\"' => "")
solutions = split(s, ", ")

# list of words that are valid guesses, but will never be solutions
s = open("nonsolutions.txt") do file
    read(file, String)
end
s = replace(s, '\"' => "")
nonsolutions = split(s, ", ")

# all possible valid guesses
largelist = [nonsolutions; solutions]
;


function measure_word( word1, word2 )
    s = []
    for i = 1:5
        if word1[i] == word2[i]
            push!(s,'2')
        elseif word1[i] in word2
            push!(s,'1')
        else
            push!(s,'0')
        end
    end
    return join(s)
end;

function argmin_set( S )
    (s,ix) = findmin(S)
    return findall( ==(s), S )
end;

# iterate through result dictionary, return maximum length (we want this to be small!)
function get_maxsize(obj)
    return findmax(length, obj)[1]  # findmax returns (val,key); we want the val
end

# iterate through result dictionary, return entropy of distribution of lengths (we want this to be large!)
function get_entropy(obj)
    v = [length(val) for (key,val) in obj]
    pmf = v/sum(v)
    return sum( -p*log(p) for p in pmf )
end

# for a given word and candidate word pool, return map of meas => {candidate words}
function get_groups( word, solution_pool )
    out = Dict()
    for wc in solution_pool
        s = measure_word(word,wc)
        if haskey(out,s)
            push!(out[s], wc)
        else
            out[s] = [wc]
        end
    end
    return out
end;

# find next move given a pool of available words
function find_move( candidate_pool, solution_pool )
    # loop over candidates, calculate size and entropy for each
    sizelist = []
    entrlist = []
    for w in candidate_pool
        grps = get_groups(w, solution_pool)
        push!(sizelist, get_maxsize(grps))
        push!(entrlist, get_entropy(grps))
    end

    # extract indices of smallest sizes
    ixs = argmin_set( sizelist )

    # see if any are in the pool. If so, prefer those!
    ixs_belong = [ ix for ix in ixs if candidate_pool[ix] in solution_pool ]
    if !isempty(ixs_belong)
        ixs = ixs_belong
    end

    # among all remaining candidates, pick one with highest entropy
    ix_best = sort( ixs, by= ix->entrlist[ix], rev=true )[1]
    return candidate_pool[ix_best]
end

# trim a pool of candidate words based on a current test word and the response it received
function trim_pool(testword, response, pool)
    newpool = [ w for w in pool if measure_word(testword,w) == response ]
    @assert !isempty(newpool) "there are no solutions!"
    return newpool
end;




# find the best first move according to our heuristic
@time begin
    wfirst = find_move( largelist, solutions )
end

wfirst
find_move( largelist, solutions )


pool = solutions
nextword = wfirst # this should be "raise"
println("FIRST MOVE: ", nextword)


response ="10020"
pool = trim_pool(nextword, response, pool)
println("list of possible solutions ($(length(pool))): ", join(pool, ", "))
nextword = find_move(largelist, pool)
println("NEXT MOVE: ", nextword)



nextword
