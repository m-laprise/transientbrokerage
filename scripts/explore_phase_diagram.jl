"""
    explore_phase_diagram.jl

Phase diagram heatmaps over a (rho, d) grid using complex geometry. Runs both
base model and staffing model for T=200 periods with 5 seeds per cell.
Produces two multi-panel heatmap figures from ensemble means over t=181-200.

Figure 1 (dynamics): outsourcing, prediction gaps, satisfaction gap, flow capture.
Figure 2 (surplus): broker revenue, surplus gaps, base-staffing diffs.

Output: data/figures/exploration/phasediagrams/
Data:   data/sims/exploration/phasediagrams/data/

Usage: julia --project --threads=auto scripts/explore_phase_diagram.jl
       julia --project --threads=auto scripts/explore_phase_diagram.jl --rerun
"""

Threads.nthreads() == 1 && @warn "Running single-threaded; start Julia with --threads=auto"

using TransientBrokerage
using CairoMakie
using DataFrames
using Statistics: mean
using JLD2

const OUTDIR = joinpath(@__DIR__, "..", "data", "figures", "exploration", "phasediagrams")
const DATADIR = joinpath(@__DIR__, "..", "data", "sims", "exploration", "phasediagrams", "data")
mkpath(OUTDIR); mkpath(DATADIR)

const RERUN = "--rerun" in ARGS

const RHOS = 0.0:0.1:1.0 |> collect   # 11 values
const DS = [4, 6, 8, 10, 12, 14, 16]  # 7 values
const T = 200
const N_SEEDS = 5
const WINDOW = 181:200  # last 20 periods for ensemble means

# ── Simulation runner ──

function run_ensemble(; base_params_kwargs, T::Int, n_seeds::Int)
    mdfs = Vector{DataFrame}(undef, n_seeds)
    Threads.@threads for s in 1:n_seeds
        p = default_params(; base_params_kwargs..., T=T, seed=s)
        _, mdf = run_simulation(p)
        mdf[!, :seed] .= s
        mdfs[s] = mdf
    end
    return mdfs
end

# ── Metric extraction ──

"""Ensemble mean of a column over the WINDOW periods, skipping NaN seeds."""
function emean(mdfs::Vector{DataFrame}, col::Symbol)
    vals = Float64[]
    for mdf in mdfs
        rows = mdf[in.(mdf.period, Ref(WINDOW)), :]
        nrow(rows) == 0 && continue
        v = collect(skipmissing(rows[!, col]))
        v = filter(!isnan, v)
        isempty(v) && continue
        push!(vals, mean(v))
    end
    isempty(vals) ? NaN : mean(vals)
end

