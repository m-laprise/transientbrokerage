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
using LinearAlgebra: svd, norm
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
    n_seeds = length(mdfs)
    periods = mdfs[1].period
    T_burn = 30

    # Font sizes
    title_fs = 12; label_fs = 10; tick_fs = 9; row_label_fs = 12

    # Compact legend style (shared across all legends)
    leg_kw = (; labelsize=9, patchsize=(10, 10), padding=(3, 3, 2, 2),
                rowgap=0, patchlabelgap=3, framewidth=0.5)

    # Helper: plot all seeds as thin lines, mean as thick
    function plot_metric!(ax, metric_fn; label="", color=COL_INTERNAL)
        seed_vals = [rolling_mean(metric_fn(mdf), window) for mdf in mdfs]
        for sv in seed_vals
            lines!(ax, periods, sv; color=(color, 0.45), linewidth=0.8)
        end
        ensemble = [mean(filter(!isnan, [sv[t] for sv in seed_vals])) for t in eachindex(periods)]
        lines!(ax, periods, ensemble; color=color, linewidth=2.5, label=label)
    end

    ax_kw = (; titlesize=title_fs, ylabelsize=label_fs,
               xticklabelsize=tick_fs, yticklabelsize=tick_fs)

    # Build figure with explicit layout control
    fig = Figure(; size=(1100, 1100), figure_padding=(5, 5, 5, 5))

    # Suptitle row (row 0) — minimal height
    Label(fig[0, 1:3], suptitle; fontsize=16, font=:bold, halign=:center, tellwidth=false)

    # ── Row 1: Market Activity ──
    Label(fig[1, 0], "Market\nActivity"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax1 = Axis(fig[1, 1]; title="Outsourcing rate", ylabel="Rate", ax_kw...)
    plot_metric!(ax1, mdf -> mdf.outsourcing_rate)

    ax2 = Axis(fig[1, 2]; title="Matches per period", ylabel="Count", ax_kw...)
    plot_metric!(ax2, mdf -> Float64.(mdf.n_direct); label="Internal", color=COL_INTERNAL)
    plot_metric!(ax2, mdf -> Float64.(mdf.n_placed); label="Brokered", color=COL_BROKER)
    axislegend(ax2; position=:rt, leg_kw...)

    ax3 = Axis(fig[1, 3]; title="Available workers & firm size", ylabel="Count", ax_kw...)
    plot_metric!(ax3, mdf -> Float64.(mdf.n_available); label="Available", color=:teal)
    plot_metric!(ax3, mdf -> mdf.avg_firm_size .* 10; label="Firm size (×10)", color=:darkorange)
    axislegend(ax3; position=:rt, leg_kw...)

    # ── Row 2: Prediction Quality ──
    Label(fig[2, 0], "Prediction\nQuality"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax4 = Axis(fig[2, 1]; title="Model quality: holdout R²", ylabel="R²", ax_kw...)
    plot_metric!(ax4, mdf -> mdf.firm_r_squared_holdout; label="Firm", color=COL_INTERNAL)
    plot_metric!(ax4, mdf -> mdf.broker_r_squared_holdout; label="Broker", color=COL_BROKER)
    axislegend(ax4; position=:rb, leg_kw...)

    ax5 = Axis(fig[2, 2]; title="Rank correlation (selected)", ylabel="Spearman ρ", ax_kw...)
    plot_metric!(ax5, mdf -> mdf.firm_rank_corr_rolling; label="Firm", color=COL_INTERNAL)
    plot_metric!(ax5, mdf -> mdf.broker_rank_corr_rolling; label="Broker", color=COL_BROKER)
    axislegend(ax5; position=:rb, leg_kw...)

    ax6 = Axis(fig[2, 3]; title="Wage accuracy: R² (selected)", ylabel="R²", ax_kw...)
    plot_metric!(ax6, mdf -> mdf.firm_r_squared_rolling; label="Firm", color=COL_INTERNAL)
    plot_metric!(ax6, mdf -> mdf.broker_r_squared_rolling; label="Broker", color=COL_BROKER)
    axislegend(ax6; position=:rb, leg_kw...)

    # ── Row 3: Broker Advantage (gaps: broker minus firm) ──
    Label(fig[3, 0], "Broker\nAdvantage"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)
    COL_GAP = :purple

    ax7 = Axis(fig[3, 1]; title="Holdout R² gap", ylabel="Δ R²", ax_kw...)
    plot_metric!(ax7, mdf -> mdf.gap_r_squared_holdout; color=COL_GAP)
    hlines!(ax7, [0.0]; color=:gray50, linewidth=0.8)

    ax8 = Axis(fig[3, 2]; title="Rank corr. gap (selected)", ylabel="Δ ρ", ax_kw...)
    plot_metric!(ax8, mdf -> mdf.gap_rank_corr_selected; color=COL_GAP)
    hlines!(ax8, [0.0]; color=:gray50, linewidth=0.8)

    ax9 = Axis(fig[3, 3]; title="R² gap (selected)", ylabel="Δ R²", ax_kw...)
    plot_metric!(ax9, mdf -> mdf.gap_r_squared_selected; color=COL_GAP)
    hlines!(ax9, [0.0]; color=:gray50, linewidth=0.8)

    # ── Row 4: Structural Dynamics ──
    Label(fig[4, 0], "Structural\nDynamics"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax10 = Axis(fig[4, 1]; title="Mean match output", ylabel="Output", ax_kw...)
    plot_metric!(ax10, mdf -> mdf.q_direct_mean; label="Internal", color=COL_INTERNAL)
    plot_metric!(ax10, mdf -> mdf.q_placed_mean; label="Brokered", color=COL_BROKER)
    axislegend(ax10; position=:rb, leg_kw...)

    ax11 = Axis(fig[4, 2]; title="Broker betweenness", ylabel="Betweenness", ax_kw...)
    plot_metric!(ax11, mdf -> mdf.betweenness; color=COL_BROKER)

    ax12 = Axis(fig[4, 3]; title="Access share (brokered)", ylabel="Fraction", ax_kw...)
    plot_metric!(ax12, access_fraction; color=:darkorange)

    # ── Row 5: Diagnostics ──
    Label(fig[5, 0], "Diagnostics"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax13 = Axis(fig[5, 1]; title="Broker pool & history", xlabel="Period", ylabel="Count",
                ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax13, mdf -> Float64.(mdf.broker_pool_size); label="Pool", color=:teal)
    plot_metric!(ax13, mdf -> Float64.(mdf.broker_history_size); label="History", color=:darkorange)
    axislegend(ax13; position=:rb, leg_kw...)

    ax14 = Axis(fig[5, 2]; title="Broker reputation", xlabel="Period", ylabel="Reputation",
                ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax14, mdf -> mdf.broker_reputation; color=COL_BROKER)

    ax15 = Axis(fig[5, 3]; title="Prediction bias (selected)", xlabel="Period", ylabel="Bias",
                ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax15, mdf -> mdf.broker_bias_rolling; label="Broker", color=COL_BROKER)
    plot_metric!(ax15, mdf -> mdf.firm_bias_rolling; label="Firm", color=COL_INTERNAL)
    axislegend(ax15; position=:rt, leg_kw...)

    # Burn-in indicator on all panels
    for ax in [ax1, ax2, ax3, ax4, ax5, ax6, ax7, ax8, ax9, ax10, ax11, ax12, ax13, ax14, ax15]
        vlines!(ax, [T_burn]; color=:gray30, linestyle=:dash, linewidth=1.5)
    end

    # Footer (row 6)
    footer = "Thin lines: individual seeds ($n_seeds). Thick: ensemble mean. " *
             "Dashed: burn-in (t=$T_burn). Rolling window: $window periods."
    Label(fig[6, 1:3], footer; fontsize=10, color=:gray30, halign=:center, tellwidth=false)

    # Explicit layout sizing
    colsize!(fig.layout, 0, Fixed(30))         # row labels: narrow
    for r in 1:5
        rowsize!(fig.layout, r, Auto(1))       # all panel rows: equal weight
    end
    rowsize!(fig.layout, 0, Fixed(22))         # suptitle: minimal
    rowsize!(fig.layout, 6, Fixed(18))         # footer: minimal
    rowgap!(fig.layout, 5)
    colgap!(fig.layout, 10)

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
     label="Baseline: 8-dim types, moderate quality share, 5% turnover (d=8, ρ=0.50, η=0.05)",
     kwargs=(d=8, rho=0.50)),
    (tag="d04_simple",
     label="Simple matching: 4-dim types (d=4, ρ=0.50, η=0.05)",
     kwargs=(d=4, rho=0.50)),
    (tag="d12_complex",
     label="Complex matching: 12-dim types (d=12, ρ=0.50, η=0.05)",
     kwargs=(d=12, rho=0.50)),
    (tag="rho10_weakquality",
     label="Weak general quality: mostly match-specific (d=8, ρ=0.10, η=0.05)",
     kwargs=(d=8, rho=0.10)),
    (tag="rho90_strongquality",
     label="Strong general quality: worker type dominates (d=8, ρ=0.90, η=0.05)",
     kwargs=(d=8, rho=0.90)),
    (tag="eta01_stable",
     label="Stable market: 1% firm turnover, ~100-period lifetimes (d=8, ρ=0.50, η=0.01)",
     kwargs=(d=8, rho=0.50, eta=0.01)),
    (tag="eta10_volatile",
     label="Volatile market: 10% firm turnover, ~10-period lifetimes (d=8, ρ=0.50, η=0.10)",
     kwargs=(d=8, rho=0.50, eta=0.10)),
    (tag="rho00_pureinteraction",
     label="Pure interaction: no general quality (d=8, ρ=0.00, η=0.05)",
     kwargs=(d=8, rho=0.0)),
    (tag="rho100_purequality",
     label="Pure general quality: no match-specific component (d=8, ρ=1.00, η=0.05)",
     kwargs=(d=8, rho=1.0)),
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

# ---------------------------------------------------------------------------
# SVD of noiseless matching matrix F[worker, firm] for dimension sweep
# ---------------------------------------------------------------------------

"""Build N_W × N_F noiseless matching matrix and plot its SVD spectrum."""
function plot_svd_matching(; d::Int, rho::Float64, seed::Int=42, filename::String)
    params = default_params(; d=d, rho=rho, seed=seed)
    state = initialize_model(params)

    N_W = length(state.workers)
    N_F = length(state.firms)
    F = Matrix{Float64}(undef, N_W, N_F)
    for j in 1:N_F
        x = state.firms[j].type
        for i in 1:N_W
            F[i, j] = match_output_noiseless(state.workers[i].type, x, state.env)
        end
    end

    S = svd(F)
    σ = S.S
    σ_norm = σ ./ σ[1]
    cumvar = cumsum(σ .^ 2) ./ sum(σ .^ 2)

    fig = Figure(; size=(700, 280), figure_padding=(10, 15, 5, 5))
    title = "SVD of noiseless matching matrix F[worker, firm] " *
            "($(N_W)×$(N_F), d=$d, ρ=$rho, seed=$seed)"
    Label(fig[0, 1:2], title; fontsize=13, font=:bold, halign=:center, tellwidth=false)

    ax1 = Axis(fig[1, 1]; title="Singular values of F(w,x) matrix",
               xlabel="Component", ylabel="Normalized",
               titlesize=11, xlabelsize=10, ylabelsize=10)
    scatterlines!(ax1, 1:length(σ_norm), σ_norm; markersize=4, color=:steelblue)

    cumvar_plot = vcat(0.0, cumvar)  # start at (0, 0)
    ax2 = Axis(fig[1, 2]; title="Cumulative variance explained",
               xlabel="Component", ylabel="Fraction",
               titlesize=11, xlabelsize=10, ylabelsize=10,
               limits=(nothing, (0, 1.05)))
    scatterlines!(ax2, 0:length(cumvar), cumvar_plot; markersize=4, color=:steelblue)
    # Reference lines at 90% and 95%
    hlines!(ax2, [0.90, 0.95]; color=:gray60, linestyle=:dash, linewidth=0.8)
    text!(ax2, length(cumvar) * 0.75, 0.90; text="90%", fontsize=9, color=:gray40, align=(:left, :bottom))
    text!(ax2, length(cumvar) * 0.75, 0.95; text="95%", fontsize=9, color=:gray40, align=(:left, :bottom))

    rowsize!(fig.layout, 0, Fixed(22))

    save(joinpath(OUTDIR, filename), fig)
    println("  Saved: $filename")
    return fig
end

# Generate SVD figures for configs that vary d or rho (i.e. change the matching function)
println("Generating SVD matching matrix figures...")
svd_configs = filter(c -> begin
        d = get(Dict(pairs(c.kwargs)), :d, 8)
        rho = get(Dict(pairs(c.kwargs)), :rho, 0.50)
        d != 8 || rho != 0.50  # skip if both are baseline defaults
    end, configs)
# Always include baseline
pushfirst!(svd_configs, configs[1])
for c in svd_configs
    kw = Dict(pairs(c.kwargs))
    plot_svd_matching(; d=get(kw, :d, 8), rho=get(kw, :rho, 0.50),
                        filename="$(c.tag)_svd.png")
end

println()
println("Figures: $OUTDIR")
println("Data: $DATADIR")
println("Done.")
