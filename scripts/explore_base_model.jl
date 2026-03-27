"""
    explore_base_model.jl

Run the base model (no staffing) for T=1000 periods across multiple parameter
configurations and seeds. Produce time-series figures to characterize the dynamics
and identify time scales before writing behavioral tests.

Usage: julia --project --threads=auto scripts/explore_base_model.jl
"""

Threads.nthreads() == 1 && @warn "Running single-threaded; start Julia with --threads=auto for faster betweenness computation"

using TransientBrokerage
using CairoMakie
using DataFrames
using Statistics: mean
using JLD2

const OUTDIR = joinpath(@__DIR__, "..", "data", "figures", "exploration")
const DATADIR = joinpath(@__DIR__, "..", "data", "sims", "exploration")
mkpath(OUTDIR)
mkpath(DATADIR)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

"""Run `n_seeds` simulations at `params` (overriding T and seed), return vector of DataFrames."""
function run_ensemble(; base_params_kwargs, T::Int, n_seeds::Int)
    mdfs = DataFrame[]
    for s in 1:n_seeds
        params = default_params(; T=T, seed=s, base_params_kwargs...)
        _, mdf = run_simulation(params)
        mdf[!, :seed] = fill(s, nrow(mdf))
        push!(mdfs, mdf)
    end
    return mdfs
end

"""Compute rolling mean over a window. Uses a growing window for early periods so all periods have values."""
function rolling_mean(v::AbstractVector, window::Int)
    n = length(v)
    out = fill(NaN, n)
    for i in 1:n
        start = max(1, i - window + 1)
        vals = filter(!isnan, @view v[start:i])
        if !isempty(vals)
            out[i] = mean(vals)
        end
    end
    return out
end

"""Access fraction = access / (access + assessment), or NaN if both zero."""
function access_fraction(mdf::DataFrame)
    total = mdf.access_count .+ mdf.assessment_count
    return [t > 0 ? mdf.access_count[i] / t : NaN for (i, t) in enumerate(total)]
end

# ---------------------------------------------------------------------------
# Main plotting function
# ---------------------------------------------------------------------------

# Consistent colors: broker = crimson, internal/firm = steelblue
const COL_BROKER = :crimson
const COL_INTERNAL = :steelblue

