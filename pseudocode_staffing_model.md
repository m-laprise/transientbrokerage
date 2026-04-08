# Pseudocode: Worker Capture Through Staffing (Model 1)

## Notation

| Symbol | Description |
|--------|-------------|
| $N_W, N_F$ | Number of workers, firms |
| $d$ | Dimensionality of type vectors |
| $w_i \in \mathbb{R}^d$ | Worker $i$'s type vector |
| $x_j \in \mathbb{R}^d$ | Firm $j$'s type vector |
| $c \in \mathbb{R}^d$ | Ideal worker type vector |
| $A \in \mathbb{R}^{d \times d}$ | Interaction matrix, entries i.i.d. $\mathcal{N}(0,1)$ |
| $r_i$ | Worker $i$'s reservation wage |
| $r_\text{base}$ | Reservation wage floor $= 0.70 \cdot \bar{f}$ |
| $E_j^t$ | Firm $j$'s employee set at time $t$ |
| $\mathcal{H}_j^t$ | Firm $j$'s history: $\{(w_m, q_{mj})\}$ |
| $\mathcal{H}_b^t$ | Broker's history: $\{(w_m, x_m, q_m)\}$ |
| $R_j^t$ | Firm $j$'s referral reach |
| $G_S$ | Worker social network (undirected) |
| $N_S(i)$ | Neighbors of $i$ in $G_S$ |
| $\text{Pool}^t$ | Broker's candidate pool |
| $P$ | Target pool size $= \lceil p_\text{pool} \cdot N_W \rceil$ |
| $s_{j,c}^t$ | Firm $j$'s satisfaction for channel $c \in \{\text{int}, \text{broker}\}$ |
| $\text{rep}^t$ | Broker reputation |
| $\hat{q}_j(w)$ | Firm $j$'s predicted match output |
| $\hat{q}_b(w,x)$ | Broker's predicted match output |
| $\bar{q}_\text{pub}$ | Public benchmark $= \bar{f}$ (Monte Carlo mean of $f$) |

## Parameters

| Symbol | Default | Description |
|--------|---------|-------------|
| $d$ | 8 | Type dimensionality |
| $\rho$ | 0.50 | Quality vs. interaction mixing weight |
| $N_W$ | 1000 | Worker population (fixed) |
| $N_F$ | 50 | Firm population (with turnover) |
| $\eta$ | 0.05 | Firm exit probability per period |
| $\beta_W$ | 0.50 | Worker surplus share |
| $\alpha$ | 0.20 | Placement fee rate |
| $L$ | 4 | Staffing assignment duration (periods) |
| $\mu_b$ | 0.25 | Staffing value-capture rate |
| $c_\text{emp}$ | $0.15 \cdot r_\text{base}$ | Per-period employment overhead |
| $\lambda$ | 1.0 | Ridge regularization |
| $\omega$ | 0.30 | Satisfaction EWMA recency weight |
| $p_\text{vac}$ | 0.50 | Vacancy arrival probability |
| $k_S$ | 6 | $G_S$ degree (Watts-Strogatz) |
| $p_\text{rewire}$ | 0.10 | $G_S$ rewiring probability |
| $\sigma_w$ | 0.50 | Worker type dispersion |
| $\sigma_\varepsilon$ | 0.25 | Match output noise |
| $Q$ | 1.0 | Output offset |
| $n_\text{cand}$ | $\lceil 0.01 \cdot N_W \rceil$ | Internal search candidate count |
| $p_\text{pool}$ | 0.10 | Broker pool as fraction of $N_W$ |
| $T$ | 200 | Simulation periods |

## 1. Matching Function

$$q_{ij} = Q + f(w_i, x_j) + \varepsilon_{ij}, \qquad \varepsilon_{ij} \sim \mathcal{N}(0, \sigma_\varepsilon^2)$$

$$f(w, x) = \rho \cdot \text{sim}(w, c) + (1 - \rho) \cdot \text{sim}(w, Ax)$$