"""Extract all metrics for one (rho, d) cell from base and staffing mdfs."""
function extract_cell(mdfs_base, mdfs_staff)
    # Base model
    b_outsourcing = emean(mdfs_base, :outsourcing_rate)
    b_r2_gap = emean(mdfs_base, :gap_r_squared_holdout)
    b_rank_gap = emean(mdfs_base, :gap_rank_corr_selected)
    b_sat_int = emean(mdfs_base, :mean_satisfaction_internal)
    b_sat_brk = emean(mdfs_base, :mean_satisfaction_broker)
    b_sat_gap = b_sat_brk - b_sat_int
    b_total_surplus = emean(mdfs_base, :total_realized_surplus)
    b_broker_surplus = emean(mdfs_base, :broker_surplus_placement) +
                       emean(mdfs_base, :broker_surplus_staffing)
    b_worker_surplus = emean(mdfs_base, :worker_surplus)
    b_firm_surplus = emean(mdfs_base, :firm_surplus_direct) +
                     emean(mdfs_base, :firm_surplus_placed) +
                     emean(mdfs_base, :firm_surplus_staffed)
    # Shares of total surplus
    b_broker_share = b_total_surplus > 0 ? b_broker_surplus / b_total_surplus : NaN
    b_worker_share = b_total_surplus > 0 ? b_worker_surplus / b_total_surplus : NaN
    b_firm_share = b_total_surplus > 0 ? b_firm_surplus / b_total_surplus : NaN

    # Staffing model
    s_outsourcing = emean(mdfs_staff, :outsourcing_rate)
    s_r2_gap = emean(mdfs_staff, :gap_r_squared_holdout)
    s_rank_gap = emean(mdfs_staff, :gap_rank_corr_selected)
    s_sat_int = emean(mdfs_staff, :mean_satisfaction_internal)
    s_sat_brk = emean(mdfs_staff, :mean_satisfaction_broker)
    s_sat_gap = s_sat_brk - s_sat_int
    s_flow_capture = emean(mdfs_staff, :flow_capture_rate)
    s_total_surplus = emean(mdfs_staff, :total_realized_surplus)
    s_broker_surplus = emean(mdfs_staff, :broker_surplus_placement) +
                       emean(mdfs_staff, :broker_surplus_staffing)
    s_worker_surplus = emean(mdfs_staff, :worker_surplus)
    s_firm_surplus = emean(mdfs_staff, :firm_surplus_direct) +
                     emean(mdfs_staff, :firm_surplus_placed) +
                     emean(mdfs_staff, :firm_surplus_staffed)
    # Shares of total surplus
    s_broker_share = s_total_surplus > 0 ? s_broker_surplus / s_total_surplus : NaN
    s_worker_share = s_total_surplus > 0 ? s_worker_surplus / s_total_surplus : NaN
    s_firm_share = s_total_surplus > 0 ? s_firm_surplus / s_total_surplus : NaN

    # Staffing revenue share
    s_staffing_rev = emean(mdfs_staff, :broker_surplus_staffing)
    s_total_broker = s_broker_surplus
    s_staffing_share = s_total_broker > 0 ? s_staffing_rev / s_total_broker : NaN

    # Cumulative surplus shares (sum over all periods, then divide)
    function cum_shares(mdfs)
        cum_broker = 0.0; cum_worker = 0.0; cum_firm = 0.0; cum_total = 0.0; n = 0
        for mdf in mdfs
            cum_total += sum(mdf.total_realized_surplus)
            cum_broker += sum(mdf.broker_surplus_placement) + sum(mdf.broker_surplus_staffing)
            cum_worker += sum(mdf.worker_surplus)
            cum_firm += sum(mdf.firm_surplus_direct) + sum(mdf.firm_surplus_placed) + sum(mdf.firm_surplus_staffed)
            n += 1
        end
        cum_total /= n; cum_broker /= n; cum_worker /= n; cum_firm /= n
        bs = cum_total > 0 ? cum_broker / cum_total : NaN
        ws = cum_total > 0 ? cum_worker / cum_total : NaN
        fs = cum_total > 0 ? cum_firm / cum_total : NaN
        return (; broker=bs, worker=ws, firm=fs)
    end
    b_cum = cum_shares(mdfs_base)
    s_cum = cum_shares(mdfs_staff)

    return (;
        # Figure 1
        b_outsourcing, s_outsourcing, diff_outsourcing = s_outsourcing - b_outsourcing,
        b_r2_gap, s_r2_gap, diff_r2_gap = s_r2_gap - b_r2_gap,
        b_rank_gap, s_rank_gap, diff_rank_gap = s_rank_gap - b_rank_gap,
        b_sat_gap, s_sat_gap, diff_sat_gap = s_sat_gap - b_sat_gap,
        s_flow_capture,
        # Figure 2 (per-period shares)
        s_staffing_share,
        b_bw_gap = b_broker_share - b_worker_share,
        b_bf_gap = b_broker_share - b_firm_share,
        s_bw_gap = s_broker_share - s_worker_share,
        s_bf_gap = s_broker_share - s_firm_share,
        # Figure 3 (cumulative shares)
        b_cum_bw_gap = b_cum.broker - b_cum.worker,
        b_cum_bf_gap = b_cum.broker - b_cum.firm,
        s_cum_bw_gap = s_cum.broker - s_cum.worker,
        s_cum_bf_gap = s_cum.broker - s_cum.firm,
    )
