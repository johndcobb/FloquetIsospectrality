# Main file for lsGens7, chunk metadata and helpers.
# Generated from lsGens7.m2

const lsGens7_CHUNK_FILES = [
    "lsGens7_chunk_1.jl",
    "lsGens7_chunk_2.jl",
]

function lsGens7_chunk_count()
    return length(lsGens7_CHUNK_FILES)
end

function lsGens7_load_chunk(i::Integer)
    @assert 1 <= i <= lsGens7_chunk_count()
    chunk_file = lsGens7_CHUNK_FILES[i]
    return include(joinpath(@__DIR__, chunk_file))
end

function lsGens7_each_chunk(f::Function)
    for cf in lsGens7_CHUNK_FILES
        data = include(joinpath(@__DIR__, cf))
        f(data)
        GC.gc()
    end
end

function lsGens7_get_all_entries()
    all = []
    for i in 1:lsGens7_chunk_count()
        append!(all, lsGens7_load_chunk(i))
    end
    return all
end

# Usage: include(joinpath(@__DIR__, "lsGens7.jl"))
# Then either call lsGens7_load_chunk(i) to load chunk i,
# use lsGens7_each_chunk(f) to process chunks one-by-one, or
# call lsGens7_get_all_entries() to concatenate all chunks into memory.