$$\text{sim}(a, b) = \frac{a^\top b}{\|a\| \, \|b\|}$$

## 2. Type Generation

**Firm types (complex geometry).** $N_F$ firms evenly spaced along a sinusoidal curve on the unit sphere:

$$\tilde{x}_k(t) = \sin(2\pi f_k t + \phi_k), \quad k = 1,\ldots,d; \qquad x(t) = \frac{\tilde{x}(t)}{\|\tilde{x}(t)\|}$$

where $f_k, \phi_k$ are random parameters drawn once. Firms at positions $t_j = (j-1)/(N_F - 1)$.

**Worker types.**

$$w_i = x_{j(i)} + \epsilon_i, \qquad j(i) \sim \mathcal{U}\{1,\ldots,N_F\}, \qquad \epsilon_i \sim \mathcal{N}\!\left(0, \frac{\sigma_w^2}{d} I_d\right)$$

**Ideal worker type.** $c = x_{j_c} + \epsilon_c$, same distribution as worker types.

## 3. Reservation Wages

$$r_i = \max\!\left(r_\text{base},\; r_\text{base} \cdot \left(1 + 0.20 \cdot \frac{\deg_S(i)}{\max_k \deg_S(k)}\right) + \epsilon_r\right), \qquad \epsilon_r \sim \mathcal{N}(0, (0.05 \cdot r_\text{base})^2)$$

## 4. Learning Models

**Firm $j$.** Ridge regression on $2d$ features, refitted each period on $\mathcal{H}_j^t$:

$$\hat{q}_j(w) = \hat{\beta}_j^\top \begin{bmatrix} w \\ w \odot w \end{bmatrix} + \hat{\alpha}_j, \qquad \hat{\beta}_j = \arg\min_\beta \sum_{m} (q_m - \beta^\top z_m - \alpha)^2 + \lambda \|\beta\|^2$$

where $z_m = [w_m;\; w_m \odot w_m] \in \mathbb{R}^{2d}$.

**Broker.** Ridge regression on $d^2 + 3d$ features, refitted each period on $\mathcal{H}_b^t$:

$$\hat{q}_b(w,x) = \hat{\beta}^\top \begin{bmatrix} w \\ x \\ \text{vec}(w \otimes x) \\ w \odot w \end{bmatrix} + \hat{\alpha}_b$$

where $w \otimes x \in \mathbb{R}^{d \times d}$ is the outer product, vectorized into $d^2$ features.

## 5. Wage and Pricing

**Direct hire / placement wage:**

$$\text{wage}_{ij} = r_i + \beta_W \cdot \max(\hat{q}_j(w_i) - r_i,\; 0)$$

**Placement fee:**

$$\phi = \alpha \cdot \text{wage}_{ij}$$

**Staffing wage:** $\text{wage}_i^\text{staff} = r_i$

**Staffing bill rate:**

$$\psi = r_i + \mu_b \cdot \hat{q}_b(w_i, x_j)$$

## 6. Staffing Decision

**Broker prefers staffing when:**

$$\underbrace{L \cdot (\mu_b \cdot \hat{q}_b - c_\text{emp})}_{\Pi^\text{staff}} > \underbrace{\alpha \cdot (r_i + \beta_W \cdot \max(\hat{q}_b - r_i, 0))}_{\Pi^\text{place}}$$

**Firm accepts staffing when:**

$$\underbrace{r_i + \mu_b \cdot \hat{q}_b}_\text{bill rate} \;\leq\; \underbrace{(r_i + \beta_W \cdot \max(\hat{q}_j - r_i, 0)) \cdot \left(1 + \frac{\alpha}{L}\right)}_\text{amortized direct-hire cost}$$

**Match is staffed iff both conditions hold; otherwise placement.**

## 7. Satisfaction Tracking

$$s_{j,c}^{t+1} = (1 - \omega)\, s_{j,c}^t + \omega \cdot \tilde{q}$$

