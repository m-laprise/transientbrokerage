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

"""Run `n_seeds` simulations at `params` (overriding T and seed), return vector of DataFrames.
Seeds are parallelized across available threads."""
function run_ensemble(; base_params_kwargs, T::Int, n_seeds::Int)
    mdfs = Vector{DataFrame}(undef, n_seeds)
    Threads.@threads for s in 1:n_seeds
        params = default_params(; T=T, seed=s, base_params_kwargs...)
        _, mdf = run_simulation(params)
        mdf[!, :seed] = fill(s, nrow(mdf))
        mdfs[s] = mdf
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

    ax1 = Axis(fig[1, 1]; title="Outsourcing rate", ylabel="Rate",
               limits=(nothing, (0, 1)), ax_kw...)
    plot_metric!(ax1, mdf -> mdf.outsourcing_rate)

    ax2 = Axis(fig[1, 2]; title="Matches per period", ylabel="Count",
               limits=(nothing, (0, nothing)), ax_kw...)
    plot_metric!(ax2, mdf -> Float64.(mdf.n_direct); label="Internal", color=COL_INTERNAL)
    plot_metric!(ax2, mdf -> Float64.(mdf.n_placed); label="Brokered", color=COL_BROKER)
    axislegend(ax2; position=:rt, leg_kw...)

    ax3 = Axis(fig[1, 3]; title="Available, broker pool & firm size", ylabel="Count",
               limits=(nothing, (0, nothing)), ax_kw...)
    plot_metric!(ax3, mdf -> Float64.(mdf.n_available); label="Available", color=:teal)
    plot_metric!(ax3, mdf -> Float64.(mdf.broker_pool_size); label="Broker pool", color=COL_BROKER)
    plot_metric!(ax3, mdf -> mdf.avg_firm_size .* 10; label="Firm size (×10)", color=:darkorange)
    axislegend(ax3; position=:rt, leg_kw...)

    # ── Row 2: Prediction Quality ──
    Label(fig[2, 0], "Prediction\nQuality"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax4 = Axis(fig[2, 1]; title="Model quality: holdout R²", ylabel="R²",
               limits=(nothing, (0, 1)), ax_kw...)
    plot_metric!(ax4, mdf -> mdf.firm_r_squared_holdout; label="Firm", color=COL_INTERNAL)
    plot_metric!(ax4, mdf -> mdf.broker_r_squared_holdout; label="Broker", color=COL_BROKER)
    axislegend(ax4; position=:rb, leg_kw...)

    ax5 = Axis(fig[2, 2]; title="Rank correlation (selected)", ylabel="Spearman ρ",
               limits=(nothing, (-0.5, 1)), ax_kw...)
    plot_metric!(ax5, mdf -> mdf.firm_rank_corr_selected; label="Firm", color=COL_INTERNAL)
    plot_metric!(ax5, mdf -> mdf.broker_rank_corr_selected; label="Broker", color=COL_BROKER)
    axislegend(ax5; position=:rb, leg_kw...)

    ax6 = Axis(fig[2, 3]; title="Wage accuracy: R² (selected)", ylabel="R²",
               limits=(nothing, (-1, 1)), ax_kw...)
    plot_metric!(ax6, mdf -> mdf.firm_r_squared_selected; label="Firm", color=COL_INTERNAL)
    plot_metric!(ax6, mdf -> mdf.broker_r_squared_selected; label="Broker", color=COL_BROKER)
    axislegend(ax6; position=:rb, leg_kw...)

    # ── Row 3: Broker Advantage (gaps: broker minus firm) ──
    Label(fig[3, 0], "Broker\nAdvantage"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)
    COL_GAP = :purple

    ax7 = Axis(fig[3, 1]; title="Holdout R² gap", ylabel="Δ R²",
               limits=(nothing, (-1, 1)), ax_kw...)
    plot_metric!(ax7, mdf -> mdf.gap_r_squared_holdout; color=COL_GAP)
    hlines!(ax7, [0.0]; color=:gray50, linewidth=0.8)

    ax8 = Axis(fig[3, 2]; title="Rank corr. gap (selected)", ylabel="Δ ρ",
               limits=(nothing, (-1, 1)), ax_kw...)
    plot_metric!(ax8, mdf -> mdf.gap_rank_corr_selected; color=COL_GAP)
    hlines!(ax8, [0.0]; color=:gray50, linewidth=0.8)

    ax9 = Axis(fig[3, 3]; title="R² gap (selected)", ylabel="Δ R²",
               limits=(nothing, (-1, 1)), ax_kw...)
    plot_metric!(ax9, mdf -> mdf.gap_r_squared_selected; color=COL_GAP)
    hlines!(ax9, [0.0]; color=:gray50, linewidth=0.8)

    # ── Row 4: Structural Dynamics ──
    Label(fig[4, 0], "Structural\nDynamics"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax10 = Axis(fig[4, 1]; title="Mean match output", ylabel="Output",
                limits=(nothing, (0, 2)), ax_kw...)
    plot_metric!(ax10, mdf -> mdf.q_direct_mean; label="Internal", color=COL_INTERNAL)
    plot_metric!(ax10, mdf -> mdf.q_placed_mean; label="Brokered", color=COL_BROKER)
    axislegend(ax10; position=:rb, leg_kw...)

    ax11 = Axis(fig[4, 2]; title="Cross-mode betweenness", ylabel="C_B(broker)",
                limits=(nothing, (0, 1)), ax_kw...)
    plot_metric!(ax11, mdf -> mdf.betweenness; color=COL_BROKER)

    ax12 = Axis(fig[4, 3]; title="Access share (brokered)", ylabel="Fraction",
                limits=(nothing, (0, 1)), ax_kw...)
    plot_metric!(ax12, access_fraction; color=:darkorange)

    # ── Row 5: Diagnostics ──
    Label(fig[5, 0], "Diagnostics"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax13 = Axis(fig[5, 1]; title="Broker history & firm referral reach", xlabel="Period", ylabel="Count",
                ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax13, mdf -> Float64.(mdf.broker_history_size); label="Broker history", color=:darkorange)
    plot_metric!(ax13, mdf -> mdf.avg_referral_pool_size; label="Avg referral pool", color=COL_INTERNAL)
    axislegend(ax13; position=:rb, leg_kw...)

    ax14 = Axis(fig[5, 2]; title="Broker reputation", xlabel="Period", ylabel="Reputation",
                limits=(nothing, (0, 2)), ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax14, mdf -> mdf.broker_reputation; color=COL_BROKER)

    ax15 = Axis(fig[5, 3]; title="Prediction bias (selected)", xlabel="Period", ylabel="Bias",
                limits=(nothing, (-0.3, 0.3)), ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax15, mdf -> mdf.broker_bias_selected; label="Broker", color=COL_BROKER)
    plot_metric!(ax15, mdf -> mdf.firm_bias_selected; label="Firm", color=COL_INTERNAL)
    axislegend(ax15; position=:rt, leg_kw...)

    # Burn-in indicator on all panels
    for ax in [ax1, ax2, ax3, ax4, ax5, ax6, ax7, ax8, ax9, ax10, ax11, ax12, ax13, ax14, ax15]
        vlines!(ax, [T_burn]; color=:gray30, linestyle=:dash, linewidth=1.5)
    end

    # Footer (row 6)
    footer = "Thin lines: individual seeds ($n_seeds). Thick: ensemble mean. " *
             "Dashed: burn-in (t=$T_burn). Smoothing: $window-period rolling mean."
    Label(fig[6, 1:3], footer; fontsize=12, color=:black, halign=:center, tellwidth=false)

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

"""Generate 2×3 surplus apportionment figure (Fig. S8 in specs)."""
function plot_surplus_ensemble(mdfs::Vector{DataFrame}, suptitle::String, filename::String;
                               window::Int=20)
    n_seeds = length(mdfs)
    periods = mdfs[1].period
    T_burn = 30

    title_fs = 12; label_fs = 10; tick_fs = 9; row_label_fs = 12
    leg_kw = (; labelsize=9, patchsize=(10, 10), padding=(3, 3, 2, 2),
                rowgap=0, patchlabelgap=3, framewidth=0.5)

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

    fig = Figure(; size=(1100, 500), figure_padding=(5, 5, 5, 5))
    Label(fig[0, 1:3], suptitle * " — Surplus"; fontsize=16, font=:bold, halign=:center, tellwidth=false)

    COL_WORKER = :forestgreen
    COL_FIRM = COL_INTERNAL
    COL_BROK = COL_BROKER
    COL_DIRECT = COL_INTERNAL
    COL_PLACED = COL_BROKER
    COL_STAFFED = :darkorange

    # ── Row 1: Three-way split ──
    Label(fig[1, 0], "Three-way\nSplit"; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax1 = Axis(fig[1, 1]; title="Surplus by party", ylabel="Surplus",
               limits=(nothing, (nothing, nothing)), ax_kw...)
    plot_metric!(ax1, mdf -> mdf.total_realized_surplus; label="Total", color=:gray40)
    plot_metric!(ax1, mdf -> mdf.worker_surplus; label="Worker", color=COL_WORKER)
    plot_metric!(ax1, mdf -> mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed;
                 label="Firm", color=COL_FIRM)
    plot_metric!(ax1, mdf -> mdf.broker_surplus_placement .+ mdf.broker_surplus_staffing;
                 label="Broker", color=COL_BROK)
    axislegend(ax1; position=:rt, leg_kw...)

    ax2 = Axis(fig[1, 2]; title="Surplus shares", ylabel="Fraction",
               limits=(nothing, (0, 1)), ax_kw...)
    plot_metric!(ax2, mdf -> begin
        tot = mdf.total_realized_surplus
        [t > 0 ? mdf.worker_surplus[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Worker", color=COL_WORKER)
    plot_metric!(ax2, mdf -> begin
        tot = mdf.total_realized_surplus
        fs = mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed
        [t > 0 ? fs[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Firm", color=COL_FIRM)
    plot_metric!(ax2, mdf -> begin
        tot = mdf.total_realized_surplus
        bs = mdf.broker_surplus_placement .+ mdf.broker_surplus_staffing
        [t > 0 ? bs[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Broker", color=COL_BROK)
    axislegend(ax2; position=:rt, leg_kw...)

    ax3 = Axis(fig[1, 3]; title="Outsourcing rate", ylabel="Rate",
               limits=(nothing, (0, 1)), ax_kw...)
    plot_metric!(ax3, mdf -> mdf.outsourcing_rate)

    # ── Row 2: Channel decomposition ──
    Label(fig[2, 0], "Channel\nDecomp."; fontsize=row_label_fs, font=:bold, rotation=π/2,
          tellheight=false)

    ax4 = Axis(fig[2, 1]; title="Firm surplus share by channel", xlabel="Period", ylabel="Fraction",
               limits=(nothing, (0, 1)), ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax4, mdf -> begin
        tot = mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed
        [t != 0 ? mdf.firm_surplus_direct[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Direct", color=COL_DIRECT)
    plot_metric!(ax4, mdf -> begin
        tot = mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed
        [t != 0 ? mdf.firm_surplus_placed[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Placed", color=COL_PLACED)
    plot_metric!(ax4, mdf -> begin
        tot = mdf.firm_surplus_direct .+ mdf.firm_surplus_placed .+ mdf.firm_surplus_staffed
        [t != 0 ? mdf.firm_surplus_staffed[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Staffed", color=COL_STAFFED)
    axislegend(ax4; position=:rt, leg_kw...)

    ax5 = Axis(fig[2, 2]; title="Broker revenue share by channel", xlabel="Period", ylabel="Fraction",
               limits=(nothing, (0, 1)), ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax5, mdf -> begin
        tot = mdf.broker_surplus_placement .+ mdf.broker_surplus_staffing
        [t != 0 ? mdf.broker_surplus_placement[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Placement", color=COL_PLACED)
    plot_metric!(ax5, mdf -> begin
        tot = mdf.broker_surplus_placement .+ mdf.broker_surplus_staffing
        [t != 0 ? mdf.broker_surplus_staffing[i] / t : NaN for (i, t) in enumerate(tot)]
    end; label="Staffing", color=COL_STAFFED)
    axislegend(ax5; position=:rt, leg_kw...)

    ax6 = Axis(fig[2, 3]; title="Mean output by channel", xlabel="Period",
               ylabel="Mean q", ax_kw..., xlabelsize=label_fs)
    plot_metric!(ax6, mdf -> mdf.q_direct_mean; label="Direct", color=COL_DIRECT)
    plot_metric!(ax6, mdf -> mdf.q_placed_mean; label="Placed", color=COL_PLACED)
    axislegend(ax6; position=:rb, leg_kw...)

    # Burn-in indicator
    for ax in [ax1, ax2, ax3, ax4, ax5, ax6]
        vlines!(ax, [T_burn]; color=:gray30, linestyle=:dash, linewidth=1.5)
    end

    footer = "Thin lines: individual seeds ($n_seeds). Thick: ensemble mean. " *
             "Dashed: burn-in (t=$T_burn). Smoothing: $window-period rolling mean."
    Label(fig[3, 1:3], footer; fontsize=12, color=:black, halign=:center, tellwidth=false)

    colsize!(fig.layout, 0, Fixed(30))
    for r in 1:2; rowsize!(fig.layout, r, Auto(1)); end
    rowsize!(fig.layout, 0, Fixed(22))
    rowsize!(fig.layout, 3, Fixed(18))
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
RERUN = "--rerun" in ARGS

# Parse --geometry flag: complex (default), simple, unstructured, or all
GEOMETRY_ARG = let
    idx = findfirst(a -> startswith(a, "--geometry="), ARGS)
    idx !== nothing ? Symbol(split(ARGS[idx], "=")[2]) : :complex
end
GEOMETRIES = GEOMETRY_ARG == :all ? [:unstructured, :simple, :complex] : [GEOMETRY_ARG]

# Each config varies one parameter from the default (d=8, rho=0.50, eta=0.05)
function make_configs(geom::Symbol)
    geo_label = geom == :complex ? "complex curve" : geom == :simple ? "great circle" : "unstructured"
    geo_short = string(geom)
    [(tag="baseline",
      label="Baseline [$geo_label]: (d=8, ρ=0.50, η=0.05)",
      kwargs=(d=8, rho=0.50, firm_geometry=geom)),
     (tag="d04_simple",
      label="4-dim types [$geo_label]: (d=4, ρ=0.50, η=0.05)",
      kwargs=(d=4, rho=0.50, firm_geometry=geom)),
     (tag="d12_complex",
      label="12-dim types [$geo_label]: (d=12, ρ=0.50, η=0.05)",
      kwargs=(d=12, rho=0.50, firm_geometry=geom)),
     (tag="rho10_weakquality",
      label="Weak quality [$geo_label]: (d=8, ρ=0.10, η=0.05)",
      kwargs=(d=8, rho=0.10, firm_geometry=geom)),
     (tag="rho90_strongquality",
      label="Strong quality [$geo_label]: (d=8, ρ=0.90, η=0.05)",
      kwargs=(d=8, rho=0.90, firm_geometry=geom)),
     (tag="eta01_stable",
      label="Stable market [$geo_label]: (d=8, ρ=0.50, η=0.01)",
      kwargs=(d=8, rho=0.50, eta=0.01, firm_geometry=geom)),
     (tag="eta10_volatile",
      label="Volatile market [$geo_label]: (d=8, ρ=0.50, η=0.10)",
      kwargs=(d=8, rho=0.50, eta=0.10, firm_geometry=geom)),
     (tag="rho00_pureinteraction",
      label="Pure interaction [$geo_label]: (d=8, ρ=0.00, η=0.05)",
      kwargs=(d=8, rho=0.0, firm_geometry=geom)),
     (tag="rho100_purequality",
      label="Pure quality [$geo_label]: (d=8, ρ=1.00, η=0.05)",
      kwargs=(d=8, rho=1.0, firm_geometry=geom)),
    ]
end

println("Running base model exploration (T=$T, $N_SEEDS seeds, geometries=$(GEOMETRIES))")
RERUN && println("  --rerun: forcing re-simulation")
println()

for geom in GEOMETRIES
    configs = make_configs(geom)
    geo_dir = string(geom)
    outdir = joinpath(OUTDIR, geo_dir)
    datadir = joinpath(DATADIR, geo_dir)
    mkpath(outdir); mkpath(datadir)
    println("━━━ Geometry: $geom ($outdir) ━━━")

    for (i, c) in enumerate(configs)
        println("[$i/$(length(configs))] $(c.label)")
        datafile = joinpath(datadir, "$(c.tag).jld2")
        if !RERUN && isfile(datafile)
            println("  Loading cached data: $datafile")
            mdfs = JLD2.load(datafile, "mdfs")
        else
            mdfs = run_ensemble(; base_params_kwargs=c.kwargs, T=T, n_seeds=N_SEEDS)
            JLD2.save(datafile, "mdfs", mdfs, "label", c.label,
                      "kwargs", Dict(pairs(c.kwargs)), "T", T, "n_seeds", N_SEEDS)
            println("  Saved data: $datafile")
        end
        plot_ensemble(mdfs, c.label, joinpath(geo_dir, "$(c.tag).png"))
        plot_surplus_ensemble(mdfs, c.label, joinpath(geo_dir, "$(c.tag)_surplus.png"))
    end

    # SVD and matching matrix figures for configs that vary d or rho

"""
    build_ordered_matching_matrix(state) -> (F, firm_order, worker_order)

Build the N_W × N_F noiseless matching matrix with rows and columns ordered to
reveal block structure:
- Firms ordered geometrically along the firm curve (by curve parameter t).
- Workers grouped by closest firm, groups in same order as firms. Within each
  group, workers sorted by decreasing proximity to their closest firm.
Returns the reordered matrix and the index permutations.
"""
function build_ordered_matching_matrix(state)
    N_W = length(state.workers)
    N_F = length(state.firms)
    d = state.params.d

    # --- Firm ordering: reconstruct curve parameter t for each firm ---
    # Firms were generated at evenly spaced t in [0, 1]; we recover the ordering
    # by projecting firm types onto the curve's first-harmonic direction.
    # Simpler: use the initialization order (firms[j] was created at t_j = (j-1)/(N_F-1)).
    # After entry/exit, firm indices no longer correspond to curve positions.
    # Instead, sort firms by their angular position along the curve's dominant axis.
    firm_types = [state.firms[j].type for j in 1:N_F]
    # Use first principal component of firm types as the curve coordinate
    FT = reduce(hcat, firm_types)  # d × N_F
    ft_mean = vec(mean(FT, dims=2))
    FT_c = FT .- ft_mean
    # First PC via SVD
    U, _, _ = svd(FT_c)
    pc1_firms = vec(U[:, 1]' * FT_c)
    firm_order = sortperm(pc1_firms)

    # --- Worker ordering: group by closest firm, sort within group ---
    # For each worker, find the closest firm (by Euclidean distance)
    worker_closest = Vector{Int}(undef, N_W)     # index into firm_order rank
    worker_dist = Vector{Float64}(undef, N_W)
    firm_rank = invperm(firm_order)  # firm_rank[j] = position of firm j in the ordering
    for i in 1:N_W
        w = state.workers[i].type
        best_j = 1
        best_d2 = Inf
        for j in 1:N_F
            d2 = sum((w[k] - firm_types[j][k])^2 for k in 1:d)
            if d2 < best_d2
                best_d2 = d2
                best_j = j
            end
        end
        worker_closest[i] = firm_rank[best_j]  # group key = firm's position in ordering
        worker_dist[i] = sqrt(best_d2)
    end
    # Sort workers: primary key = firm group (ascending), secondary = distance (ascending = closest first)
    worker_order = sortperm(1:N_W, by=i -> (worker_closest[i], worker_dist[i]))

    # --- Build reordered matrix ---
    F = Matrix{Float64}(undef, N_W, N_F)
    for (jj, j) in enumerate(firm_order)
        x = firm_types[j]
        for (ii, i) in enumerate(worker_order)
            F[ii, jj] = match_output_noiseless(state.workers[i].type, x, state.env)
        end
    end

    return F, firm_order, worker_order
end

"""Plot SVD spectrum of the noiseless matching matrix."""
function plot_svd_matching(F::Matrix{Float64}; d::Int, rho::Float64,
                           seed::Int=42, filename::String)
    N_W, N_F = size(F)
    S = svd(F)
    σ = S.S
    σ_norm = σ ./ σ[1]
    cumvar = cumsum(σ .^ 2) ./ sum(σ .^ 2)

    fig = Figure(; size=(700, 280), figure_padding=(10, 15, 5, 5))
    title = "SVD of noiseless F[worker, firm] " *
            "($(N_W)×$(N_F), d=$d, ρ=$rho, seed=$seed)"
    Label(fig[0, 1:2], title; fontsize=13, font=:bold, halign=:center, tellwidth=false)

    ax1 = Axis(fig[1, 1]; title="Singular values of F(w,x)",
               xlabel="Component", ylabel="Normalized",
               titlesize=11, xlabelsize=10, ylabelsize=10)
    scatterlines!(ax1, 1:length(σ_norm), σ_norm; markersize=4, color=:steelblue)

    cumvar_plot = vcat(0.0, cumvar)
    ax2 = Axis(fig[1, 2]; title="Cumulative variance explained",
               xlabel="Component", ylabel="Fraction",
               titlesize=11, xlabelsize=10, ylabelsize=10,
               limits=(nothing, (0, 1.05)))
    scatterlines!(ax2, 0:length(cumvar), cumvar_plot; markersize=4, color=:steelblue)
    hlines!(ax2, [0.90, 0.95]; color=:gray60, linestyle=:dash, linewidth=0.8)
    text!(ax2, length(cumvar) * 0.75, 0.90; text="90%", fontsize=9, color=:gray40, align=(:left, :bottom))
    text!(ax2, length(cumvar) * 0.75, 0.95; text="95%", fontsize=9, color=:gray40, align=(:left, :bottom))

    rowsize!(fig.layout, 0, Fixed(22))
    save(joinpath(OUTDIR, filename), fig)
    println("  Saved: $filename")
end

"""Plot the ordered noiseless matching matrix (top) and histogram of f values (bottom)."""
function plot_matching_matrix(F::Matrix{Float64}; d::Int, rho::Float64,
                              seed::Int=42, filename::String)
    N_W, N_F = size(F)
    crange = let m = maximum(abs, F); (-m, m) end

    fig = Figure(; size=(700, 500), figure_padding=(10, 15, 5, 5))
    title = "Noiseless matching matrix f(w,x) " *
            "($(N_W)×$(N_F), d=$d, ρ=$rho, seed=$seed)"
    Label(fig[0, 1:2], title; fontsize=13, font=:bold, halign=:center, tellwidth=false)

    # Top panel: heatmap (workers on x-axis, firms on y-axis — wider than tall)
    ax1 = Axis(fig[1, 1]; xlabel="Worker (grouped by closest firm)",
               ylabel="Firm (curve order)",
               titlesize=11, xlabelsize=10, ylabelsize=10)
    hm = heatmap!(ax1, 1:N_W, 1:N_F, F; colormap=:RdBu, colorrange=crange)
    Colorbar(fig[1, 2], hm; label="f(w, x)", labelsize=10, ticklabelsize=9)

    # Bottom panel: histogram of all f values
    ax2 = Axis(fig[2, 1]; xlabel="f(w, x)", ylabel="Count",
               titlesize=11, xlabelsize=10, ylabelsize=10)
    hist!(ax2, vec(F); bins=80, color=(:steelblue, 0.7), strokewidth=0.5, strokecolor=:gray40)
    vlines!(ax2, [0.0]; color=:gray50, linewidth=0.8)

    rowsize!(fig.layout, 0, Fixed(22))
    rowsize!(fig.layout, 1, Relative(0.7))
    colsize!(fig.layout, 2, Fixed(30))
    save(joinpath(OUTDIR, filename), fig)
    println("  Saved: $filename")
end

    println("  Generating SVD and matching matrix figures...")
    svd_configs = filter(c -> begin
            kd = get(Dict(pairs(c.kwargs)), :d, 8)
            krho = get(Dict(pairs(c.kwargs)), :rho, 0.50)
            kd != 8 || krho != 0.50
        end, configs)
    pushfirst!(svd_configs, configs[1])
    for c in svd_configs
        kw = Dict(pairs(c.kwargs))
        cd = get(kw, :d, 8)
        crho = get(kw, :rho, 0.50)
        params = default_params(; d=cd, rho=crho, firm_geometry=geom, seed=42)
        state = initialize_model(params)
        F, _, _ = build_ordered_matching_matrix(state)
        plot_svd_matching(F; d=cd, rho=crho, filename=joinpath(geo_dir, "$(c.tag)_svd.png"))
        plot_matching_matrix(F; d=cd, rho=crho, filename=joinpath(geo_dir, "$(c.tag)_matrix.png"))
    end
    println()
end

println("Figures: $OUTDIR")
println("Data: $DATADIR")
println("Done.")