end

# ── Run grid and generate figures per geometry ──

const GEOMETRIES = let
    idx = findfirst(a -> startswith(a, "--geometry="), ARGS)
    if idx !== nothing
        sym = Symbol(split(ARGS[idx], "=")[2])
        sym == :all ? [:complex, :simple, :unstructured] : [sym]
    else
        [:complex]
    end
end

n_rho = length(RHOS)
n_d = length(DS)

# Mutable storage for current geometry's cells (used by field_matrix)
cells = Matrix{Any}(undef, n_d, n_rho)

function field_matrix(field::Symbol)
    M = Matrix{Float64}(undef, n_d, n_rho)
    for ri in 1:n_rho, di in 1:n_d
        M[di, ri] = getfield(cells[di, ri], field)
    end
    return M
end

# ── Plotting helpers ──

const AX_KW = (; xticklabelsize=12, yticklabelsize=12, xlabelsize=14, ylabelsize=14)

"""Bilinear interpolation of matrix M (indexed by d_idx, rho_idx) onto a finer grid."""
function interpolate_grid(M, rhos, ds; n_fine=200)
    rho_fine = range(first(rhos), last(rhos); length=n_fine)
    d_fine = range(first(ds), last(ds); length=n_fine)
    Z = Matrix{Float64}(undef, n_fine, n_fine)
    for (jj, rf) in enumerate(rho_fine), (ii, df) in enumerate(d_fine)
        # Find bounding cell in the original grid
        ri = searchsortedlast(rhos, rf)
        ri = clamp(ri, 1, length(rhos) - 1)
        di = searchsortedlast(ds, df)
        di = clamp(di, 1, length(ds) - 1)
        # Bilinear weights
        tr = (rf - rhos[ri]) / (rhos[ri+1] - rhos[ri])
        td = (df - ds[di]) / (ds[di+1] - ds[di])
        tr = clamp(tr, 0.0, 1.0)
        td = clamp(td, 0.0, 1.0)
        v00 = M[di, ri];     v10 = M[di+1, ri]
        v01 = M[di, ri+1];   v11 = M[di+1, ri+1]
        # Handle NaN: fall back to nearest non-NaN
        vs = [v00, v10, v01, v11]
        if any(isnan, vs)
            valid = filter(!isnan, vs)
            Z[ii, jj] = isempty(valid) ? NaN : mean(valid)
        else
            Z[ii, jj] = (1-tr)*(1-td)*v00 + (1-tr)*td*v10 + tr*(1-td)*v01 + tr*td*v11
        end
    end
    return rho_fine, d_fine, Z
end

"""Add an interpolated filled contour + contour lines to `ax`, with colorbar at `cb_pos`.
`zero_contour=true` draws a bold black zero-crossing line (automatic for diverging maps).
`shared_range` overrides the auto-computed color range (use for consistent colormaps across panels)."""
function make_phase_plot!(ax, cb_pos, M; colormap=Reverse(:RdBu), diverging=true,
                          zero_contour=diverging, n_levels=15,
                          shared_range::Union{Nothing, Tuple{Float64,Float64}}=nothing)
    vals = filter(!isnan, vec(M))
    if shared_range !== nothing
        crange = shared_range
    elseif isempty(vals)
        crange = (-1.0, 1.0)
    elseif diverging
        vmax = maximum(abs, vals)
        crange = (-vmax, vmax)
    else
        crange = (minimum(vals), maximum(vals))
    end

    rho_fine, d_fine, Z = interpolate_grid(M, collect(Float64, RHOS), Float64.(DS))
    levels = range(crange[1], crange[2]; length=n_levels + 1)

    cf = contourf!(ax, rho_fine, d_fine, Z; colormap, levels, extendlow=:auto, extendhigh=:auto)
    # Overlay contour lines; bold zero line when requested
    if zero_contour
        contour!(ax, rho_fine, d_fine, Z; levels=[0.0], color=:black, linewidth=1.5)
    end
    contour!(ax, rho_fine, d_fine, Z; levels=collect(levels), color=(:gray30, 0.4), linewidth=0.5)

    ax.xticks = 0.0:0.2:1.0
    ax.yticks = DS
    ax.xlabel = "ρ"
    ax.ylabel = "d"
    Colorbar(cb_pos, cf; ticklabelsize=10, width=12)
    return cf