| Channel $c$ | Net outcome $\tilde{q}$ |
|---|---|
| Internal | $q_{ij} - \beta_W \max(\hat{q}_j - r_i, 0)$ |
| Placement | $q_{ij} - \beta_W \max(\hat{q}_j - r_i, 0) - \alpha \cdot \text{wage}_{ij} / L$ |
| Staffing | $q_{ij} - \mu_b \cdot \hat{q}_b$ |
| No-proposal | $s_{j,\text{broker}}^{t+1} = (1-\omega)\, s_{j,\text{broker}}^t + \omega \cdot s_{j,\text{int}}^t$ |

## 8. Outsourcing Decision

$$\text{decision}_j = \begin{cases} \text{broker} & \text{if } \text{score}_\text{broker} > s_{j,\text{int}}^t \\ \text{internal} & \text{if } s_{j,\text{int}}^t > \text{score}_\text{broker} \\ \text{random} & \text{if tied} \end{cases}$$

$$\text{score}_\text{broker} = \begin{cases} s_{j,\text{broker}}^t & \text{if firm } j \text{ has tried broker} \\ \text{rep}^t & \text{otherwise} \end{cases}$$

## 9. Broker Reputation

$$\text{rep}^t = \begin{cases} \frac{1}{|\mathcal{J}^t|} \sum_{j \in \mathcal{J}^t} s_{j,\text{broker}}^t & \text{if } \mathcal{J}^t \neq \emptyset \\ \text{last\_reputation} & \text{if } \mathcal{J}^t = \emptyset \text{ and broker has had clients} \\ \bar{q}_\text{pub} & \text{if broker has never had clients} \end{cases}$$

where $\mathcal{J}^t = J^t \cup \{j : \text{firm } j \text{ has active staffing assignment}\}$.

## 10. Lock-In Table

| | Direct hire / Placement | Staffing |
|---|---|---|
| Worker joins $E_j$? | Yes | **No** |
| $(w_i, q)$ added to $\mathcal{H}_j$? | Yes | **No** |
| Coworker ties form in $G_S$? | Yes | **No** |
| $R_j$ grows? | Yes | **No** |
| $(w_i, x_j, q)$ added to $\mathcal{H}_b$? | Placement only | Yes |

## 11. Surplus Decomposition

For each match producing output $q_{ij}$ with reservation wage $r_i$:

| | Worker surplus | Firm surplus | Broker surplus |
|---|---|---|---|
| Direct hire | $\beta_W \max(\hat{q}_j - r_i, 0)$ | $q_{ij} - r_i - \beta_W \max(\hat{q}_j - r_i, 0)$ | $0$ |
| Placement | $\beta_W \max(\hat{q}_j - r_i, 0)$ | $q_{ij} - r_i - \beta_W \max(\hat{q}_j - r_i, 0) - \alpha \cdot \hat{w}_{ij}$ | $\alpha \cdot \hat{w}_{ij}$ |
| Staffing | $0$ | $q_{ij} - r_i - \mu_b \hat{q}_b$ | $\mu_b \hat{q}_b$ |

where $\hat{w}_{ij} = r_i + \beta_W \max(\hat{q}_j - r_i, 0)$. Broker net staffing profit per period: $\mu_b \hat{q}_b - c_\text{emp}$.

## 12. Initialization

