var documenterSearchIndex = {"docs":
[{"location":"gettingstarted/#Getting-Started","page":"Getting Started","title":"Getting Started","text":"","category":"section"},{"location":"gettingstarted/#Installation","page":"Getting Started","title":"Installation","text":"","category":"section"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"The RootIO module provides functionality for working with ROOT TTrees in Julia. It allows you to create, manage, and write TTrees to ROOT files using a Julia-friendly API. This guide will walk you through the basic usage of RootIO.","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"To install the latest version of RootIO.jl, use Julia's package manager by pressing the ] key in the REPL prompt. You should also install ROOT.jl.","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"julia> ]\npkg> add RootIO\npkg> add ROOT","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"compat: Use Julia 1.6 or newer\nRootIO.jl requires at least Julia v1.6.","category":"page"},{"location":"gettingstarted/#Basic-Methods-in-RootIO","page":"Getting Started","title":"Basic Methods in RootIO","text":"","category":"section"},{"location":"gettingstarted/#TTree(file,-name,-title,-rowtype)","page":"Getting Started","title":"TTree(file, name, title, rowtype)","text":"","category":"section"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"Creates a new RootIO TTree, an abstraction over the ROOT TTree, to store rows of the specified type. rowtype must be a composite type. Each field of the composite type will be stored in a dedicated branch named after the field name.","category":"page"},{"location":"gettingstarted/#Example:","page":"Getting Started","title":"Example:","text":"","category":"section"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"using RootIO, ROOT\nmutable struct Event\n    x::Float32\n    y::Float32\n    z::Float32\n    v::StdVector{Float32}\nend\nEvent() = Event(0, 0, 0, StdVector(Float32[]))\nf = ROOT.TFile!Open(\"data.root\", \"RECREATE\")\n\n# Create a RootIO ttree with columns x, y, z and v\ntree = RootIO.TTree(f, \"mytree\", \"mytitle\", Event)\n\n# Display the tree definition\nPrint(tree)","category":"page"},{"location":"gettingstarted/#Fill(tree,-row)","page":"Getting Started","title":"Fill(tree, row)","text":"","category":"section"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"Appends a row to the RootIO TTree.","category":"page"},{"location":"gettingstarted/#Example:-2","page":"Getting Started","title":"Example:","text":"","category":"section"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"# Fill the TTree from previous example with an event e\ne = Event()\ne.x, e.y, e.z = rand(3)\ne.v = StdVector(rand(Float32, 5))\nRootIO.Fill(tree, e)\n\n#Display the tree contents\nScan(tree)","category":"page"},{"location":"gettingstarted/#Write(tree)","page":"Getting Started","title":"Write(tree)","text":"","category":"section"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"Writes a ROOT TTree to the associated ROOT file. Call this method after filling the entries in the TTree to finalize the writing to disk.","category":"page"},{"location":"gettingstarted/#Example:-3","page":"Getting Started","title":"Example:","text":"","category":"section"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"RootIO.Write(tree)","category":"page"},{"location":"gettingstarted/","page":"Getting Started","title":"Getting Started","text":"warning: Closing the ROOT file\nTo ensure the integrity of the ROOT file, Close(f) needs to be called after exiting Julia (more precisely, before the file instance is garbage collected). This is due to an issue in ROOT.jl, and this call will not be required anymore when the issue is fixed.","category":"page"},{"location":"examples/#Examples","page":"Examples","title":"Examples","text":"","category":"section"},{"location":"examples/#Row-by-row-filling","page":"Examples","title":"Row-by-row filling","text":"","category":"section"},{"location":"examples/#Example-1:-storing-scalars","page":"Examples","title":"Example 1: storing scalars","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"In this example, the columns are filled with data of primitive types.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using RootIO, ROOT\nusing Random\n\n# Create a ROOT file\nfile = ROOT.TFile!Open(\"example.root\", \"RECREATE\")\n\n# Create the tree\ntree = RootIO.TTree(file, \"tree\", \"My Tree\", pt = Float64, eta = Float64, phi = Float64)\n\n# Fill the tree with random values\nfor i in 1:10\nFill(tree, (pt = 100*randexp(), eta = 5*randn(), phi = 2π*rand()))\nend\n\n# Display tree content\nScan(tree)\n\n# Save the tree and close the file\nRootIO.Write(tree)\nROOT.Close(file)","category":"page"},{"location":"examples/#Example-2:-storing-value-collections-using-the-array-branch-type","page":"Examples","title":"Example 2: storing value collections using the array branch type","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"This example shows how to store a collection of values using the tree branch array type. With the array type, the collection length is specified in a different branch (if not fixed). Upon TTree creation, the array type is specified using a tuple (etype, length), with etype the element type and length the array size specification, either an integer or a symbol that refers to the name of the branch where the number of elements is stored. ","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using RootIO, ROOT\nusing Random\n\n# Create a ROOT file\nfile = ROOT.TFile!Open(\"example.root\", \"RECREATE\")\n\n# Create the tree\ntree = RootIO.TTree(file, \"tree\", \"My Tree\", nparts=Int32, pt=(Float64, :nparts), eta=(Float64, :nparts), phi=(Float64, :nparts))\n\n# Fill the tree with random values\nfor i in 1:10\n    n = rand(Vector{Int32}(1:10))\n    Fill(tree, (nparts=n, pt=100*randexp(n), eta=5*randn(n), phi=2π*rand(n)))\nend\n\n# Display the tree content\nScan(tree)\n\n# Print the tree structure: we notice the array type of the branches e.g., `pt[nparts]/D`\nPrint(tree)\n\n# Save the tree and close the file\nWrite(tree)\nClose(file)","category":"page"},{"location":"examples/#Example-3:-storing-collection-of-values-using-STL-vectors","page":"Examples","title":"Example 3: storing collection of values using STL vectors","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"This example is similar to Example 2, but it uses standard template library vectors to store the collection of values instead of the ROOT tree array type.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using RootIO, ROOT\nusing Random\n\n# Create a ROOT file\nfile = ROOT.TFile!Open(\"example.root\", \"RECREATE\")\n\n# Create the tree\ntree = RootIO.TTree(file, \"tree\", \"My Tree\", nparts=Int32, pt=StdVector{Float64}, eta=StdVector{Float64}, phi=StdVector{Float64})\n\n# Fill the tree with random values\nfor i in 1:10\n    n = rand(Vector{Int32}(1:10))\n   Fill(tree, (nparts=n, pt=StdVector(100*randexp(n)), eta=StdVector(5*randn(n)), phi=StdVector(2π*rand(n))))\nend\n\n# Display tree content\nScan(tree)\n\n# Print the tree structure: we notice the `vector<double>` branh types\nPrint(tree)\n\n# Save the tree and close the file\nRootIO.Write(tree)\nROOT.Close(file)","category":"page"},{"location":"examples/#Example-4:-row-data-grouped-in-a-composite-type","page":"Examples","title":"Example 4: row data grouped in a composite type","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"This example is similar to examples 2 and 3, but with row data provided as a composite type (struct).","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using RootIO, ROOT\nusing Random\n\n# The composite type used to store data of a row:\nmutable struct Event\n    nparts::Int32\n    pt::StdVector{Float64}\n    eta::StdVector{Float64}\n    phi::StdVector{Float64}\nend\nEvent()  = Event(0., StdVector{Float64}(), StdVector{Float64}(), StdVector{Float64}())\n\n# Create the ROOT file\nf = ROOT.TFile!Open(\"example.root\", \"RECREATE\")\n\n# Create the tree\ntree = RootIO.TTree(f, \"tree\", \"My Tree\", Event)\n\ne = Event()\nfor i in 1:10\n    e.nparts = rand(Vector{Int32}(1:10))\n    e.pt = StdVector(100*randexp(e.nparts))\n    e.eta = StdVector(5*randn(e.nparts))\n    e.phi = StdVector(2π*rand(e.nparts))\n    RootIO.Fill(tree, e)\nend\n\n# Display tree contents\nScan(tree)\n\n# Save the tree and close the file\nRootIO.Write(tree)\nClose(f)","category":"page"},{"location":"examples/#Multiple-row-filling","page":"Examples","title":"Multiple-row filling","text":"","category":"section"},{"location":"examples/#Example-5:-columns-provided-as-vectors","page":"Examples","title":"Example 5: columns provided as vectors","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"using RootIO, ROOT\nusing Random\n\n# Create the ROOT file\nf = ROOT.TFile!Open(\"example.root\", \"RECREATE\")\n\n# Create the tree and fill it with the dataframe contents\nnevents = 10\nnparts = rand(1:10, nevents)\ntree = RootIO.TTree(f, \"tree\", \"My Tree\",\n                    nparts = nparts,\n                    pt  = StdVector.(100 .* randexp.(nparts)),\n                    eta = StdVector.(  5 .* randn.(nparts)),\n                    phi = StdVector.( 2π .* randn.(nparts)))\n\n# Display tree contents\nScan(tree)\n\n# Save the tree and close the file\nRootIO.Write(tree)\nClose(f)","category":"page"},{"location":"examples/#Example-6:-Table/DataFrame","page":"Examples","title":"Example 6: Table/DataFrame","text":"","category":"section"},{"location":"examples/","page":"Examples","title":"Examples","text":"This example illustrates how to store a table (in the Tables.jl sense), like a NamedTuple or a DataFrame from the DataFrames.jl package.","category":"page"},{"location":"examples/","page":"Examples","title":"Examples","text":"using RootIO, ROOT\nusing Random\nusing DataFrames\n\n# Create the dataframe. Broadcasting is used to vectorize the event/row generation\nnevents = 10\nnparts = rand(1:10, nevents)\n\n# Use here a DataFrame for illustration. It works also for NamedTuple,\n# i.e. after remove `DataFrame` in the statement below, or any other\n# container table type compliant with the `Tables.jl` interface.\ntable = DataFrame(nparts = nparts,\n                  pt  = StdVector.(100 .* randexp.(nparts)),\n                  eta = StdVector.(  5 .* randn.(nparts)),\n                  phi = StdVector.( 2π .* randn.(nparts)))\n\n# Create the ROOT file\nf = ROOT.TFile!Open(\"example.root\", \"RECREATE\")\n\n# Create the tree and fill it with the dataframe contents\ntree = RootIO.TTree(f, \"tree\", \"My Tree\", table)\n\n# Display tree contents\nScan(tree)\n\n# Save the tree and close the file\nRootIO.Write(tree)\nClose(f)","category":"page"},{"location":"#RootIO.jl","page":"RootIO.jl","title":"RootIO.jl","text":"","category":"section"},{"location":"#Introduction","page":"RootIO.jl","title":"Introduction","text":"","category":"section"},{"location":"","page":"RootIO.jl","title":"RootIO.jl","text":"The RootIO package provides an easy interface to read and write columnar data sets from and into ROOT files using the TTree representation. A TTree is a columnar data representation stored on disk that supports an in-memory buffer for fast data access and automatic writing to disk. This package is based on ROOT.jl, a package that provides Julia bindings to the C++ ROOT API.","category":"page"},{"location":"","page":"RootIO.jl","title":"RootIO.jl","text":"The original TTree API is heavily based on pointers; it does not translate well to Julia and is not easy to use. The RootIO module, to be used alongside the ROOT module, provides a higher-level and more user-friendly interface to TTree. RootIO defines its own TTree type to be used in place of ROOT.TTree.","category":"page"},{"location":"","page":"RootIO.jl","title":"RootIO.jl","text":"The development of this package was initiated in the context of the 2024 edition of the Google Summer of Code program under the CERN-HSF organization.","category":"page"},{"location":"#Contents","page":"RootIO.jl","title":"Contents","text":"","category":"section"},{"location":"","page":"RootIO.jl","title":"RootIO.jl","text":"Pages = [\"index.md\", \"gettingstarted.md\", \"typesandmethods.md\", \"examples.md\"]\nDepth = 1","category":"page"},{"location":"#Supported-types","page":"RootIO.jl","title":"Supported types","text":"","category":"section"},{"location":"","page":"RootIO.jl","title":"RootIO.jl","text":"TTree represents data in two dimensions. Elements of this matrix can be of any type that can be defined in C++, including classes. In the botanical ROOT terminology, a column is called a branch and a row a tree entry.","category":"page"},{"location":"","page":"RootIO.jl","title":"RootIO.jl","text":"RootIO includes support for most of the standard Julia primitive types, character strings (String), and vectors of elements of these types. Vectors of Any are not supported. The supported types are summarized in the table below.","category":"page"},{"location":"","page":"RootIO.jl","title":"RootIO.jl","text":"Type Description Supported\nString A character string ✅\nInt8 An 8-bit signed integer ✅\nUInt8 An 8-bit unsigned integer ✅\nInt16 A 16-bit signed integer ✅\nUInt16 A 16-bit unsigned integer ✅\nInt32 A 32-bit signed integer ✅\nUInt32 A 32-bit unsigned integer ✅\nFloat32 A 32-bit floating-point number ✅\nFloat64 A 64-bit floating-point number ✅\nInt64 A long signed integer, stored as 64-bit ✅\nUInt64 A long unsigned integer, stored as 64-bit ✅\nBool A boolean ✅\nStdVector{T}¹ A vector of elements of any of the above types stored as std::vector ✅\nVector{T} A vector of elements of any of the above types stored as a C-array² ✅","category":"page"},{"location":"","page":"RootIO.jl","title":"RootIO.jl","text":"¹ StdVector is a subtype of AbstractVector provided by the CxxWrap package and reexported by RootIO. Use StdVector([1, 2, 3]) to create a vector with elements 1, 2, and 3.","category":"page"},{"location":"","page":"RootIO.jl","title":"RootIO.jl","text":"² with a fixed size or a size specified in another column.","category":"page"},{"location":"typesandmethods/#Types-and-Methods","page":"Types & Methods","title":"Types & Methods","text":"","category":"section"},{"location":"typesandmethods/","page":"Types & Methods","title":"Types & Methods","text":"Modules = [RootIO]\nOrder   = [:type, :function]","category":"page"},{"location":"typesandmethods/#RootIO.TTree","page":"Types & Methods","title":"RootIO.TTree","text":"`TTree`\n\nType representing a ROOT tree. It must be used in place of the TTree type of the ROOT module.\n\n\n\n\n\n","category":"type"},{"location":"typesandmethods/#RootIO.TTree-Tuple{CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, String, String, DataType}","page":"Types & Methods","title":"RootIO.TTree","text":"TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String, rowtype)\n\nCreate a ROOT TTree to store instances of a composite type, rowtype. Each field of the type is mapped to a TTree branch (aka column) of the same name. Each field must be annotated with its type in the declaration of rowtype declaration. The Fill function must be used to store the instance. Each instance will be stored in a TTree entry (aka row).\n\nNote: for convenience, providing an instance of the row type instead of the type itself is currently supported. This support might eventually be dropped if we find that it leads to confusion. The instance is used solely to retrieve the type and is not nserted in the tree. See TTree(::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, ::String, ::String; columns...) to create and fill a tree in one go.\n\nExample\n\n\nusing CxxWrap, ROOT, RootIO\nmutable struct Event\n    x::Float32\n    y::Float32\n    z::Float32\n    v::StdVector{Float32}\nend\nEvent()  = Event(0., 0., 0., StdVector{Float32}())\n\n# Create the tree\nf = ROOT.TFile!Open(\"data.root\", \"RECREATE\")\ntree = RootIO.TTree(f, \"mytree\", \"mytreetitle\", Event)\n\n# Fill the tree\ne = Event()\nfor i in 1:10\n    e.x, e.y, e.z = rand(3)\n    n = rand(1:5)\n    # Two next lines are an optimized version of e.v = rand(Float32)\n    # by limiting time consuming memory allocation\n    resize!(e.v, n)\n    e.v .= rand(Float32)\n    Fill(tree, e)\nend\n\n# Display tree contents\nScan(tree)\n\n\n\n\n\n","category":"method"},{"location":"typesandmethods/#RootIO.TTree-Tuple{CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, String, String}","page":"Types & Methods","title":"RootIO.TTree","text":"TTree(file::CxxWrap.CxxWrapCore.CxxPtr{ROOT.TFile}, name::String, title::String; columns...)\n\nCreates a new ROOT tree and fill it with the provided data.\n\nArguments\n\nfile: A pointer to a ROOT file where the TTree will be stored.\nname: The name of the TTree.\ntitle: The title of the TTree.\ncolumns...: column definitions passed as named argument, in the form columnname = columncontent or columnname = elementtype\n\nCreation of an empty TTree\n\nIf the columns values are data types, then an empty TTree is created. The argument names are used for the column (aka branch) names and their value specify the type of elements to store in the column.\n\nExample\n\nusing ROOT, RootIO\n\n# Create the tree\nfile = ROOT.TFile!Open(\"example.root\", \"RECREATE\")\ntree = RootIO.TTree(file, \"mytree\", \"My tree\"; col_int = Int64, col_float = Float64)\n\n# Display the tree definition\nPrint(tree)\n\nCreation and filling of a TTree\n\nIf the columns values are vectors, a TTree is created and filled with the data provided in the vectors. A branch is created for each columns argument with the name of the argument and filled with each element of the vector provided as the argument value. All the vectors must be of the same length.\n\nExample\n\nfile = ROOT.TFile!Open(\"example.root\", \"RECREATE\")\nname = \"example_tree\"\ntitle = \"Example TTree\"\ndata = (col_float=rand(Float64, 3), col_int=rand(Int32, 3))\ntree = RootIO.TTree(file, name, title; data...)\n\n\n\n\n\n","category":"method"},{"location":"typesandmethods/#ROOT.Fill-Tuple{TTree, Any}","page":"Types & Methods","title":"ROOT.Fill","text":"Fill(tree::TTree, data)\n\nAppend one or more rows (aka entries) to the ROOT tree.\n\nSingle row can be provided as an instance of a composite type or of a Tuple.\n\nExample\n\nusing ROOT, RootIO\n\n# Create the tree\nfile = ROOT.TFile!Open(\"example.root\", \"RECREATE\")\ntree = RootIO.TTree(file, \"mytree\", \"My tree\"; col_int = Int64, col_float = Float64)\n\n# Fill the tree\nfor i in 1:10\n    Fill(tree, (i, i*π))\nend\n\n# Display the tree contents\nScan(tree)\n\n\n\n\n\n","category":"method"},{"location":"typesandmethods/#ROOT.GetEntries-Tuple{TTree}","page":"Types & Methods","title":"ROOT.GetEntries","text":"GetEntries(tree)\n\nReturns the number of entries (aka rows) stored in the tree.\n\n\n\n\n\n","category":"method"},{"location":"typesandmethods/#ROOT.Print-Tuple{TTree}","page":"Types & Methods","title":"ROOT.Print","text":"Print(tree, options = \"\")\n\nPrint a summary of the tree contents.\n\nIf option contains \"all\" friend trees are also printed.\nIf option contains \"toponly\" only the top level branches are printed.\nIf option contains \"clusters\" information about the cluster of baskets is printed.\n\nWildcarding can be used to print only a subset of the branches, e.g., Print(tree, \"Elec*\") will print all branches with name starting with \"Elec\".\n\n\n\n\n\n","category":"method"},{"location":"typesandmethods/#ROOT.Scan-Tuple{TTree, Vararg{Any}}","page":"Types & Methods","title":"ROOT.Scan","text":"Scan(tree, varexp = \"\", selection = \"\", option = \"\", nentries = -1, firstentry = 0)\n\nLoop over tree entries and print entries passing selection.\n\nIf varexp is 0 (or \"\") then print only first 8 columns.\nIf varexp = \"*\" print all columns.\n\nOtherwise a column selection can be made using \"var1:var2:var3\".\n\n\n\n\n\n","category":"method"},{"location":"typesandmethods/#ROOT.Write-Tuple{TTree}","page":"Types & Methods","title":"ROOT.Write","text":"Write(tree::TTree)\n\nSave the tree into the associated ROOT file. This method needs to be called to finalize the writing to disk.\n\n\n\n\n\n","category":"method"}]
}
