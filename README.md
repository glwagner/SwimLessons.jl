# OceanFlavoredFluids

Tutorials and scripts that teach ocean-flavored fluid dynamics with [Oceananigans](https://github.com/CliMA/Oceananigans.jl).
Oceananigans is Julia software for simulating the dynamics of incompressible fluids, with a focus on ocean applications.

## Why learn fluid dynamics with Oceananigans?

Oceananigans has an innovative user interface for fluids simulation.
Unlike in many other modeling systems for computational fluid dynamics or oceanography, where users write config files or namelists, Oceananigans users write programs ("scripts") that implement their numerical experiments.
This might sounds scary, but its actually easy --- using Oceananigans is like using a plotting library, or a library for data analysis.
And the benefits are huge: readable, understandable numerical experiments can be implemented a single file, arbitrary functions for forcing, boundary conditions, and background states injected directly into hot inner loops.

