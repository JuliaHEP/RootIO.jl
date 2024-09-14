# Getting Started

## Installation

The `RootIO` module provides functionality for working with ROOT TTrees in Julia. It allows you to create, manage, and write TTrees to ROOT files using a Julia-friendly API. This guide will walk you through the basic usage of `RootIO`.

To install the latest version of `RootIO.jl`, use Julia's package manager by pressing the `]` key in the REPL prompt. You should also install `ROOT.jl`.

```julia
julia> ]
pkg> add RootIO
pkg> add ROOT
```

!!! compat "Use Julia 1.6 or newer"
    RootIO.jl requires at least Julia v1.6.

## Basic Methods in `RootIO`

### `TTree(file, name, title, rowtype)`

Creates a new `RootIO` `TTree`, an abstraction over the `ROOT` `TTree`, to store rows of the specified type. `rowtype` must be a composite type. Each field of the composite type will be stored in a dedicated branch named after the field name.

#### Example: 

```julia
using RootIO, ROOT
mutable struct Event
    x::Float32
    y::Float32
    z::Float32
    v::StdVector{Float32}
end
Event() = Event(0, 0, 0, StdVector(Float32[]))
f = ROOT.TFile!Open("data.root", "RECREATE")

# Create a RootIO ttree with columns x, y, z and v
tree = RootIO.TTree(f, "mytree", "mytitle", Event)

# Display the tree definition
Print(tree)
```

### `Fill(tree, row)`

Appends a row to the RootIO TTree.

#### Example:
```julia
# Fill the TTree from previous example with an event e
e = Event()
e.x, e.y, e.z = rand(3)
e.v = StdVector(rand(Float32, 5))
RootIO.Fill(tree, e)

#Display the tree contents
Scan(tree)
```

### `Write(tree)`

Writes a ROOT TTree to the associated ROOT file. Call this method after filling the entries in the TTree to finalize the writing to disk.

#### Example:
```julia
RootIO.Write(tree)
```

!!! warning "Closing the ROOT file"
    To ensure the integrity of the ROOT file, `Close(f)` needs to be called after exiting Julia (more precisely, before the file instance is garbage collected). This is due to an issue in `ROOT.jl`, and this call will not be required anymore when the issue is fixed.

