# Getting Started

## Installation

The `RootIO` module provides functionality for working with ROOT TTrees in Julia. It allows you to create, manage, and write TTrees to ROOT files, using a Julia-friendly API. This guide will walk you through the basic usage of `RootIO`.

Before getting started, ensure you have the required dependencies installed. You'll need the following Julia packages:

```julia
using Pkg
Pkg.add("ROOT")
Pkg.add("Tables")
Pkg.add("CxxWrap")
```

To install the latest version of RootIO.jl use the Julia's package manager by pressing the ```]``` in the REPL prompt:

```julia
julia> ]
(v1.6) pkg> add RootIO
```

!!! compat "Use Julia 1.6 or newer"
    RootIO.jl requires at least Julia v1.6 as it is dependent on ROOT.jl. Older versions of Julia are not supported.

## Basic Methods in `RootIO`

### `TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, data)`

Creates a new RootIO TTree struct that is in abstraction over the ROOT TTree, with branches of a given type or branches having types inferred from the provided row instance.

#### Example: 

```julia
mutable struct Event
    x::Float32
    y::Float32
    z::Float32
    v::CxxWrap.StdVector{Float32}
end
f = ROOT.TFile!Open("data.root", "RECREATE")
# Create a RootIO ttree with columns x, y, z and v
tree = RootIO.TTree(f, "mytree", "mytitle", Event)
```

### `Fill(tree::TTree, data)`

Adds a row the the RootIO TTree with the given data.

#### Example:
```julia
# Fille the TTree from previous example with an event e
e.x, e.y, e.z = rand(3)
resize!.([e.v], 5)
e.v .= rand(Float32, 5)
RootIO.Fill(tree, e)
```


### `Write(tree::TTree)`

Writes a ROOT TTree to the associated ROOT file. Call this method after filling the entries to the TTree.

#### Example:
```julia
RootIO.Write(tree)
```

!!! warning "Always close the ROOT file after your work is completed"
    Close the ROOT file, 'f', with the help of ```ROOT.Close(f)``` after the analysis is completed