end

println("Phase diagram grid: $(n_rho) rho × $(n_d) d = $(n_rho * n_d) cells, $(N_SEEDS) seeds each, T=$T")
println("  rho = $RHOS")
println("  d   = $DS")
println("  geometries = $GEOMETRIES")
RERUN && println("  --rerun: forcing re-simulation")
println()

for geom in GEOMETRIES

geo_label = Dict(:complex => "complex", :simple => "simple (great circle)",
                 :unstructured => "unstructured")[geom]
geo_tag = string(geom)
geo_outdir = joinpath(OUTDIR, geo_tag)
geo_datadir = joinpath(DATADIR, geo_tag)
mkpath(geo_outdir); mkpath(geo_datadir)

println("━━━ Geometry: $geom ━━━")

for (ri, rho) in enumerate(RHOS)
    for (di, d) in enumerate(DS)
        tag = "rho$(lpad(Int(rho*100), 3, '0'))_d$(lpad(d, 2, '0'))"
        base_file = joinpath(geo_datadir, "$(tag)_base.jld2")
        staff_file = joinpath(geo_datadir, "$(tag)_staffing.jld2")

        print("  ρ=$(rho) d=$(d) ...")

        if !RERUN && isfile(base_file)
            mdfs_base = JLD2.load(base_file, "mdfs")
        else
            mdfs_base = run_ensemble(; base_params_kwargs=(d=d, rho=rho, firm_geometry=geom),
                                       T=T, n_seeds=N_SEEDS)
            N_W = default_params(; d=d, rho=rho, firm_geometry=geom).N_W
            JLD2.save(base_file, "mdfs", mdfs_base, "N_W", N_W)
        end

        if !RERUN && isfile(staff_file)
            mdfs_staff = JLD2.load(staff_file, "mdfs")
        else
            mdfs_staff = run_ensemble(; base_params_kwargs=(d=d, rho=rho, firm_geometry=geom,
                                                             enable_staffing=true),
                                        T=T, n_seeds=N_SEEDS)
            N_W = default_params(; d=d, rho=rho, firm_geometry=geom, enable_staffing=true).N_W
            JLD2.save(staff_file, "mdfs", mdfs_staff, "N_W", N_W)
        end

        cells[di, ri] = extract_cell(mdfs_base, mdfs_staff)
        println(" done")
    end
end

# ── Figure 1: Dynamics ──
# Layout: 5 rows × 3 panel columns (Base | M1 | Δ M1−Base)
# 6 layout columns: [hm1, cb1, hm2, cb2, hm3, cb3]
# Row 0: title + subtitle. Row -1 (after title): column headers.
# Row 5: M1-only panels in cols 2-3; col 1 empty.
# Row 6: footer caption.

fig1 = Figure(; size=(1100, 1300), figure_padding=(5, 5, 3, 3))

# Title and subtitle
Label(fig1[0, 1:6],
      "Phase diagrams: How the nature of the matching problem shapes broker advantage and capture";
      fontsize=16, font=:bold, halign=:center, tellwidth=false)
Label(fig1[1, 1:6],
      "$(titlecase(geo_label)) geometry, T=$T, steady-state means (t=$(first(WINDOW))-$(last(WINDOW))) of ensemble means over $N_SEEDS seeds.";
      fontsize=14, halign=:center, tellwidth=false, color=:gray30)

