# OceanFlavoredFluids

Tutorials and scripts that teach ocean-flavored fluid dynamics with [Oceananigans](https://github.com/CliMA/Oceananigans.jl).
Oceananigans is Julia software for simulating the dynamics of incompressible fluids, with a focus on ocean applications.

## Why learn fluid dynamics with Oceananigans?

Oceananigans has an innovative user interface.
In other modeling systems for fluid dynamics users typically write config files or namelists.
But with Oceananigans, users write programs ("scripts") that implement their numerical experiments.
This might sounds scary, but its actually easy --- using Oceananigans is like using a plotting library, or a library for data analysis.
And Oceananigans' user interface is way more than just "easy to use": with plain English names and an alignment between the the way we think about fluid dynamics and the organization of functionality, user scripts scripts can be literal, logical, interpretable and pedagogical.
Finally, Oceananigans presents an interface based on mathematical notation for defining diagnostic calculations, forcing functions, boundary conditions, and background states that closes the gap between the written description of a fluid dynamics problem, and its implementation in an Oceananigans script.

## Contents of this repository

This repo is a work in progress. Here's the status of things as they stand now.

- Below, a "quickstart" section is supposed to help users get up and swimming in the open ocean in an hour or two.
- `fundamentals`: a series of tutorial notebooks introducing basic Oceananigans objects and functions: staggered grids, fields, operations/diagnostics, etc.
- `snacks`: short, easily digested scripts that solve small problems.
- `course`: a series of notebooks providing a university-style course on computational fluid dynamics and the Oceananigans user interface.

# Quickstart

This is a 1-2 hour tutorial intended to get people swimming on day 1, assuming no prior Julia or Oceananigans experience.

## Install Julia

Copy into a terminal:


```bash
curl -fsSL https://install.julialang.org | sh
```

You will be prompted a few times and usually you can just accept the defaults.
See also https://julialang.org/downloads/.

## Install Oceananigans

```julia
julia> using Pkg; Pkg.add("Oceananigans")
```

Tip: another way is to press `]` (to enter package manager mode) and then type `pkg> add Oceananigans`.

Note: in this tutorial we are "installing" Oceananigans into your global Julia environment.
This is great for playing around!
If you start working with Julia, however, its strongly recommended that you create project-specific
[environments](https://pkgdocs.julialang.org/v1/environments/).
But we don't need to worry about that yet.

## Very Important Resources for learning Julia

* [Julia's Documentation](https://docs.julialang.org/en/v1/)
* [Official resources for learning Julia](https://julialang.org/learning/)

In this tutorial we also make extensive use of one of Julia's most powerful plotting libraries,
[Makie](https://docs.makie.org/v0.21/).

## A first example (it's supposed to impress you): two-dimensional turbulence

```julia
using Oceananigans

grid = RectilinearGrid(CPU(),
                       size = (128, 128),
                       x = (0, 2π),
                       y = (0, 2π),
                       topology = (Periodic, Periodic, Flat))

model = NonhydrostaticModel(; grid, advection=WENO())

ϵ(x, y) = 2rand() - 1
set!(model, u=ϵ, v=ϵ)

simulation = Simulation(model; Δt=0.01, stop_time=4)
run!(simulation)
```

then type

```julia
using GLMakie
heatmap(interior(model.velocities.u, :, :, 1), axis=(; aspect=1), colormap=:balance)
```

For even more fun, try this:

```juli
u, v, w = model.velocities
ω = Field(∂x(v) - ∂y(u))
compute!(ω)
heatmap(interior(ω, :, :, 1), axis=(; aspect=1), colormap=:balance)
```

This should create a visualization of the turbulence you just simulated.

### Again with more explanation

```julia
using Oceananigans
```

This "loads" Oceananigans.
Specifically, this brings a bunch of "names" (functions and constructors for objects, like `RectilinearGrid`)
into our namespace so that we can use them.

```julia
grid = RectilinearGrid(CPU(),
                       size = (128, 128),
                       x = (0, 2π),
                       y = (0, 2π),
                       topology = (Periodic, Periodic, Flat))
```

This builds a rectilinear grid (eg, a rectangle), defining the physical domain and finite volume spatial discretization for our problem.

Oceananigans also supports `LatitudeLongitudeGrid` for hydrostatic simulations in a spherical shell,
and a few other grid types are in various stages of development.
The first argument, which is not "named" (this is called a "positional" argument) is `CPU()`.
`CPU()` indicates that we'll allocate memory and do all our computations on the CPU.
Some other options are

* `GPU()` to allocate memory and perform computations on an NVidia GPU, if one is available.
* `Distributed(arch)`, where `arch=CPU()` or `arch=GPU()` to distributed computations across nodes, using MPI for communication.

The second argument is `size`, which sets the resolution.
Because this grid is two-dimensional, `size` is a "tuple" with 2 elements.
We're using a grid with 128 cells in the x- and y-directions.
Note, this argument is named and is called a "keyword" argument, or "kwarg".

The arguments `x` and `y` specify the domain extend in `x` and `y`.
A tuple builds a grid with equal spacing.
An array or function specifying the cell _interfaces_ can be used to build a stretched grid.

The argument `topology` dictates the nature of each dimension.
The possibilities are `Periodic`, `Bounded`, and `Flat`.
Here the z-dimension is `Flat` which means our grid is two-dimensional in `x, y`.

For more information, type `?` in the REPL (to enter "help mode") and then `RectilinearGrid`.

```julia
model = NonhydrostaticModel(; grid, advection=WENO())
```

This builds a nonhydrostatic model, which defines the dynamical equations and numerical methods we'll use for our problem.
`NonhydrostaticModel` also holds most of the memory we need.
For example, `model.velocities.u` references the data correpsonding to the velocity component in the `x`-direction.

Writing `function(; grid)` is the same as writing `function(grid=grid)`.
(`NonhydrostaticModel` has one required keyword argument, and it's `grid`.)
We've built the model with an `advection` scheme called `WENO`, which stands for "Weighted Essentially Non-Oscillatory."

```julia
ϵ(x, y) = 2rand() - 1
set!(model, u=ϵ, v=ϵ)
```

This sets our initial condition.
Basically, `set!` mutates the model state.
`set!` can also be called on individual fields, like `set!(model.velocities.u, ϵ)`.
Using `set!(model, ...)` ensures that the model state is self-consistent (for example, enforcing incompressibility, filling halo regions, etc).
Model fields can be `set!` to numbers, functions, and arrays.
The arguments of the function dependent on the dimensionality of the problem;
we need a function `ui(x, y, z)` to `set!(model, u=ui)` on a three-dimensional `model`.

```julia
simulation = Simulation(model; Δt=0.01, stop_time=4)
```

This builds a `Simulation`, which is basically a simple utility for managing a time-stepping loop.
The `Simulation` requires a time-step, `Δt`, and a stopping criterion
(usually `stop_time` or `stop_iteration`, but other criteria, including custom criteria, can be defined).

If you continue on the path of learning, you'll eventually know how to implement adaptive time-stepping, output, and arbitrary `Callback`s
(functions executed on some schedule) with `Simulation`.

```julia
run!(simulation)
```

The bees knees and pretty self-explanatory.
The best part of every script.


