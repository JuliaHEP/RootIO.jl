# RootIO.jl

## Introduction

Interface to ROOT file format with read/write support based on the C++ ROOT libraries.

It uses a Julia interface to the official [ROOT](http://root.cern/) C++ libraries written using [WrapIt](https://github.com/grasph/wrapit) and [CxxWrap](https://github.com/JuliaInterop/CxxWrap.jl). It extends this interface to provide a user-friendly and Julia-like interface.

This project is initiated in the context of the 2024 edition of the [Google Summer of Code](https://summerofcode.withgoogle.com/) program under the [CERN-HSF](https://github.com/JuliaHEP/RootIO.jl/blob/main/Introduction) organization.

## Contents
```@contents
Pages = ["index.md", "gettingstarted.md", "typesandmethods.md", "examples.md"]
Depth = 1
```

## For contributors

1. Add support for ROOT classes in [ROOT.jl](https://github.com/JuliaHEP/ROOT.jl)
2. Add support for writing new classes and objects
3. Translate [ROOT Tutorials](https://root.cern/doc/master/group__Tutorials.html) into equivalent Julia tutorials