# Column headers
Label(fig1[2, 1:2], "Base model"; fontsize=14, font=:bold, halign=:center, tellwidth=false)
Label(fig1[2, 3:4], "Staffing model (M1)"; fontsize=14, font=:bold, halign=:center, tellwidth=false)
Label(fig1[2, 5:6], "Difference (M1 − Base)"; fontsize=14, font=:bold, halign=:center, tellwidth=false)

# Panel rows start at row 3
PROW = 2  # offset: panel row r maps to fig row r + PROW

for c in [1, 3, 5]
    colsize!(fig1.layout, c, Relative(0.29))
end
for c in [2, 4, 6]
    colsize!(fig1.layout, c, Relative(0.04))
end
colgap!(fig1.layout, 2, 4)
colgap!(fig1.layout, 3, 12)
colgap!(fig1.layout, 4, 4)
colgap!(fig1.layout, 5, 12)

panels1 = [
    # (row, hcol, ccol, field, title, colormap, diverging, zero_contour)
    # Col 1: Base
    (1, 1, 2, :b_outsourcing, "Outsourcing rate",               :inferno, false, false),
    (2, 1, 2, :b_r2_gap,     "Broker − firm prediction R²",    Reverse(:RdBu), true, true),
    (3, 1, 2, :b_rank_gap,   "Broker − firm ranking accuracy",  Reverse(:RdBu), true, true),
    (4, 1, 2, :b_sat_gap,    "Satisfaction: broker ch. − internal ch.",      Reverse(:RdBu),    true, true),
    # Col 2: M1
    (1, 3, 4, :s_outsourcing, "Outsourcing rate",               :inferno, false, false),
    (2, 3, 4, :s_r2_gap,     "Broker − firm prediction R²",    Reverse(:RdBu), true, true),
    (3, 3, 4, :s_rank_gap,   "Broker − firm ranking accuracy",  Reverse(:RdBu), true, true),
    (4, 3, 4, :s_sat_gap,    "Satisfaction: broker ch. − internal ch.",      Reverse(:RdBu),    true, true),
    # Col 3: Δ (M1 − Base)
    (1, 5, 6, :diff_outsourcing, "Δ Outsourcing rate",          Reverse(:RdBu),    true, true),
    (2, 5, 6, :diff_r2_gap,     "Δ Prediction R² gap",          Reverse(:RdBu),    true, true),
    (3, 5, 6, :diff_rank_gap,   "Δ Ranking accuracy gap",       Reverse(:RdBu),    true, true),
    (4, 5, 6, :diff_sat_gap,    "Δ Satisfaction gap",            Reverse(:RdBu),    true, true),
    # Row 5: M1-only (col 2 and col 3 positions)
    (5, 3, 4, :s_flow_capture,   "Staffing share of new matches",          :inferno, false, false),
    (5, 5, 6, :s_staffing_share, "Staffing share of broker revenue",       :inferno, false, false),
]

# Compute shared color ranges for consistent colormaps across panels
# Shared color ranges per measure (Base and M1 panels use same scale)
function shared_range(fields)
    vals = Float64[]
    for f in fields
        append!(vals, filter(!isnan, vec(field_matrix(f))))
    end
    (minimum(vals), maximum(vals))
end
inferno_range = shared_range([:b_outsourcing, :s_outsourcing, :s_flow_capture, :s_staffing_share])
r2_vals = shared_range([:b_r2_gap, :s_r2_gap, :diff_r2_gap])
r2_vmax = max(abs(r2_vals[1]), abs(r2_vals[2]))
r2_range = (-r2_vmax, r2_vmax)
rank_vals = shared_range([:b_rank_gap, :s_rank_gap, :diff_rank_gap])
rank_vmax = max(abs(rank_vals[1]), abs(rank_vals[2]))
rank_range = (-rank_vmax, rank_vmax)

# Map each field to its shared range
field_ranges = Dict{Symbol, Tuple{Float64,Float64}}()
for f in [:b_outsourcing, :s_outsourcing, :s_flow_capture, :s_staffing_share]
    field_ranges[f] = inferno_range
