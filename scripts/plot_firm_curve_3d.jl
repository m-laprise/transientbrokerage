"""
    plot_firm_curve_3d.jl

Visualize the sinusoidal firm type curve on the unit sphere in d=3,
showing three orthogonal projections with color-coded depth.

Usage: julia --project scripts/plot_firm_curve_3d.jl
"""

using TransientBrokerage, CairoMakie, StableRNGs, LinearAlgebra

const OUTDIR = joinpath(@__DIR__, "..", "data", "figures", "exploration")
mkpath(OUTDIR)

rng = StableRNG(42)
geo = generate_firm_geometry(:complex, 3, 50, rng)

# Dense samples along the curve (no perturbation) for the smooth path
n_pts = 500
ts = range(0.0, 1.0; length=n_pts)
pts = Matrix{Float64}(undef, 3, n_pts)
for (i, t) in enumerate(ts)
    x = [sin(2π * geo.freqs[k] * t + geo.phases[k]) for k in 1:3]
    x ./= norm(x)
    pts[:, i] = x
end

# 50 firm positions
firm_pts = Matrix{Float64}(undef, 3, 50)
for (i, t) in enumerate(range(0.0, 1.0; length=50))
    firm_pts[:, i] = sample_firm_type(geo, t, 3, StableRNG(i))
end

# Sphere equator
θs = range(0, 2π; length=60)

fig = Figure(size=(800, 700))
Label(fig[0, 1:2], "Firm type curve on the unit sphere (d=3, seed=42)";
      fontsize=16, font=:bold, halign=:center, tellwidth=false)

# Helper: plot one projection
function plot_projection!(pos, pts, firm_pts, xdim, ydim, cdim, xlabel, ylabel, title)
    ax = Axis(fig[pos...]; title, xlabel, ylabel, aspect=DataAspect(), titlesize=14)
    lines!(ax, cos.(θs), sin.(θs); color=:gray85, linewidth=0.5)
    for i in 1:(size(pts, 2) - 1)
        lines!(ax, [pts[xdim, i], pts[xdim, i+1]], [pts[ydim, i], pts[ydim, i+1]];
               color=pts[cdim, i], colorrange=(-1, 1), colormap=:viridis, linewidth=2)
    end
    scatter!(ax, firm_pts[xdim, :], firm_pts[ydim, :]; color=firm_pts[cdim, :],
             colorrange=(-1, 1), colormap=:viridis, markersize=8,
             strokewidth=0.5, strokecolor=:black)
    return ax
end

plot_projection!((1, 1), pts, firm_pts, 1, 2, 3, "X", "Y", "X-Y projection (color = Z)")
plot_projection!((1, 2), pts, firm_pts, 1, 3, 2, "X", "Z", "X-Z projection (color = Y)")
plot_projection!((2, 1), pts, firm_pts, 2, 3, 1, "Y", "Z", "Y-Z projection (color = X)")

# Info panel
ax4 = Axis(fig[2, 2]; limits=(0, 1, 0, 1))
hidedecorations!(ax4); hidespines!(ax4)
text!(ax4, 0.05, 0.9; text="Sinusoidal curve on unit sphere (d=3)", fontsize=13, font=:bold)
text!(ax4, 0.05, 0.75; text="Smooth curve: $n_pts points along t ∈ [0,1]", fontsize=11)
text!(ax4, 0.05, 0.62; text="Dots: 50 firm positions (with perturbation)", fontsize=11)
text!(ax4, 0.05, 0.49; text="Color: value of the third coordinate", fontsize=11)
text!(ax4, 0.05, 0.33; text="freqs = $(round.(geo.freqs, digits=2))", fontsize=10)
text!(ax4, 0.05, 0.20; text="phases = $(round.(geo.phases, digits=2))", fontsize=10)
text!(ax4, 0.05, 0.07; text="Grey circle: unit sphere equator", fontsize=10)

rowsize!(fig.layout, 0, Fixed(25))

save(joinpath(OUTDIR, "firm_curve_3d.png"), fig)
println("Saved: $(joinpath(OUTDIR, "firm_curve_3d.png"))")
