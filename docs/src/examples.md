# Examples

## Row-by-row filling

### Example 1: storing scalars

In this example, the columns are filled with data of primitive types.

```julia
using RootIO, ROOT
using Random

# Create a ROOT file
file = ROOT.TFile!Open("example.root", "RECREATE")

# Create the tree
tree = RootIO.TTree(file, "tree", "My Tree", pt = Float64, eta = Float64, phi = Float64)

# Fill the tree with random values
for i in 1:10
Fill(tree, (pt = 100*randexp(), eta = 5*randn(), phi = 2π*rand()))
end

# Display tree content
Scan(tree)

# Save the tree and close the file
RootIO.Write(tree)
ROOT.Close(file)
```

### Example 2: storing value collections using the array branch type

This example shows how to store a collection of values using the tree branch array type. With the array type, the collection length is specified in a different branch (if not fixed). Upon `TTree` creation, the array type is specified using a tuple `(etype, length)`, with `etype` the element type and `length` the array size specification, either an integer or a symbol that refers to the name of the branch where the number of elements is stored. 

```julia
using RootIO, ROOT
using Random

# Create a ROOT file
file = ROOT.TFile!Open("example.root", "RECREATE")

# Create the tree
tree = RootIO.TTree(file, "tree", "My Tree", nparts=Int32, pt=(Float64, :nparts), eta=(Float64, :nparts), phi=(Float64, :nparts))

# Fill the tree with random values
for i in 1:10
    n = rand(Vector{Int32}(1:10))
    Fill(tree, (nparts=n, pt=100*randexp(n), eta=5*randn(n), phi=2π*rand(n)))
end

# Display the tree content
Scan(tree)

# Print the tree structure: we notice the array type of the branches e.g., `pt[nparts]/D`
Print(tree)

# Save the tree and close the file
Write(tree)
Close(file)
```

### Example 3: storing collection of values using STL vectors

This example is similar to Example 2, but it uses standard template library vectors to store the collection of values instead of the ROOT tree array type.

```julia
using RootIO, ROOT
using Random

# Create a ROOT file
file = ROOT.TFile!Open("example.root", "RECREATE")

# Create the tree
tree = RootIO.TTree(file, "tree", "My Tree", nparts=Int32, pt=StdVector{Float64}, eta=StdVector{Float64}, phi=StdVector{Float64})

# Fill the tree with random values
for i in 1:10
    n = rand(Vector{Int32}(1:10))
   Fill(tree, (nparts=n, pt=StdVector(100*randexp(n)), eta=StdVector(5*randn(n)), phi=StdVector(2π*rand(n))))
end

# Display tree content
Scan(tree)

# Print the tree structure: we notice the `vector<double>` branh types
Print(tree)

# Save the tree and close the file
RootIO.Write(tree)
ROOT.Close(file)
```

### Example 4: row data grouped in a composite type

This example is similar to examples 2 and 3, but with row data provided as a composite type (struct).

```julia
using RootIO, ROOT
using Random

# The composite type used to store data of a row:
mutable struct Event
    nparts::Int32
    pt::StdVector{Float64}
    eta::StdVector{Float64}
    phi::StdVector{Float64}
end
Event()  = Event(0., StdVector{Float64}(), StdVector{Float64}(), StdVector{Float64}())

# Create the ROOT file
f = ROOT.TFile!Open("example.root", "RECREATE")

# Create the tree
tree = RootIO.TTree(f, "tree", "My Tree", Event)

e = Event()
for i in 1:10
    e.nparts = rand(Vector{Int32}(1:10))
    e.pt = StdVector(100*randexp(e.nparts))
    e.eta = StdVector(5*randn(e.nparts))
    e.phi = StdVector(2π*rand(e.nparts))
    RootIO.Fill(tree, e)
end

# Display tree contents
Scan(tree)

# Save the tree and close the file
RootIO.Write(tree)
Close(f)
```
## Multiple-row filling

### Example 5: columns provided as vectors

```julia
using RootIO, ROOT
using Random

# Create the ROOT file
f = ROOT.TFile!Open("example.root", "RECREATE")

# Create the tree and fill it with the dataframe contents
nevents = 10
nparts = rand(1:10, nevents)
tree = RootIO.TTree(f, "tree", "My Tree",
                    nparts = nparts,
                    pt  = StdVector.(100 .* randexp.(nparts)),
                    eta = StdVector.(  5 .* randn.(nparts)),
                    phi = StdVector.( 2π .* randn.(nparts)))

# Display tree contents
Scan(tree)

# Save the tree and close the file
RootIO.Write(tree)
Close(f)
```

### Example 6: Table/DataFrame

This example illustrates how to store a table (in the `Tables.jl` sense), like a `NamedTuple` or a `DataFrame` from the `DataFrames.jl` package.

```julia
using RootIO, ROOT
using Random
using DataFrames

# Create the dataframe. Broadcasting is used to vectorize the event/row generation
nevents = 10
nparts = rand(1:10, nevents)

# Use here a DataFrame for illustration. It works also for NamedTuple,
# i.e. after remove `DataFrame` in the statement below, or any other
# container table type compliant with the `Tables.jl` interface.
table = DataFrame(nparts = nparts,
                  pt  = StdVector.(100 .* randexp.(nparts)),
                  eta = StdVector.(  5 .* randn.(nparts)),
                  phi = StdVector.( 2π .* randn.(nparts)))

# Create the ROOT file
f = ROOT.TFile!Open("example.root", "RECREATE")

# Create the tree and fill it with the dataframe contents
tree = RootIO.TTree(f, "tree", "My Tree", table)

# Display tree contents
Scan(tree)

# Save the tree and close the file
RootIO.Write(tree)
Close(f)
```