end
for f in [:b_r2_gap, :s_r2_gap, :diff_r2_gap]; field_ranges[f] = r2_range; end
for f in [:b_rank_gap, :s_rank_gap, :diff_rank_gap]; field_ranges[f] = rank_range; end
sat_range = shared_range([:b_sat_gap, :s_sat_gap, :diff_sat_gap])
sat_vmax = max(abs(sat_range[1]), abs(sat_range[2]))
for f in [:b_sat_gap, :s_sat_gap, :diff_sat_gap]; field_ranges[f] = (-sat_vmax, sat_vmax); end

for (row, hcol, ccol, field, title, cmap, divg, zc) in panels1
    ax = Axis(fig1[row + PROW, hcol]; title, titlesize=13, AX_KW...)
    sr = get(field_ranges, field, nothing)
    make_phase_plot!(ax, fig1[row + PROW, ccol], field_matrix(field);
                     colormap=cmap, diverging=divg, zero_contour=zc, shared_range=sr)
end

# Footer caption — use supertitle-style positioning outside the grid for full width
footer_lines = join([
    "ρ (quality share) controls the share of match quality from general worker quality (high ρ) vs. worker-firm interaction (low ρ).",
    "d (type dimensions) is the dimensionality of worker and firm types (higher d increases the number of parameters to estimate).",
    "Row 1 — Outsourcing rate: fraction of firms with vacancies that delegate search to the broker.",
    "Row 2 — Prediction R² gap: holdout R² difference (broker minus avg firm); how much better the broker predicts match quality.",
    "Row 3 — Ranking accuracy gap: rank correlation difference on actual hires; does the broker pick better candidates than firms.",
    "Row 4 — Satisfaction gap: mean broker-channel minus internal-channel satisfaction; positive means firms prefer the broker.",
    "Row 5 — Capture: staffing share of new matches = fraction that are staffing; staffing share of revenue = staffing / total.",
], "\n")
Box(fig1[5 + PROW + 1, 1:6]; color=:transparent, strokevisible=false)
Label(fig1[5 + PROW + 1, 1:6], footer_lines;
      fontsize=14, halign=:left, valign=:top, justification=:left,
      tellwidth=false, tellheight=true,
      padding=(5, 5, 3, 3), color=:gray30)

save(joinpath(geo_outdir, "phase_dynamics.png"), fig1; px_per_unit=2)
println("  Saved: $geo_tag/phase_dynamics.png")

# ── Figure 2: Surplus ──

fig2 = Figure(; size=(950, 580), figure_padding=(10, 10, 5, 5))
Label(fig2[0, 1:4],
      "Phase diagrams: Who captures the surplus from matching?";
      fontsize=16, font=:bold, halign=:center, tellwidth=false)
Label(fig2[1, 1:4],
      "$(titlecase(geo_label)) geometry, T=$T, steady-state means (t=$(first(WINDOW))-$(last(WINDOW))) of ensemble means over $N_SEEDS seeds.";
      fontsize=11, halign=:center, tellwidth=false, color=:gray30)

colsize!(fig2.layout, 1, Relative(0.42))
colsize!(fig2.layout, 2, Relative(0.06))
colsize!(fig2.layout, 3, Relative(0.42))
colsize!(fig2.layout, 4, Relative(0.06))
colgap!(fig2.layout, 2, 5)
colgap!(fig2.layout, 3, 15)

panels2 = [
    (1, 1, 2, :b_bw_gap,         "Broker − worker share gap (Base)",  Reverse(:RdYlGn),  true),
    (1, 3, 4, :s_bw_gap,         "Broker − worker share gap (M1)",    Reverse(:RdYlGn),  true),
    (2, 1, 2, :b_bf_gap,         "Broker − firm share gap (Base)",    Reverse(:RdBu),    true),
    (2, 3, 4, :s_bf_gap,         "Broker − firm share gap (M1)",      Reverse(:RdBu),    true),
]

