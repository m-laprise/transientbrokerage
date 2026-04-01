"""
    quick_diagnostic.jl

Quick single-seed run at default params, producing a multi-panel diagnostic figure.
Use after any code change to eyeball the dynamics.

Usage: julia --project scripts/quick_diagnostic.jl
"""

using TransientBrokerage
using CairoMakie
using Statistics: mean

const OUTDIR = joinpath(@__DIR__, "..", "data", "figures")
mkpath(OUTDIR)

println("Running quick diagnostic (T=200, default params)...")
@time state, mdf = run_simulation(default_params())

periods = mdf.period
total_brokered = mdf.access_count .+ mdf.assessment_count
access_frac = [t > 0 ? mdf.access_count[i] / t : NaN for (i, t) in enumerate(total_brokered)]

fig = Figure(size=(1400, 1600))

ax1 = Axis(fig[1, 1]; title="Outsourcing Rate", ylabel="Rate")
lines!(ax1, periods, mdf.outsourcing_rate; color=:steelblue)

ax2 = Axis(fig[1, 2]; title="Prediction Quality (R²)", ylabel="R²")
lines!(ax2, periods, mdf.broker_r_squared_rolling; color=:crimson, label="Broker")
lines!(ax2, periods, mdf.firm_r_squared_rolling; color=:steelblue, label="Firm")
axislegend(ax2; position=:rb)

ax3 = Axis(fig[2, 1]; title="Cross-mode Betweenness", ylabel="C_B(broker)")
lines!(ax3, periods, mdf.betweenness; color=:steelblue)

ax4 = Axis(fig[2, 2]; title="Mean Output by Channel", ylabel="Output")
lines!(ax4, periods, mdf.q_direct_mean; color=:steelblue, label="Internal")
lines!(ax4, periods, mdf.q_placed_mean; color=:crimson, label="Brokered")
axislegend(ax4; position=:rb)

ax5 = Axis(fig[3, 1]; title="Access Fraction", ylabel="Fraction")
lines!(ax5, periods, access_frac; color=:darkorange)

ax6 = Axis(fig[3, 2]; title="Broker Pool & History", ylabel="Count")
lines!(ax6, periods, Float64.(mdf.broker_pool_size); color=:steelblue, label="Pool")
lines!(ax6, periods, Float64.(mdf.broker_history_size); color=:crimson, label="History")
axislegend(ax6; position=:rb)

ax7 = Axis(fig[4, 1]; title="Matches per Period", xlabel="Period", ylabel="Count")
lines!(ax7, periods, Float64.(mdf.n_direct); color=:steelblue, label="Internal")
lines!(ax7, periods, Float64.(mdf.n_placed); color=:crimson, label="Brokered")
axislegend(ax7; position=:rt)

ax8 = Axis(fig[4, 2]; title="Broker Reputation", xlabel="Period", ylabel="Reputation")
lines!(ax8, periods, mdf.broker_reputation; color=:purple)

outpath = joinpath(OUTDIR, "quick_diagnostic.png")
save(outpath, fig)
println("Saved: $outpath")

# Print summary stats
println("\n=== Summary (last 50 periods) ===")
tail = mdf[end-49:end, :]
println("  Outsourcing rate: $(round(mean(tail.outsourcing_rate), digits=3))")
println("  Broker R² (rolling): $(round(mean(filter(!isnan, tail.broker_r_squared_rolling)), digits=3))")
println("  Firm R² (rolling): $(round(mean(filter(!isnan, tail.firm_r_squared_rolling)), digits=3))")
println("  Cross-mode betweenness: $(round(mean(tail.betweenness), digits=4))")
println("  Mean internal output: $(round(mean(filter(!isnan, tail.q_direct_mean)), digits=3))")
println("  Mean brokered output: $(round(mean(filter(!isnan, tail.q_placed_mean)), digits=3))")
println("  Broker pool: $(round(mean(tail.broker_pool_size), digits=0))")
println("  Broker history: $(round(mean(tail.broker_history_size), digits=0))")