function plot_ensemble(mdfs::Vector{DataFrame}, suptitle::String, filename::String;
                       window::Int=20)
    fig = Figure(size=(1200, 1400))
    n_seeds = length(mdfs)
    periods = mdfs[1].period

    # Supertitle spanning both columns
    Label(fig[0, 1:2], suptitle; fontsize=20, font=:bold, halign=:center)

    # Shared axis styling
    title_fs = 16
    label_fs = 14
    tick_fs = 12
    legend_fs = 12

    # Helper: plot all seeds as thin lines, mean as thick
    function plot_metric!(ax, metric_fn; label="", color=COL_INTERNAL)
        seed_vals = [rolling_mean(metric_fn(mdf), window) for mdf in mdfs]
        for sv in seed_vals
            lines!(ax, periods, sv; color=(color, 0.45), linewidth=0.8)
        end
        ensemble = [mean(filter(!isnan, [sv[t] for sv in seed_vals])) for t in eachindex(periods)]
        lines!(ax, periods, ensemble; color=color, linewidth=2.5, label=label)
    end

    # Row 1
    ax1 = Axis(fig[1, 1]; title="Share of vacancies sent to broker", ylabel="Rate",
               titlesize=title_fs, ylabelsize=label_fs, xticklabelsize=tick_fs, yticklabelsize=tick_fs)
    plot_metric!(ax1, mdf -> mdf.outsourcing_rate)

    ax2 = Axis(fig[1, 2]; title="Predicted vs realized match quality (R²)", ylabel="R²",
               titlesize=title_fs, ylabelsize=label_fs, xticklabelsize=tick_fs, yticklabelsize=tick_fs)
    plot_metric!(ax2, mdf -> mdf.broker_r_squared_rolling; label="Broker", color=COL_BROKER)
    plot_metric!(ax2, mdf -> mdf.firm_r_squared_rolling; label="Firm", color=COL_INTERNAL)
    axislegend(ax2; position=:rb, labelsize=legend_fs)

    # Row 2
    ax3 = Axis(fig[2, 1]; title="Broker betweenness in combined network", ylabel="Betweenness",
               titlesize=title_fs, ylabelsize=label_fs, xticklabelsize=tick_fs, yticklabelsize=tick_fs)
    plot_metric!(ax3, mdf -> mdf.betweenness; color=COL_BROKER)

    ax4 = Axis(fig[2, 2]; title="Realized output of matches by channel", ylabel="Mean output",
               titlesize=title_fs, ylabelsize=label_fs, xticklabelsize=tick_fs, yticklabelsize=tick_fs)
    plot_metric!(ax4, mdf -> mdf.q_direct_mean; label="Internal", color=COL_INTERNAL)
    plot_metric!(ax4, mdf -> mdf.q_placed_mean; label="Brokered", color=COL_BROKER)
    axislegend(ax4; position=:rb, labelsize=legend_fs)

    # Row 3
    ax5 = Axis(fig[3, 1]; title="Access share of brokered matches", ylabel="Fraction",
               titlesize=title_fs, ylabelsize=label_fs, xticklabelsize=tick_fs, yticklabelsize=tick_fs)
    plot_metric!(ax5, access_fraction; color=:darkorange)

    ax6 = Axis(fig[3, 2]; title="Broker pool and history sizes", ylabel="Count",
               titlesize=title_fs, ylabelsize=label_fs, xticklabelsize=tick_fs, yticklabelsize=tick_fs)
    plot_metric!(ax6, mdf -> Float64.(mdf.broker_pool_size); label="Pool", color=:teal)
    plot_metric!(ax6, mdf -> Float64.(mdf.broker_history_size); label="History", color=:darkorange)
    axislegend(ax6; position=:rb, labelsize=legend_fs)

    # Row 4
    ax7 = Axis(fig[4, 1]; title="Prediction bias (predicted minus realized)", ylabel="Bias",
               titlesize=title_fs, ylabelsize=label_fs, xticklabelsize=tick_fs, yticklabelsize=tick_fs)
    plot_metric!(ax7, mdf -> mdf.broker_bias_rolling; label="Broker", color=COL_BROKER)
    plot_metric!(ax7, mdf -> mdf.firm_bias_rolling; label="Firm", color=COL_INTERNAL)
    axislegend(ax7; position=:rb, labelsize=legend_fs)

    ax8 = Axis(fig[4, 2]; title="Rank correlation: predicted vs realized quality", ylabel="Spearman ρ",
               titlesize=title_fs, ylabelsize=label_fs, xticklabelsize=tick_fs, yticklabelsize=tick_fs)
    plot_metric!(ax8, mdf -> mdf.broker_rank_corr_rolling; label="Broker", color=COL_BROKER)
    plot_metric!(ax8, mdf -> mdf.firm_rank_corr_rolling; label="Firm", color=COL_INTERNAL)
    axislegend(ax8; position=:rb, labelsize=legend_fs)

    # Row 5
    ax9 = Axis(fig[5, 1]; title="Matches formed per period by channel", xlabel="Period", ylabel="Count",
               titlesize=title_fs, ylabelsize=label_fs, xlabelsize=label_fs, xticklabelsize=tick_fs, yticklabelsize=tick_fs)
    plot_metric!(ax9, mdf -> Float64.(mdf.n_direct); label="Internal", color=COL_INTERNAL)
    plot_metric!(ax9, mdf -> Float64.(mdf.n_placed); label="Brokered", color=COL_BROKER)
    axislegend(ax9; position=:rb, labelsize=legend_fs)

    ax10 = Axis(fig[5, 2]; title="Broker reputation (mean client satisfaction)", xlabel="Period", ylabel="Reputation",
                titlesize=title_fs, ylabelsize=label_fs, xlabelsize=label_fs, xticklabelsize=tick_fs, yticklabelsize=tick_fs)
    plot_metric!(ax10, mdf -> mdf.broker_reputation; color=COL_BROKER)

    # Burn-in indicator on all axes
    T_burn = 30
    for ax in [ax1, ax2, ax3, ax4, ax5, ax6, ax7, ax8, ax9, ax10]
        vlines!(ax, [T_burn]; color=:gray30, linestyle=:dash, linewidth=1.5)
    end

    # Footer
    M = mdfs[1].period[2] <= 10 ? 10 : "M"
    footer = "Thin lines: individual seeds ($n_seeds). Thick lines: ensemble mean. Dashed vertical line: end of burn-in (t=$T_burn).\n" *
             "Rolling window: $window periods. R² over rolling 5-period pairs. Betweenness recomputed every $M periods."
    Label(fig[6, 1:2], footer; fontsize=13, color=:gray15, halign=:center, padding=(10, 10, 0, 0))

    save(joinpath(OUTDIR, filename), fig)
    println("  Saved: $filename")
    return fig