for (row, hcol, ccol, field, title, cmap, divg) in panels2
    ax = Axis(fig2[row + 1, hcol]; title, titlesize=13, AX_KW...)
    make_phase_plot!(ax, fig2[row + 1, ccol], field_matrix(field); colormap=cmap, diverging=divg)
end

surplus_footer = join([
    "Each panel shows broker surplus share minus counterparty surplus share of total realized surplus per period.",
    "Red = broker captures a larger share; green/blue = counterparty retains more. Zero line shown in black.",
    "Worker surplus = wage above reservation wage. Firm surplus = realized output minus wage and fees.",
    "Broker surplus = placement fees + staffing margins (bill rate minus worker wage minus employment costs).",
], "\n")
Box(fig2[4, 1:4]; color=:transparent, strokevisible=false)
Label(fig2[4, 1:4], surplus_footer;
      fontsize=12, halign=:left, valign=:top, justification=:left,
      tellwidth=false, tellheight=true,
      padding=(5, 5, 3, 3), color=:gray30)

save(joinpath(geo_outdir, "phase_surplus.png"), fig2; px_per_unit=2)
println("  Saved: $geo_tag/phase_surplus.png")

# ── Figure 3: Cumulative surplus shares ──

fig3 = Figure(; size=(950, 580), figure_padding=(10, 10, 5, 5))
Label(fig3[0, 1:4],
      "Phase diagrams: Cumulative surplus distribution over entire simulation";
      fontsize=16, font=:bold, halign=:center, tellwidth=false)
Label(fig3[1, 1:4],
      "$(titlecase(geo_label)) geometry, T=$T, $N_SEEDS seeds. Shares computed from cumulative sums over all $T periods.";
      fontsize=11, halign=:center, tellwidth=false, color=:gray30)

colsize!(fig3.layout, 1, Relative(0.42))
colsize!(fig3.layout, 2, Relative(0.06))
colsize!(fig3.layout, 3, Relative(0.42))
colsize!(fig3.layout, 4, Relative(0.06))
colgap!(fig3.layout, 2, 5)
colgap!(fig3.layout, 3, 15)

panels3 = [
    (1, 1, 2, :b_cum_bw_gap,  "Broker − worker share gap (Base)",  Reverse(:RdYlGn),  true),
    (1, 3, 4, :s_cum_bw_gap,  "Broker − worker share gap (M1)",    Reverse(:RdYlGn),  true),
    (2, 1, 2, :b_cum_bf_gap,  "Broker − firm share gap (Base)",    Reverse(:RdBu),     true),
    (2, 3, 4, :s_cum_bf_gap,  "Broker − firm share gap (M1)",      Reverse(:RdBu),     true),
]

for (row, hcol, ccol, field, title, cmap, divg) in panels3
    ax = Axis(fig3[row + 1, hcol]; title, titlesize=13, AX_KW...)
    make_phase_plot!(ax, fig3[row + 1, ccol], field_matrix(field); colormap=cmap, diverging=divg)
end

cum_footer = join([
    "Each panel shows broker cumulative surplus share minus counterparty share, summed over all $T periods.",
    "Red = broker captures a larger share; green/blue = counterparty retains more. Zero line shown in black.",
    "Unlike the per-period figure, cumulative shares reflect the full trajectory including early transients.",
], "\n")
Box(fig3[4, 1:4]; color=:transparent, strokevisible=false)
Label(fig3[4, 1:4], cum_footer;
      fontsize=12, halign=:left, valign=:top, justification=:left,
      tellwidth=false, tellheight=true,
      padding=(5, 5, 3, 3), color=:gray30)

save(joinpath(geo_outdir, "phase_surplus_cumulative.png"), fig3; px_per_unit=2)
println("  Saved: $geo_tag/phase_surplus_cumulative.png")

println()
end  # geometry loop

println("Figures: $OUTDIR")
println("Data: $DATADIR")
println("Done.")
