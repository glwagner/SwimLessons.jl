using Oceananigans
using GLMakie

# Two-dimensional grid with isotropic resolution
Nx = Ny = 128
grid = RectilinearGrid(size = (Nx, Ny),
                       x = (0, 1),
                       y = (0, 1),
                       topology = (Periodic, Periodic, Flat))

# A simple model with a fancy advection scheme
model = NonhydrostaticModel(; grid, timestepper=:RungeKutta3, advection=WENO(order=5))

# A random initial condition
ui(x, y) = randn()
set!(model, u=ui, v=ui)

# Build a simulation with adaptive time-stepping
simulation = Simulation(model, Δt=0.1/Nx, stop_iteration=200)
conjure_time_step_wizard!(simulation, cfl=0.7)

progress(sim) = @info @sprintf("Iter: %d, time: %.2e, Δt: %.2e",
                               iteration(sim), time(sim), sim.Δt)

add_callback!(simulation, progress, IterationInterval(10))

run!(simulation)

# Cool visualization
u, v, w = model.velocities
ω_op = ∂x(v) - ∂y(v)
s_op = @at (Center, Center, Center) sqrt(u^2 + v^2)

ω = compute!(Field(ω_op))
s = compute!(Field(s_op))

ωn = interior(ω, :, :, 1)
sn = interior(s, :, :, 1)

fig = Figure()
axω = Axis(fig[1, 1], aspect=1)
axω = Axis(fig[1, 2], aspect=1)

heatmap!(axω, ωn, colormap=:balance)
heatmap!(axs, sn, colormap=:viridis)

display(fig)

