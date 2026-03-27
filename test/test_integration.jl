using Test
using TransientBrokerage
using DataFrames: DataFrame, nrow, names, eltype

@testset "Integration: run_simulation" begin
    params = default_params()

    # Full 200-period run with invariant checking
    @testset "200 periods with invariants" begin
        state, mdf = run_simulation(params; verify=true)
        @test state.period == params.T
        @test nrow(mdf) == params.T
    end

    # DataFrame has expected columns
    @testset "DataFrame columns" begin
        _, mdf = run_simulation(params)
        expected_cols = [:period, :matches, :outsourcing_rate,
                         :openings_internal, :openings_brokered,
                         :vacancies_internal, :vacancies_brokered,
                         :q_direct_mean, :q_placed_mean,
                         :n_direct, :n_placed,
                         :broker_history_size, :broker_pool_size,
                         :broker_reputation, :betweenness, :constraint,
                         :effective_size, :placement_revenue,
                         :cumulative_placement_revenue,
                         :access_count, :assessment_count,
                         :firm_r_squared_rolling, :broker_r_squared_rolling,
                         :firm_bias_rolling, :broker_bias_rolling,
                         :firm_rank_corr_rolling, :broker_rank_corr_rolling,
                         :firm_r_squared_holdout, :broker_r_squared_holdout,
                         :firm_bias_holdout, :broker_bias_holdout,
                         :firm_rank_corr_holdout, :broker_rank_corr_holdout,
                         :n_available, :avg_firm_size]
        @test all(col in Symbol.(names(mdf)) for col in expected_cols)
    end

    # No NaN in non-optional integer columns
    @testset "integer columns have no NaN" begin
        _, mdf = run_simulation(params)
        int_cols = [:period, :matches, :openings_internal, :openings_brokered,
                    :vacancies_internal, :vacancies_brokered, :n_direct, :n_placed,
                    :broker_history_size, :broker_pool_size,
                    :access_count, :assessment_count]
        for col in int_cols
            @test all(isfinite.(Float64.(mdf[!, col])))
        end
    end

    # Network measures are NaN before first measurement, finite after
    @testset "network measures finite after period M" begin
        _, mdf = run_simulation(params)
        M = params.network_measure_interval
        @test all(isnan.(mdf.betweenness[1:M-1]))
        @test all(isfinite.(mdf.betweenness[M:end]))
        @test all(isfinite.(mdf.constraint[M:end]))
        @test all(isfinite.(mdf.effective_size[M:end]))
    end

    # Holdout R-squared should be finite after a few periods
    @testset "holdout R-squared becomes finite" begin
        _, mdf = run_simulation(params)
        post_burn = mdf.firm_r_squared_holdout[params.T_burn+1:end]
        @test any(isfinite.(post_burn))
        post_burn_b = mdf.broker_r_squared_holdout[params.T_burn+1:end]
        @test any(isfinite.(post_burn_b))
    end

    # Outsourcing rate always in [0, 1]
    @testset "outsourcing rate in valid range" begin
        _, mdf = run_simulation(params)
        @test all(0.0 .<= mdf.outsourcing_rate .<= 1.0)
    end

    # Cumulative placement revenue is monotonically non-decreasing
    @testset "cumulative revenue monotonic" begin
        _, mdf = run_simulation(params)
        @test all(diff(mdf.cumulative_placement_revenue) .>= -1e-10)
    end

    # Deterministic: same params + seed produces identical DataFrame
    @testset "deterministic with fixed seed" begin
        _, mdf1 = run_simulation(params)
        _, mdf2 = run_simulation(params)
        @test mdf1.matches == mdf2.matches
        @test mdf1.outsourcing_rate == mdf2.outsourcing_rate
        @test mdf1.broker_history_size == mdf2.broker_history_size
    end

    # diagnostic_summary returns a populated Dict
    @testset "diagnostic_summary" begin
        state, _ = run_simulation(params)
        d = diagnostic_summary(state)
        @test d["period"] == params.T
        @test d["n_workers"] == params.N_W
        @test d["n_firms"] == length(state.firms)
        @test isfinite(d["betweenness"])
        @test isfinite(d["broker_reputation"])
    end

    # Prediction/outcome pairs are correctly wired in step_period!
    @testset "prediction pair recording" begin
        params2 = default_params()
        state = initialize_model(params2)
        # Run enough periods for matches to accumulate
        for _ in 1:20
            step_period!(state)
        end
        a = state.accum
        # firm_predicted and firm_realized have same length (one pair per match)
        @test length(a.firm_predicted) == length(a.firm_realized)
        @test length(a.firm_predicted) == a.matches
        # broker pairs are a subset (only broker matches)
        @test length(a.broker_predicted) == length(a.broker_realized)
        @test length(a.broker_predicted) <= a.matches
        # Values are finite (not uninitialized)
        if !isempty(a.firm_predicted)
            @test all(isfinite, a.firm_predicted)
            @test all(isfinite, a.firm_realized)
        end
        if !isempty(a.broker_predicted)
            @test all(isfinite, a.broker_predicted)
            @test all(isfinite, a.broker_realized)
        end
    end
end
