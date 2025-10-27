using HomotopyContinuation

@var v[1:3,1:3,1:3]

# Include the generated chunk-metadata files (they define *_CHUNK_FILES and helpers)
include(joinpath(@__DIR__, "cache", "lsGens8.jl"))
include(joinpath(@__DIR__, "cache", "lsGens7.jl"))
include(joinpath(@__DIR__, "cache", "lsGens6.jl"))
include(joinpath(@__DIR__, "cache", "lambdagens5.jl"))

# ChunkedVector: an AbstractVector backed by chunk files. It loads chunks on demand
struct ChunkedVector{T} <: AbstractVector{T}
	chunk_files::Vector{String}    # absolute paths to chunk files
	chunk_lengths::Vector{Int}
	offsets::Vector{Int}
	cache::Dict{Int, Vector{T}}    # loaded chunk cache
end

function ChunkedVector_from_chunkfiles(chunk_files::Vector{String})
	# chunk_files are expected to be relative names (as generated). Convert to absolute paths
	abs_files = [joinpath(@__DIR__, "cache", cf) for cf in chunk_files]
	lengths = Int[]
	# determine lengths by briefly including each chunk and then dropping it
	for f in abs_files
		arr = include(f)
		push!(lengths, length(arr))
		# drop local reference and request GC to free memory
		arr = nothing
		GC.gc()
	end
	offsets = cumsum([1; lengths[1:end-1]])
	return ChunkedVector{Any}(abs_files, lengths, offsets, Dict{Int, Vector{Any}}())
end

Base.length(cv::ChunkedVector) = sum(cv.chunk_lengths)

# Provide size and eltype to behave like an Array/Vector for libraries that query them
Base.size(cv::ChunkedVector) = (length(cv),)
Base.eltype(::Type{ChunkedVector{T}}) where T = T
Base.size(cv::ChunkedVector, d::Int) = Base.size(cv)[d]

function _locate(cv::ChunkedVector, idx::Int)
	@assert 1 <= idx <= length(cv)
	k = searchsortedlast(cv.offsets, idx)
	local_index = idx - cv.offsets[k] + 1
	return k, local_index
end

function Base.getindex(cv::ChunkedVector, i::Int)
	k, local_i = _locate(cv, i)
	if haskey(cv.cache, k)
		return cv.cache[k][local_i]
	else
		data = include(cv.chunk_files[k])
		# If the chunk contains strings (the converter may write expressions as
		# JSON-escaped strings to avoid token-splitting), parse and eval them.
		if !isempty(data) && all(x -> isa(x, AbstractString), data)
			parsed = Vector{Any}(undef, length(data))
			for j in eachindex(data)
				# parse then evaluate in Main (where @var v[...] is declared)
				parsed[j] = Core.eval(Main, Meta.parse(data[j]))
			end
			cv.cache[k] = parsed
			return parsed[local_i]
		else
			cv.cache[k] = data
			return data[local_i]
		end
	end
end

function Base.iterate(cv::ChunkedVector, state=1)
	if state > length(cv)
		return nothing
	else
		return (cv[state], state+1)
	end
end

# Build chunked vectors for each generated dataset
lsGens8_cv = ChunkedVector_from_chunkfiles(lsGens8_CHUNK_FILES)
lsGens7_cv = ChunkedVector_from_chunkfiles(lsGens7_CHUNK_FILES)
lsGens6_cv = ChunkedVector_from_chunkfiles(lsGens6_CHUNK_FILES)
lambdagens5_cv = ChunkedVector_from_chunkfiles(lambdagens5_CHUNK_FILES)

# Pass the chunked vectors to the System constructor. Note: if the called library
# eagerly copies the vectors into memory this won't avoid the memory use, but
# many workflows will iterate without copying and will benefit from laziness.
F = System([lsGens8_cv; lsGens7_cv; lsGens6_cv; lambdagens5_cv])
res = solve(F)