```
INITIALIZE:

  I.1   Generate N_F firm types {x_j} on unit sphere (sinusoidal curve).
  I.2   Draw c = x_{j_c} + epsilon_c,  j_c ~ U{1,...,N_F},  epsilon_c ~ N(0, sigma_w^2/d I_d).
  I.3   Draw A in R^{d x d},  A_{kl} ~ N(0,1) i.i.d.
  I.4   for i = 1 to N_W:
          j(i) ~ U{1,...,N_F}
          w_i = x_{j(i)} + epsilon_i,  epsilon_i ~ N(0, sigma_w^2/d I_d)
  I.5   Sort workers by first principal component of {w_i}.
        Build G_S: Watts-Strogatz(N_W, k_S, p_rewire) with sorted node order.
  I.6   Compute f_bar = (1/10000) sum_{k=1}^{10000} f(w_{i_k}, x_{j_k})
        over random (w, x) pairs using actual firm types.
        q_pub := f_bar;  r_base := 0.70 * f_bar;  c_emp := 0.15 * r_base.
  I.7   for i = 1 to N_W:
          Compute r_i per Section 3 using r_base and deg_S(i).
  I.8   for j = 1 to N_F:
          n_j ~ U{6,...,10}
          Sample n_j available workers with prob proportional to exp(-||w_i - x_j||^2).
          for each sampled worker i:
            status_i := employed;  employer_i := j;  add i to E_j.
            q := Q + f(w_i, x_j) + epsilon,  epsilon ~ N(0, sigma_eps^2).
            Append (w_i, q) to H_j.
          Connect all workers in E_j pairwise in G_S.
          R_j^0 := Union_{i in E_j} N_S(i) \ E_j.
          s_{j,int}^0 := q_pub;  s_{j,broker}^0 := q_pub;  vacancies_j := 0.
  I.9   Pool^0 := sample P available workers uniformly.
        Seed H_b with 20 random (w_i, x_j, q_{ij}) from existing employed pairs.
  I.10  rep^0 := q_pub;  last_reputation := q_pub;  active_assignments := [].
```

## 13. Per-Period Algorithm

