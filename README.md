# LearnOcean

This repository hosts tutorials and scripts that teach [Oceananigans](https://github.com/CliMA/Oceananigans.jl), ocean modeling with Oceananigans, and ocean-flavored fluid dynamics with Oceananigans.
Oceananigans is Julia software for simulating the dynamics of incompressible fluids, with a focus on ocean applications.

## Why learn fluid dynamics with Oceananigans?

Oceananigans has an innovative user interface.
In other modeling systems for fluid dynamics users typically write config files or namelists.
But with Oceananigans, users write programs ("scripts") that implement their numerical experiments.
This might sounds scary, but don't worry!
Using Oceananigans is like using a plotting library, or a library for data analysis.
In fact, it's better than that, because Oceananigans' user interface is way more than just "easy to use".
With plain English names and an alignment between core objects and the way we think about fluid dynamics, users can write scripts that are literal, logical, interpretable and pedagogical.
We can use mathematical notation to define diagnostic calculations, initial conditions, forcing functions, boundary conditions, and background states --- closing the gap between the written description of a fluid dynamics problem, and its implementation in an Oceananigans script.

## Contents of this repository

This repo is a work in progress. Here's the status of things as they stand now.

- Below, a "quickstart" section is supposed to help users get up and swimming in an hour or two.
- `fundamentals`: a series of tutorial notebooks introducing basic Oceananigans objects and functions: staggered grids, fields, operations/diagnostics, etc.
- `snacks`: short, easily digested scripts that solve small problems.
- `course`: a series of notebooks providing a university-style course on computational fluid dynamics and the Oceananigans user interface.

# Quickstart

This is a 1-2 hour tutorial intended to get people swimming on day 1, assuming no prior Julia or Oceananigans experience.

## Install Julia on your laptop or personal computer

Open up a terminal on your laptop or personal computer and copy/paste this into it:


```bash
curl -fsSL https://install.julialang.org | sh
```

You will be prompted a few times and usually you can just accept the defaults.
See also https://julialang.org/downloads/.

Sometimes people are tempted to start working on a cluster or HPC system they have access too.
We _definitely_ suggest starting on your laptop, because developing Oceananigans scripts on your laptop is a crucial part of the
"Oceananigans flow".

## Install Oceananigans and GLMakie

```julia
julia> using Pkg
julia> Pkg.add("Oceananigans")
julia> Pkg.add("GLMakie")
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

## A teaser example: two-dimensional turbulence

Open a terminal and type

```bash
$ julia
```

This opens the julia REPL.
It should look something like this:

<img width="640" alt="image" src="https://github.com/glwagner/OceanFlavoredFluids.jl/assets/15271942/1fea8c11-7a24-4b18-ac3c-e529b3174312">

but maybe with a more recent version of Julia 👀
Now, paste this whole script into your REPL.

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

At first this should look something like

<img width="706" alt="image" src="https://github.com/glwagner/OceanFlavoredFluids.jl/assets/15271942/ea9eed53-3b41-49f9-be2f-faac32c5adc2">

but quickly more exciting things start to happen.
Eventually, you'll have run your first Julia simulation (maybe).
To see what happened inside that simulation, try typing

```julia
using GLMakie
heatmap(interior(model.velocities.u, :, :, 1), axis=(; aspect=1), colormap=:balance)
```

For even more fun, try this:

```julia
u, v, w = model.velocities
ω = Field(∂x(v) - ∂y(u))
compute!(ω)
heatmap(interior(ω, :, :, 1), axis=(; aspect=1), colormap=:balance)
```

A window should pop up that looks something like this:

<img width="465" alt="image" src="https://github.com/glwagner/OceanFlavoredFluids.jl/assets/15271942/d5d5abbb-1ffb-4c5e-86b3-f0badcac8e01">

This is showing the _vorticity_ of the turbulence you just simulated.
Yes, it's coarse, but that's why it runs quick.
You can always bump the resolution if you want -- here's what we get for `size = (512, 512)`:

<img width="480" alt="image" src="https://github.com/glwagner/OceanFlavoredFluids.jl/assets/15271942/4f02de7a-c72d-4775-9381-1601c5ae16a0">


### Again with more explanation

But enough tinkering.
Let's talk about what each line in this first starter script does.

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

```julia
u, v, w = model.velocities
```

This "unpacks" the `NamedTuple` `model.velocities`. `u, v, w` are the velocity fields.
Note that `w` is 0 here, but we still have a `w` field in `model.velocities`.

```julia
ω = Field(∂x(v) - ∂y(u))
compute!(ω)
```

This builds a "computed field", which is linked to the operation `∂x(v) - ∂y(u)` ---
the difference between the `x`-derivative of `v` and the `y`-derivative of `u`, otherwise known as "vertical vorticity".
Note that in order to plot vorticity, we have to also build a `Field` (which allocates memory to store the result of the computation), and then we have to `compute!` the voricity.
The allocation of memory and `compute!` steps are separated intentionally --- to compute diagnostics during a simulation, we want to allocate the memory want, but `compute!` many times.

```julia
heatmap(interior(ω, :, :, 1), axis=(; aspect=1), colormap=:balance)
```

This plots the `x, y` plane of the vorticity field at the first vertical level (and there's only one vertical level in this simulation).
We also make sure the plot is square (like the domain) and that we're using a divergent colormap for vorticity which should be fairly equally distributed around zero.

## What next?

That's it for this first tutorial.
Here's a few ideas to take it up a notch, many of which may require referring to the [Oceananigans documentation](https://clima.github.io/OceananigansDocumentation/stable/):

- Try increasing the resolution of the model. Is the chosen time-step stable? Try adding adaptive time stepping to the simulation.
- Try using a doubly bounded grid instead of a doubly-periodic grid.
- Try computing and plotting the "speed", ie `s = sqrt(u^2 + v^2)`. Note the staggered grid location of `s`. Can you figure out how to put `s` at cell centers?
- Try adding a passive tracer called `c` to the simulation. Compute the tracer variance, `c^2`.
- Use output writers to output vorticity on a regular time-interval. Make an animation.
- Use output writers to compute and save a time-series of the total, domain-averaged kinetic energy. Also compute the domain-averaged tracer variance.