end

# ---------------------------------------------------------------------------
# Run configurations
# ---------------------------------------------------------------------------

T = 800
N_SEEDS = 5

# Each config varies one parameter from the default (d=8, rho=0.50, eta=0.05)
# Labels: evocative description first, exact parameters in parentheses
configs = [
    (tag="baseline",
     label="Baseline: 4-dim types, moderate quality share, 5% turnover (d=4, ρ=0.50, η=0.05)",
     kwargs=(d=4, rho=0.50)),
    (tag="simple_matching",
     label="Simple matching: 2-dim types (d=2, ρ=0.50, η=0.05)",
     kwargs=(d=2, rho=0.50)),
    (tag="complex_matching",
     label="Complex matching: 8-dim types (d=8, ρ=0.50, η=0.05)",
     kwargs=(d=8, rho=0.50)),
    (tag="weak_quality",
     label="Weak general quality: mostly match-specific (d=4, ρ=0.10, η=0.05)",
     kwargs=(d=4, rho=0.10)),
    (tag="strong_quality",
     label="Strong general quality: worker type dominates (d=4, ρ=0.90, η=0.05)",
     kwargs=(d=4, rho=0.90)),
    (tag="stable_market",
     label="Stable market: 1% firm turnover, ~100-period lifetimes (d=4, ρ=0.50, η=0.01)",
     kwargs=(d=4, rho=0.50, eta=0.01)),
    (tag="volatile_market",
     label="Volatile market: 10% firm turnover, ~10-period lifetimes (d=4, ρ=0.50, η=0.10)",
     kwargs=(d=4, rho=0.50, eta=0.10)),
]

RERUN = "--rerun" in ARGS  # pass --rerun to force re-simulation

println("Running base model exploration (T=$T, $N_SEEDS seeds per config, $(length(configs)) configs)")
println("Data cache: $DATADIR")
RERUN && println("  --rerun: forcing re-simulation of all configs")
println()

for (i, c) in enumerate(configs)
    println("[$i/$(length(configs))] $(c.label)")
    datafile = joinpath(DATADIR, "$(c.tag).jld2")
    if !RERUN && isfile(datafile)
        println("  Loading cached data: $datafile")
        mdfs = JLD2.load(datafile, "mdfs")
    else
        mdfs = run_ensemble(; base_params_kwargs=c.kwargs, T=T, n_seeds=N_SEEDS)
        JLD2.save(datafile, "mdfs", mdfs, "label", c.label,
                  "kwargs", Dict(pairs(c.kwargs)), "T", T, "n_seeds", N_SEEDS)
        println("  Saved data: $datafile")
    end
    plot_ensemble(mdfs, c.label, "$(c.tag).png")
end

println()
println("Figures: $OUTDIR")
println("Data: $DATADIR")
println("Done.")