```
PERIOD t:

  ================================================================
  STEP 0: BROKER POOL MAINTENANCE
  ================================================================
    Remove from Pool^t any worker i with status != available.
    n_gap := P - |Pool^t|.
    if n_gap > 0:
      eligible := {i : status_i = available} \ Pool^t
      n_ref := floor(n_gap / 2)
      ref_candidates := Union_{i in Pool^t} N_S(i)  intersect  eligible
      Sample min(n_ref, |ref_candidates|) from ref_candidates uniformly.
      Sample remaining (n_gap - n_sampled) from eligible uniformly.
      Add all sampled workers to Pool^t.

  ================================================================
  STEP 1: REFERRAL POOL COMPUTATION
  ================================================================
    for each firm j:
      R_j^t := Union_{i in E_j^t} N_S(i) \ E_j^t

  ================================================================
  STEP 2: VACANCY MANAGEMENT AND OUTSOURCING
  ================================================================
    for each firm j with vacancies_j = 0:
      With prob p_vac:
        vacancies_j := random draw from {1, 2} with equal probability.

    for each firm j with vacancies_j > 0:
      score_int := s_{j,int}^t
      score_bkr := s_{j,broker}^t  if tried_broker_j else rep^t
      if score_bkr > score_int:       decision_j := broker
      else if score_int > score_bkr:  decision_j := internal
      else:                            decision_j := coin flip

    J^t := {j : decision_j = broker}       // broker client list

  ================================================================
  STEP 3: CANDIDATE GENERATION AND EVALUATION
  ================================================================

    proposals := []

    -- 3a. Internal search --
    for each firm j with decision_j = internal:
      for v = 1 to vacancies_j:
        Draw floor(n_cand/2) from {available} intersect R_j^t, uniformly.
        Draw ceil(n_cand/2) from {available} \ R_j^t, uniformly.
        candidates := union of above.
        Refit firm j's ridge model on H_j^t (Section 4).
        for each candidate i:
          Compute q_hat_j(w_i).
        i* := argmax_i q_hat_j(w_i)        // ties: uniform random
        if q_hat_j(w_{i*}) > r_{i*}:
          wage := r_{i*} + beta_W * max(q_hat_j(w_{i*}) - r_{i*}, 0)
          Append ProposedMatch(firm=j, worker=i*, source=internal,
                               q_hat_j=q_hat_j(w_{i*}), q_hat_b=0, wage=wage)
                               to proposals.

    -- 3b. Broker greedy allocation --
    Refit broker's ridge model on H_b^t (Section 4).
    avail_pool := Pool^t intersect {available workers}
    open_slots := {(j, v) : j in J^t, v = 1..vacancies_j}

    Compute Q_hat[i, j] := q_hat_b(w_i, x_j)
      for all i in avail_pool, j in {firms in open_slots}.

    while avail_pool non-empty AND open_slots non-empty:
      (i*, j*) := argmax_{i,j} Q_hat[i,j]    // ties: uniform random
      if Q_hat[i*, j*] <= r_{i*}: break

      q_hat_b_val := Q_hat[i*, j*]

      // Firm evaluates candidate with its own model
      q_hat_j_val := q_hat_{j*}(w_{i*})

      // Staffing decision (Section 6)
      staff_profit := L * (mu_b * q_hat_b_val - c_emp)
      est_wage := r_{i*} + beta_W * max(q_hat_b_val - r_{i*}, 0)
      place_profit := alpha * est_wage
      bill_rate := r_{i*} + mu_b * q_hat_b_val
      direct_cost := (r_{i*} + beta_W * max(q_hat_j_val - r_{i*}, 0)) * (1 + alpha/L)

      if staff_profit > place_profit AND bill_rate <= direct_cost:
        source := staffing
        wage := r_{i*}
      else:
        source := placement
        wage := r_{i*} + beta_W * max(q_hat_j_val - r_{i*}, 0)

      Append ProposedMatch(firm=j*, worker=i*, source=source,
                           q_hat_j=q_hat_j_val, q_hat_b=q_hat_b_val,
                           wage=wage) to proposals.
      Remove i* from avail_pool.
      Remove one slot for j* from open_slots.

    for each j in J^t with remaining unfilled slots:
      Mark j as no-proposal.

  ================================================================
  STEP 4: MATCH FORMATION
  ================================================================

    -- 4a. Conflict resolution --
    Group proposals by worker_id.
    for each worker i with |proposals_i| > 1:
      accepted := proposal with max wage     // ties: uniform random
      Discard all other proposals for i.
    accepted_matches := all surviving proposals.

    -- 4b. Finalization --
    for each accepted match m = (j, i*, source, q_hat_j, q_hat_b, wage):

      q := Q + f(w_{i*}, x_j) + epsilon,   epsilon ~ N(0, sigma_eps^2)

      CASE source = internal:
        status_{i*} := employed;  employer_{i*} := j.
        E_j := E_j union {i*}.
        Append (w_{i*}, q) to H_j.
        Coworker ties: sample min(5, floor(|E_j|/2)) members of E_j \ {i*};
                       add edges (i*, k) to G_S for each sampled k.
        vacancies_j -= 1.

      CASE source = placement:
        status_{i*} := employed;  employer_{i*} := j.
        E_j := E_j union {i*}.
        Append (w_{i*}, q) to H_j.
        Append (w_{i*}, x_j, q) to H_b.
        Coworker ties: same as internal.
        Broker revenue: Pi_b += alpha * wage.
        vacancies_j -= 1.

      CASE source = staffing:
        status_{i*} := staffed;  broker_{i*} := b;  staffing_firm_{i*} := j.
        Append StaffingAssignment(
          worker=i*, firm=j, periods_remaining=L,
          reservation_wage=r_{i*},
          bill_rate=r_{i*} + mu_b * q_hat_b,
          realized_q=q,  predicted_q=q_hat_b
        ) to active_assignments.
        Append (w_{i*}, x_j, q) to H_b.
        // LOCK-IN: E_j unchanged. H_j unchanged. No coworker ties.
        vacancies_j -= 1.

    -- 4c. Satisfaction updates (Section 7) --
    for each accepted match m = (j, i*, source, ...):
      Compute tilde_q per Section 7 table using source.
      s_{j, channel(source)}^{t+1} := (1-omega) * s_{j, channel(source)}^t + omega * tilde_q
      if source in {placement, staffing}: tried_broker_j := true.

    for each firm j marked no-proposal:
      s_{j,broker}^{t+1} := (1-omega) * s_{j,broker}^t + omega * s_{j,int}^t

  ================================================================
  STEP 4b: STAFFING ECONOMICS
  ================================================================
    for each StaffingAssignment sa in active_assignments:
      // Per-period surplus (Section 11)
      total_surplus  += sa.realized_q - sa.reservation_wage
      firm_surplus   += sa.realized_q - sa.reservation_wage - mu_b * sa.predicted_q
      broker_surplus += mu_b * sa.predicted_q
      broker_net     += mu_b * sa.predicted_q - c_emp

      sa.periods_remaining -= 1
      if sa.periods_remaining <= 0:
        status_{sa.worker} := available;  broker_{sa.worker} := null;
        staffing_firm_{sa.worker} := null.
        if vacancies_{sa.firm} < 2:
          vacancies_{sa.firm} += 1.
        Remove sa from active_assignments.

  ================================================================
  STEP 5: REPUTATION UPDATE (Section 9)
  ================================================================
    J_active := J^t  union  {j : firm j has active staffing assignment}
    if |J_active| > 0:
      rep^t := (1/|J_active|) sum_{j in J_active} s_{j,broker}^t
      last_reputation := rep^t
    else if has_had_clients:
      rep^t := last_reputation
    else:
      rep^t := q_pub

  ================================================================
  STEP 6: ENTRY AND EXIT
  ================================================================
    for each firm j:
      With prob eta:
        // EXIT
        for each i in E_j:
          status_i := available;  employer_i := null.
        for each sa in active_assignments where sa.firm = j:
          status_{sa.worker} := available;  broker_{sa.worker} := null;
          staffing_firm_{sa.worker} := null.
          Remove sa from active_assignments.

        // ENTRY (replacement)
        Draw t' ~ U[0,1]; set x_{j'} from firm curve at t'.
        n_{j'} ~ U{6,...,10}.
        Sample n_{j'} available workers with prob proportional to exp(-||w_i - x_{j'}||^2).
        for each sampled worker i:
          status_i := employed;  employer_i := j'.
          q := Q + f(w_i, x_{j'}) + epsilon.
          Append (w_i, q) to H_{j'}.
        E_{j'} := {sampled workers}.
        Connect all workers in E_{j'} pairwise in G_S.
        R_{j'}^t := Union_{i in E_{j'}} N_S(i) \ E_{j'}.
        s_{j',int} := q_pub;  s_{j',broker} := q_pub.
        tried_broker_{j'} := false;  vacancies_{j'} := 0.
        H_{j'} seeded from initial hires above.

  ================================================================
  STEP 7: NETWORK MEASURES (every M periods, default M=10)
  ================================================================
    Construct combined graph G:
      Nodes: {1,...,N_W} (workers), {N_W+1,...,N_W+N_F} (firms), {N_W+N_F+1} (broker).
      Edges:
        (i, k) for all (i,k) in G_S.                                     // worker-worker
        (i, N_W+j) for all i in E_j, all j.                              // employment (direct only)
        (N_W+N_F+1, i) for all i in Pool^t.                              // broker-pool worker
        (N_W+N_F+1, i) for all i with status_i = staffed.                // broker-staffed worker
        (N_W+N_F+1, N_W+j) for all j in J^t.                            // broker-client firm
        (N_W+N_F+1, N_W+j) for all j with active staffing assignment.    // broker-staffed firm

    Cross-mode betweenness centrality of broker node b:
      C_B^x(b) = (1 / N_W N_F) sum_{i in workers} sum_{j in firms} sigma_{ij}(b) / sigma_{ij}
      where sigma_{ij} = number of shortest i-j paths, sigma_{ij}(b) = those through b.

    Burt's constraint:
      C_b = sum_j (p_{bj} + sum_{q != b,j} p_{bq} p_{qj})^2
      where p_{bj} = 1/|N(b)| (unweighted).

    Effective size:
      ES_b = |N(b)| - sum_j p_{bj} sum_{q != b} p_{bq} m_{jq}
      where m_{jq} = 1 if j and q are connected.
```
