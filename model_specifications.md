# Model Specification: Transient Brokerage in Matching Markets

This document details the specifications of an agent-based model of brokered matching meant to formalize and demonstrate the theory of brokerage put forward in the project titled "Transient Brokerage."

## Theory Overview

The structural-hole theory of brokerage (Burt, 1992) locates the broker's value in its network position, bridging disconnected parties. Structural-hole brokerage, when performed at scale, can be self-liquidating: each successful match creates a direct tie that densifies the network and closes the holes that created bridging opportunities in the first place, unless the broker aggressively recruits new, distant clients.

I propose a complementary view of brokerage. Brokerage is outsourced relational work: the broker constructs viable matches between parties who cannot easily evaluate each other. This relational work generates an informational byproduct that the broker can leverage. The broker accumulates knowledge of how to match heterogeneous parties. Structural position provides the access that feeds learning, but while each successful match erodes the broker's structural advantage, it also strengthens its informational position (by adding an observation to its experience of the matching function).

The broker converts structural capital into informational capital through the act of brokering. When the matching problem is sufficiently complex, the informational capital compounds faster than structural capital erodes, and this compounding advantage can support a transition from intermediation to capture, transforming the broker into a principal selling the resource it was formerly intermediating or data and analytics. This is *transient brokerage*, a process that highlights the broker's power rather than its fragility.

This project develops an agent-based model of brokered matching to formalize and demonstrate the theoretical framework. In the model, agents seeking pairwise matches either search their own network or outsource the search to a broker. Capture can take two forms: resource capture, where the broker becomes a principal and locks clients out of learning, or data capture, where the broker sells its predictions as an analytics service while clients continue matching directly. All agents use heuristic decision rules. No agent solves an optimization problem or holds beliefs about other agents' strategies.

## Questions

1. Under what conditions does the broker develop, maintain, or lose an informational advantage over its clients?

2. Under what conditions can the broker leverage its advantage for capture?

3. What form does capture take and how does capture impact the dynamics of the broker's advantage?

## Main Propositions

The simulation is designed to demonstrate the following propositions.

### Premise

**1. A broker provides value in a matching market because of its structural or informational advantages.** A broker helps create a match between principals who, without the broker's intervention, could not easily find each other (access; structural advantage) or were unaware that they would benefit from a match (matchmaking; informational advantage). In other words, the broker's service is valuable both because it can find counterparties that clients cannot reach and because it can assess match quality better than its clients can.

- ***The existence of a structural advantage depends purely on network topology.*** It can be measured using betweenness centrality, constraint, and effective size.

- ***The emergence of an informational advantage depends on the value of the data a broker and its clients accumulate, which in turn depends on the form and difficulty of the matching problem.*** When the matching problem is hard to solve, local or limited experience can be insufficient relative to a broker's high volume of cross-market data.

### 1. Advantage

#### Proposition 1.1

**A broker's structural and informational advantages exhibit distinct dynamics over repeated brokerage activity.**

**1.1a. Structural advantage tends to be self-liquidating.** A broker that bridges a gap between two principals, and successfully matches them, creates a direct relationship between them. With each match, the broker's network position weakens. Direct ties accumulate between principals and structural holes close. This is particularly the case when brokerage occurs at scale. A broker can counteract the self-liquidating tendency by aggressively recruiting new candidates, continuously expanding its reach into parts of the network that principals cannot yet access. However, when the broker's pool of candidates is stable or slowly evolving, placements create direct ties faster than new structural holes are bridged, and the erosion of structural advantage dominates.

**1.1b. Informational advantage tends to be self-reinforcing.** Each match generates information about what makes pairings succeed or fail in a given market. The broker's cross-market experience, whether it helps assess general counterparty quality or understand pairing complementarities, generates an informational advantage over each client's limited within-agent perspective. This advantage grows with the volume and diversity of the broker's placement history.

#### Proposition 1.2

**The broker's informational advantage arises primarily from understanding pairing complementarities (the relational channel) rather than from better assessing counterparty quality (the attributional channel), and the extent of the dominance of the relational channel depends on the structure of the data-generating process.**

The broker's advantage will be largest when the interaction component dominates (relational channel), rather than when the general quality component dominates (attributional channel). This difference is more or less pronounced depending on the structure of the data-generating process.

Assessing match quality involves two components: assessing the general quality of each good or counterparty involved, and assessing the quality of the specific pairing or relational package being considered.

The broker observes outcomes from many different pairings across principals, while each principal observes outcomes only from its own matches. This gives the broker two potential channels of informational advantage: (1) better estimation of counterparty quality from cross-market data (the attributional channel), and (2) better understanding of pairing complementarities from observing the same counterparties matched with different principals (the relational channel).

Important models in the economics literature have characterized the broker's role as quality certification (Li, 1998) or expert screening (Bethune, Sultanum, and Trachter, 2024): the broker identifies which goods or counterparties are high quality. He is an appraiser whose cross-market experience helps it assess the general quality of counterparties more accurately than individual principals can.

The relational-work view of brokerage rather suggests that the broker's value lies in understanding complementarities between counterparties and shaping relational packages accordingly. The broker is a relational worker and a matchmaker whose advantage comes from knowing which pairings will succeed.

#### Proposition 1.3

**Network topology influences whether an active broker's structural or informational advantages dominate.**

**1.3a. In sparse or small-world networks, an active broker's value depends primarily on its structural advantage, which is correlated with its informational advantage.** Principals cannot easily find each other in such a network. Standard structural-hole measures (betweenness centrality, constraint, effective size) predict broker value well in this regime. At the same time, structural holes provide the access that feeds the broker's learning, so its structural and informational advantages are positively correlated.

**1.3b. In dense (or densifying) networks, an active broker's value depends primarily (or increasingly) on its informational advantage, which can become decoupled from its structural advantage.** Even if principals could find each other, a broker provides value if it can predict match quality better than principals can. A broker that started in a strong structural position may possess a lot of accumulated cross-market knowledge, regardless of its current structural advantage. As a broker's structural position weakens as a result of its brokerage activity, it accumulates more data, and the correlation between the two types of advantages weakens. In the limit, the broker has no structural advantage but retains its informational advantage.

### 2. Conditions for capture

#### Proposition 2.1

**A broker can leverage its informational advantage to transition from intermediary to principal (capture by the broker). The informational channel, not the structural one, drives capture.** A broker's information advantage translates into higher quality predictions of matching outputs and matches providing higher value to clients. Instead of continuing to facilitate these matches, the broker can leverage its predictive ability to capture the resource it was intermediating and become a principal.

At the point of capture, the broker's structural advantage may be declining (it has closed many of the gaps it once bridged). Standard structural-hole measures would predict that the broker is losing power exactly when it is consolidating it.

#### Proposition 2.2

**Capture requires specific conditions and does not occur universally. It is more likely when matching is complex and markets are opaque.**

High matching complexity and low transparency make the principals' learning problem harder, widening and preserving the broker's advantage.

In transparent markets with simple matching problems, principals learn fast and well enough that the broker does not accumulate a decisive informational advantage. Brokers persist as commodity intermediaries earning thin margins and may attempt capture but do not consolidate into dominant principals. This is the no-capture region of the parameter space.

Within the capture region of the parameter space, if the broker does not capture, its information advantage may start to erode over time.

### 3. Forms of capture

#### Proposition 3

**Capture can occur in two forms with qualitatively different dynamics.**

**3a. Under resource capture, the transition is abrupt, and the broker suddenly starts taking inventory risk and acting primarily as a principal.** Resource capture creates a triple lock-in: the client's information state freezes (it doesn't learn from new matches like it did when the broker acted as an intermediary), the client's network no longer grows (the broker is everyone's counterparty, so no direct ties form between principals), and the open market thins as the broker acquires counterparty positions (supply-side scarcity). The self-liquidating dynamic of structural advantage is suspended, because the broker no longer creates direct ties between clients. This produces a steep capture trajectory.

**3b. Under data capture, the transition is gradual, and the broker progressively monetizes its informational advantage by acting as a principal in subscription contracts.** Clients continue making new matches, learning from outcomes, and growing their networks. The self-liquidating dynamic of structural advantage continues operating. This produces a smooth capture trajectory.

## Illustrative Domains

The model is domain-agnostic: it formalizes brokered matching between heterogeneous agents in a single population. It represents any market in which a broker facilitates pairwise matches, and accumulates cross-market data from doing so while facing structural erosion from the direct ties it creates.

Because of its level of generality, the model can equally be taken to represent a variety of empirical domains in which real life brokers sometime transition to become principals; here I describe three of them, which I will refer to as illustrative examples throughout this section, to make things more concrete.

**Interdealer brokerage in OTC financial markets.** Dealers in over-the-counter markets (interest rate swaps, foreign exchange, corporate bonds) need counterparties for trades. Interdealer brokers (IDBs) sit between dealers, matching buy and sell interests across the market. Each successful brokered trade creates a direct relationship between two dealers who can subsequently trade bilaterally. The IDB accumulates cross-market knowledge of which dealer pairings clear efficiently. The well-documented transition from voice brokerage to electronic trading platforms (ICAP → NEX/CME, BGC → Fenics) is an instance of data capture; IDBs that became principal traders illustrate resource capture.

**Dealer networks in collectible markets.** Collectors of art, wine, rare books, or similar specialty goods seek trades or sales through dealers who know the market. Each collector has distinct tastes and holdings; match quality depends on multidimensional complementarity between what one party has and what another wants. Dealers accumulate knowledge of collector preferences across transactions. A dealer who transitions from pure intermediation to holding inventory (gallery, wine merchant) illustrates resource capture; one who builds a valuation database or subscription advisory service illustrates data capture.

**Import-export trading companies.** Producers and buyers across international markets rely on trading intermediaries to find counterparties they cannot easily reach or evaluate. Trading companies (*sōgō shōsha*, commodity brokers, Hong Kong trading houses) bridge geographically and informationally separated markets, matching exporters' goods with importers' needs. Match quality depends on multidimensional compatibility of product specifications, volumes, timing, and quality standards. Each successful brokered trade creates a direct relationship between producer and buyer who can subsequently trade bilaterally. The trading company's informational advantage lies in knowing which supplier-buyer combinations work across many markets. The transition from pure intermediation to taking principal positions (buying commodities from producers and reselling to buyers, bearing inventory and price risk) is the canonical resource capture trajectory. Some trading companies evolve further into vertically integrated conglomerates.

## Part I. Base Model

The model is a discrete-time agent-based simulation of a matching market with two participant types: *agents* and a *broker*. Agents seeking pairwise matches either search their own network or outsource the search to the broker. Each period represents one calendar quarter. All economic quantities (match output, fees, surplus) are in the same monetary units.

A single broker serves the market. This is a simplification: with multiple brokers, the data pool fragments, there is competition for informational rents, and no single broker consolidates as large an informational advantage. The model can be interpreted as a monopolistic broker or as a single broker's segment within a competitive market. Analysis of broker competition is deferred to future work.

All agents use heuristic decision rules. No agent solves an optimization problem or holds beliefs about other agents' strategies, in line with the tradition of ABM agents using simple, bounded-rationality rules grounded in empirically observable behavior (Brenner, 2006).

The base model specifies agents (§0), the matching problem (§1), how agents learn to predict match quality (§2), match economics (§3), network structure and agent turnover (§4), how agents and the broker find counterparties (§5), the outsourcing decision (§6), the broker's roster (§7), the match lifecycle (§8), and the complete step ordering (§9). There is no capture in the base model. Resource capture is specified in Part III (§12).

### 0. Agents

The model has $N$ agents (default 1000) and a single broker. Agents are nodes in an undirected network $G$ that determines their search opportunities: an agent can only find counterparties among its direct connections in $G$ (§5). The network is initialized as a small-world graph with random node ordering (no built-in type assortativity). It evolves over time as matches create new edges between matched agents (§4).

Each agent $i$ is characterized by:

- **Type** $\mathbf{x}_i \in \mathbb{R}^d$: a fixed vector of observable characteristics assigned at initialization. Types determine general quality and productive compatibility with other agents through the matching function (§1). The dimensionality $d = 8$ is fixed.
- **Active matches** $M_i^t$: the list of active matches involving $i$. The same counterparty may appear multiple times (concurrent matches with the same partner are allowed). The length $|M_i^t| \leq K$ (default $K = 5$).
- **Available capacity**: $K - |M_i^t|$, the number of additional matches the agent can enter.
- **Experience history** $\mathcal{H}_{i}^t = \{(\mathbf{x}_j, q_{ij})\}$: the set of (other party's type, realized match output) pairs from all matches $i$ has participated in, regardless of whether $i$ was the demander or the counterparty (§2a). Because the matching function is symmetric (§1a), both roles produce the same prediction target.
- **Satisfaction indices** $s_{i,c}^t$: one scalar per search channel $c \in \{\text{self}, \text{broker}\}$, tracking realized match value via an EWMA (§6a). Drives the outsourcing decision (§6).
- **Outside option** $r$: the minimum match value any agent requires to participate in a match (§3). Constant across agents, calibrated at initialization.

Agents exit independently each period with probability $\eta$ (default 0.02) and are replaced by new entrants with fresh types, empty histories, and satisfaction initialized at the public benchmark (§4).

#### Agent types

Agents are described by type vectors in $\mathbb{R}^d$ ($d = 8$). These types are the observable characteristics that determine productive compatibility through the matching function (§1).

Agent types lie near a smooth one-dimensional curve on the surface of the unit sphere in $\mathbb{R}^d$. The curve is parameterized by a position $t \in [0, 1]$:

$$\mathbf{x}(t) = \frac{\tilde{\mathbf{x}}(t)}{\|\tilde{\mathbf{x}}(t)\|}, \qquad \tilde{x}_k(t) = \begin{cases} \sin(2\pi f_k t + \theta_k) & k = 1, \ldots, s \\ 0 & k = s+1, \ldots, d \end{cases}$$

where $f_k \sim U\{1, 2, 3, 4, 5\}$ are random integer frequencies and $\theta_k \sim U[0, 2\pi)$ are random phases, both drawn once per simulation, and $s \leq d$ is the number of **active dimensions** (the dimensions along which the curve has nonzero variation). The remaining $d - s$ dimensions receive only noise (see below).

Each agent is drawn at a random position $t_i \sim U[0,1]$ on the curve, then perturbed:

$$\mathbf{x}_i = \frac{\mathbf{x}(t_i) + \boldsymbol{\epsilon}_i}{\|\mathbf{x}(t_i) + \boldsymbol{\epsilon}_i\|}, \qquad \boldsymbol{\epsilon}_i \sim N\!\left(\mathbf{0}, \frac{\sigma_x^2}{d} \mathbf{I}_d\right)$$

The noise $\boldsymbol{\epsilon}_i$ is applied in all $d$ dimensions (including inactive ones), so that type vectors are not exactly confined to the $s$-dimensional subspace of the curve. The per-dimension noise scale $\sigma_x / \sqrt{d}$ is chosen so that the expected Euclidean distance from an agent to its curve position is approximately $\sigma_x$ regardless of $d$. The result is then re-projected to the unit sphere.

The parameter $s$ controls the complexity of the matching problem. When $s = d$, the curve spans all $d$ dimensions: agents nearby on the curve have similar types, while agents far apart point in genuinely different directions across all of $\mathbb{R}^d$. When $s < d$, the curve is confined to a lower-dimensional subspace.

#### Broker

A single broker serves the market. The broker is a permanent node in $G$, connected to all agents on its roster. The broker is characterized by:

- **Experience history** $\mathcal{H}_b^t = \{(\mathbf{x}_i, \mathbf{x}_j, q_{ij})\}$: the set of (demander type, counterparty type, realized match output) triples from all matches the broker has mediated (§2c).
- **Roster** $\text{Roster}^t$: the set of agents the broker knows and can propose as counterparties. Grows over time as agents outsource to the broker (§7).
- **Reputation** $\text{rep}^t$: the average satisfaction of current client agents (§6).

### 1. The Matching Problem

The model's central dynamics depend on a matching problem: how valuable will the match between agents $i$ and $j$ be? No agent knows the answer in advance; all must learn it from experience.

The structure of the matching problem and how the broker and agents try to solve it determines whether and when the broker develops an informational advantage over the agents it serves.

**Match quality** (§1a) is symmetric: $f(\mathbf{x}_i, \mathbf{x}_j) = f(\mathbf{x}_j, \mathbf{x}_i)$. Match quality is a property of the pairing, not of which party initiated the match. It decomposes into two components:

- **General quality** (§1b): each party's baseline contribution to any match, independent of who the other party is.
- **Match-specific interaction** (§1c): how well this particular pairing works, depending on both parties' types.

The broker, which mediates matches across many agents, observes the same agent types producing different outcomes with different counterparties; whereas each agent only sees its own matching history.

#### 1a. Match quality

Let $q_{ij}$ represent the **per-period value of the match between agents $i$ and $j$**. It is a function of both agents' types, it is measured in monetary units, and it represents the economic value the match generates:

$$q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}, \qquad
\varepsilon_{ij} \sim N(0, \sigma_\varepsilon^2)$$

where $Q = 1.0$ is a constant offset that shifts $q$ positive for downstream economic computations (surplus, fees, satisfaction), and $\sigma_\varepsilon = 0.10$. The noise term $\varepsilon_{ij}$ represents idiosyncratic match-specific variation (unobserved characteristics, timing, context) that is irreducible even with perfect knowledge of $f$.

The matching function $f: \mathbb{R}^d \times \mathbb{R}^d \to \mathbb{R}$ is unknown to all agents and fixed for the duration of the simulation. $f$ represents the pure signal structure of the data-generating process.

The deterministic matching function has two components, the first relating to each party's general quality and the second to their pairing complementarity:

$$f(\mathbf{x}_i, \mathbf{x}_j) = \rho \cdot \frac{1}{2}\!\left[\mathbf{x}_i^\top \mathbf{c} + \mathbf{x}_j^\top \mathbf{c}\right] + (1 - \rho) \cdot g(\mathbf{x}_i, \mathbf{x}_j) \cdot \mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j$$

where $\mathbf{c} \in \mathbb{R}^d$ is an ideal type vector (§1b), $\mathbf{A} \in \mathbb{R}^{d \times d}$ is a symmetric random interaction matrix (§1c), and $g(\mathbf{x}_i, \mathbf{x}_j)$ is a **regime-dependent gain** that modulates the interaction strength (§1c). The gain $g$ depends on a second symmetric random matrix $\mathbf{B}$ that determines whether a pairing is in a high-gain or low-gain regime. Because $\mathbf{A}$ and $\mathbf{B}$ are symmetric, $\mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j = \mathbf{x}_j^\top \mathbf{A} \mathbf{x}_i$ and $g(\mathbf{x}_i, \mathbf{x}_j) = g(\mathbf{x}_j, \mathbf{x}_i)$, so $f(\mathbf{x}_i, \mathbf{x}_j) = f(\mathbf{x}_j, \mathbf{x}_i)$.

The mixing weight $\rho$ (§1d) controls how much the general quality component contributes to total match output compared to the interaction component.

#### 1b. Agent general quality

General quality captures the portable value each party brings to any match, independent of who the counterparty is. Both parties contribute quality through their dot product with an **ideal type vector** $\mathbf{c} \in \mathbb{R}^d$. Agents whose types are aligned with $\mathbf{c}$ are high-quality counterparties in any match.

The vector $\mathbf{c}$ is drawn at initialization as a perturbation of a random point on the agent type curve with the same $\sigma_x / \sqrt{d}$ per-dimension noise used for regular agents.

A match between two high-quality agents produces a high quality component; a match involving a low-quality agent is penalized regardless of the other party's quality. 

#### 1c. Match-specific interaction

The match-specific interaction combines a base interaction with a regime-dependent gain: $g(\mathbf{x}_i, \mathbf{x}_j) \cdot \mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j$.

**Base interaction.** The bilinear form $\mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j$ measures the complementarity of the pairing. The interaction matrix $\mathbf{A} \in \mathbb{R}^{d \times d}$ is symmetric positive definite (SPD), constructed as $\mathbf{A} = \mathbf{M}_A^\top \mathbf{M}_A \cdot (d / \text{tr}(\mathbf{M}_A^\top \mathbf{M}_A))$ where $\mathbf{M}_A$ has iid $N(0,1)$ entries. The trace normalization ensures $\text{tr}(\mathbf{A}) = d$, so that $E[\mathbf{x}^\top \mathbf{A} \mathbf{x}] = 1$ for random unit vectors, keeping the bilinear form at unit scale. $\mathbf{A}$ is fixed for the duration of the simulation.

Because $\mathbf{A}$ is symmetric, $\mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j = \mathbf{x}_j^\top \mathbf{A} \mathbf{x}_i$, so the base interaction is symmetric without explicit symmetrization. Positive definiteness ensures $\mathbf{A}$ has full rank and well-conditioned eigenvalues, so the interaction structure spans all $d$ dimensions without degenerate directions. The interaction depends on all $d(d+1)/2$ distinct cross-dimensional products $x_{i,k} \cdot x_{j,l}$ (for $k \leq l$).

**Regime-dependent gain.** A second SPD matrix $\mathbf{B} \in \mathbb{R}^{d \times d}$ (independent of $\mathbf{A}$, same construction including trace normalization) determines a gain that amplifies or attenuates the base interaction:

$$g(\mathbf{x}_i, \mathbf{x}_j) = 1 + \delta \cdot \text{sign}(\mathbf{x}_i^\top \mathbf{B} \mathbf{x}_j)$$

where $\delta \in (0, 1)$ (default 0.5) controls the gain strength. Because $\mathbf{B}$ is symmetric, $g(\mathbf{x}_i, \mathbf{x}_j) = g(\mathbf{x}_j, \mathbf{x}_i)$. Pairings divide into two regimes: when $\mathbf{x}_i^\top \mathbf{B} \mathbf{x}_j > 0$, the gain is $(1 + \delta)$ (high-gain regime); when $\mathbf{x}_i^\top \mathbf{B} \mathbf{x}_j < 0$, the gain is $(1 - \delta)$ (low-gain regime). At $\delta = 0.5$, the high-gain interaction is three times the low-gain interaction.

The gain modulates the *strength* of the base interaction without changing its sign. Among pairings with similar base interactions $\mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j$, those in the high-gain regime are worth substantially more than those in the low-gain regime. This difference is the source of the broker's informational advantage (§1e).

#### 1d. What controls the nature of the matching problem

- **$s$ (active dimensions).** When $s = d$, the type curve spans all $d$ dimensions, creating maximum diversity in the type space and the interaction effects that depend on it. When $s < d$, the curve is confined to a lower-dimensional subspace.

- **$\rho$ (mixing weight).** At high $\rho$, general quality dominates. At low $\rho$, the gain-modulated interaction dominates.

- **$\delta$ (gain strength).** Controls the magnitude of the regime effect. At $\delta = 0$, the gain is 1 for all pairings and the DGP reduces to a simple interaction without regimes. At $\delta > 0$, the true interaction results from a mixture of two regimes. Larger $\delta$ produces a larger gap between high-gain and low-gain pairings, making the regime more consequential for match rankings.

- **$\mathbf{A}$ and $\mathbf{B}$ (interaction and regime matrices).** $\mathbf{A}$ determines the base interaction structure; $\mathbf{B}$ determines the regime boundary. Both are symmetric positive definite $d \times d$ matrices drawn independently at initialization. For a fixed agent $i$, the base interaction $\mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j = \mathbf{a}_i^\top \mathbf{x}_j$ (where $\mathbf{a}_i = \mathbf{A} \mathbf{x}_i$) is linear in $\mathbf{x}_j$. The regime boundary ($\mathbf{b}_i^\top \mathbf{x}_j = 0$, where $\mathbf{b}_i = \mathbf{B} \mathbf{x}_i$) is along a *different direction* than the interaction.

- **$\sigma_\varepsilon$ (noise scale).** The match-level noise $\sigma_\varepsilon = 0.10$ should be interpreted relative to the actual variance of $f$, which depends on the parameter configuration. The typical magnitude of dot products on the unit sphere in $\mathbb{R}^d$ is $O(1/\sqrt{d})$. The effective signal-to-noise ratio should be measured empirically at initialization.

#### 1e. The information gap between single- and cross-agent data

The regime-dependent gain (§1c) creates an informational gap between single-agent and cross-agent data. This gap has three important characteristics:

1. The gap is inherent to the DGP, not purely model-related.

2. The gap is fundamental, not merely statistical.

    - A purely statistical advantage depends asymptotically on data volume only and erodes as agents accumulate data. A fundamental gap involve an identification problem that single-agent data cannot solve regardless of sample size.

3. The gap affects match selection.

    - Agents use predictions to select a best counterparty ($\arg\max$).
    - The gap causes single- and cross-agent data to produce *different rankings* among top candidates, not just more accurate point estimates or better predictions for candidates that would never selected.

These characteristics correspond to assumptions being made through model design.

**Why the regime creates a fundamental information gap.** For a fixed agent $i$, the gain-modulated interaction produces outcomes from a *mixture* of two linear functions of $\mathbf{x}_j$. Some partners are in the high-gain regime ($g = 1 + \delta$) and others in the low-gain regime ($g = 1 - \delta$), but it is hard for agent $i$ to determine which regime each match fell into. The regime boundary (where $\mathbf{b}_i^\top \mathbf{x}_j = 0$, with $\mathbf{b}_i = \mathbf{B}^\top \mathbf{x}_i$) is along a direction in $\mathbf{x}_j$ space that the agent does not know. 

The agent data is generated by the mixture:

$$q_{ij} \approx \begin{cases} (1 + \delta) \cdot \mathbf{a}_i^\top \mathbf{x}_j & \text{if } \mathbf{b}_i^\top \mathbf{x}_j > 0 \\ (1 - \delta) \cdot \mathbf{a}_i^\top \mathbf{x}_j & \text{if } \mathbf{b}_i^\top \mathbf{x}_j < 0 \end{cases}$$

(omitting the quality component and noise for clarity). 

A linear model $\boldsymbol{\beta}^\top \mathbf{x}_j$ fitted on this mixture learns an *average slope* that is systematically wrong for both regimes. To separate the two regimes, the agent needs to detect that the slope of the relationship between $\mathbf{x}_j$ and outcomes changes along the direction $\mathbf{b}_i$. This is an unsupervised change-point detection problem in $d$ dimensions that requires qualitatively more sophisticated analysis than simple linear regression, regardless of sample size.

**Why the broker can resolve the regime.** The broker observes $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ triples across many different pairings. The regime depends on $\mathbf{x}_i^\top \mathbf{B} \mathbf{x}_j$, which is a *bilinear* function of both types. The broker's network, taking $[\mathbf{x}_i; \mathbf{x}_j]$ as input (§2c), can learn that certain combinations of $(\mathbf{x}_i, \mathbf{x}_j)$ systematically produce higher or lower match quality, capturing the regime effect through the nonlinear interactions learned by its hidden layer. The regime boundary that is hidden from the individual agent (because it requires conditioning on $\mathbf{x}_i$, which is fixed in single-agent data) is *visible* in the broker's input (because $\mathbf{x}_i$ varies across observations in cross-agent data).

**Why the gap affects match selection.** The gain operates multiplicatively on the base interaction. Among an agent's candidates with a high true interaction component, some are in the high-gain regime and others in the low-gain regime. The agent's linear model, fitting the average slope, ranks these candidates similarly. But their true match qualities differ by a factor of $(1 + \delta) / (1 - \delta)$ (3:1 at $\delta = 0.5$). The broker, knowing the regime, can identify which top candidates are high-gain and rank them above the low-gain candidates. This produces *different selections* from the same candidate pool.

### 2. Learning

Each period, agents and the broker **fit** prediction models on their accumulated histories to learn from past outcomes, then **use** those models to rank candidates and make decisions. Models are fitted once per period (§9, Step 2.1), then used repeatedly during candidate evaluation and match formation (§9, Steps 2.2–3).

#### 2a. Architecture and fitting

Both agents and the broker use the same architecture: a fully-connected network with one hidden layer, ReLU activations, and a single linear output:

$$\hat{q}(\mathbf{z}) = \mathbf{w}_2^\top \text{ReLU}(\mathbf{W}_1 \mathbf{z} + \mathbf{b}_1) + b_2$$

where $\mathbf{z}$ is the input feature vector, $\mathbf{W}_1$ is the hidden-layer weight matrix, $\mathbf{b}_1$ is the hidden bias vector, $\mathbf{w}_2$ is the output-layer weight vector, and $b_2$ is the output bias. Neither agents nor the broker use hand-crafted features; both receive raw type vectors as input and learn the relevant structure from data.

**Fitting.** Each period, the network weights are updated by minimizing MSE using vanilla gradient descent on the full batch with a fixed learning rate $\eta_{lr}$ (default 0.03). No explicit regularization is applied: at the data scales the broker and agents accumulate, adding weight decay has no measurable effect on held-out fit, so it is omitted for simplicity.

**Initialization.** At $t = 0$ each network is trained from random weights for $E_{\text{init}}$ gradient steps (default 200) on its seed history. The output bias $b_2$ is initialized to $Q$ (the DGP offset, §1a) rather than zero so that an untrained network predicts the population-mean match quality. This avoids a large negative-bias artifact for fresh entrants whose network has not yet been trained, and is irrelevant for mature networks (the first training steps on any real data move $b_2$ to its fitted value). All other weights follow He initialization.

**Adaptive schedule.** The network is updated each period with warm start from the previous period's weights. The number of gradient steps adapts to the ratio of new observations to total history:

$$E_t = \max\!\left(50, \; \left\lceil E_{\text{init}} \cdot \frac{n_{\text{new}}}{n_{\text{total}}} \right\rceil\right)$$

where $n_{\text{new}}$ is the number of observations added this period and $n_{\text{total}} = |\mathcal{H}^t|$ is the current history size. The floor of 50 ensures that mature networks continue to receive enough gradient updates per period to converge close to the DGP's best-achievable fit, rather than stagnating far below it.

**Training window.** To avoid diluting new observations in a large full-batch gradient, each training period uses at most the $W = 500$ most recent observations from the agent's or broker's history. The warm start preserves what was learned from older data. This sliding window ensures that the gradient reflects recent experience while being large enough, after symmetry augmentation for the broker, to contain a representative cross-section of match types.

**Prediction.** Given a fitted network, the prediction for a candidate match is a single forward pass. An agent evaluates $\hat{q}_i(\mathbf{x}_j)$ for each candidate partner $\mathbf{x}_j$ and selects the candidate with the highest predicted quality ($\arg\max$). Because $f$ is symmetric, the same model serves both roles: evaluating potential counterparties (as demander) and evaluating incoming proposals (as counterparty). The broker evaluates $\hat{q}_b([\mathbf{x}_i; \mathbf{x}_j])$ for all (demander, available roster member) pairs and allocates greedily (§5b).

#### 2b. Agent $i$'s model

**History.** $\mathcal{H}_i^t = \{(\mathbf{x}_j, q_{ij})\}_{m=1}^{n_i}$ records the other party's type and the realized match output from every match $i$ has participated in, regardless of role. Because $f$ is symmetric (§1a), observations from both roles pool into a single history.

**Input and capacity.** The agent's network takes the partner's type as input: $\mathbf{z} = \mathbf{x}_j$ ($d = 8$ inputs). The hidden layer has $h_a = 16$ units. Total parameters: $h_a \cdot (d + 1) + (h_a + 1) = 161$.

**Why this architecture.** The regime-dependent gain (§1c) makes the agent's local prediction problem *piecewise linear*: for a fixed agent $i$, the target function is $f_i(\mathbf{x}_j) \approx (1 \pm \delta) \cdot \mathbf{a}_i^\top \mathbf{x}_j + \text{quality}$, with two different slopes on either side of a hyperplane boundary $\mathbf{b}_i^\top \mathbf{x}_j = 0$ that the agent does not know. A one-hidden-layer ReLU network is the natural function approximator for this structure: each ReLU unit computes a hinge function $\max(\mathbf{w}^\top \mathbf{x}_j + b, 0)$, and a small number of such units can represent piecewise linear functions with learned breakpoints.

With sufficient data, the network can in principle learn the piecewise linear structure. The ReLU units can discover the regime boundary as one of their activation thresholds. In practice, with sparse data, the network produces a smooth approximation that averages across regimes. As the agent accumulates observations, the approximation improves, but the identification problem persists: detecting a change in slope along an unknown direction in $\mathbb{R}^d$ from noisy data requires substantially more observations than fitting a single linear relationship.

#### 2c. Broker's model

**History.** $\mathcal{H}_b^t = \{(\mathbf{x}_i, \mathbf{x}_j, q_{ij})\}_{m=1}^{n_b}$ records both parties' types and the realized match output from every match the broker has mediated. Seeded at initialization from random roster member pairs (§11c).

**Input and capacity.** The broker's network takes both parties' types as input: $\mathbf{z} = [\mathbf{x}_i; \mathbf{x}_j]$ ($2d = 16$ inputs). The hidden layer has $h_b = 32$ units. Total parameters: $h_b \cdot (2d + 1) + (h_b + 1) = 577$. No hand-crafted features (such as outer products) are provided.

**Fitting.** The network must discover the bilinear interaction structure $\mathbf{x}_i^\top \mathbf{A} \mathbf{x}_j$ and the regime boundary $\mathbf{x}_i^\top \mathbf{B} \mathbf{x}_j$ from the raw concatenated inputs. With 32 hidden ReLU units, the network has sufficient capacity to approximate these bilinear forms. Each unit computes a piecewise linear function of $[\mathbf{x}_i; \mathbf{x}_j]$ that can represent products of input components through interactions between units. 

To exploit the symmetry of $f$, the broker augments its training data by including both orderings of each observation: for each $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ in $\mathcal{H}_b$, the broker trains on both $[\mathbf{x}_i; \mathbf{x}_j]$ and $[\mathbf{x}_j; \mathbf{x}_i]$ with the same target $q_{ij}$. This doubles the effective training set and ensures the network learns that the two input slots are interchangeable.

**Data scope.** The broker learns only from matches it mediates. It does not observe outcomes of self-search matches. After a brokered match forms, the realized output $q_{ij}$ is observed by all parties involved (the two agents and the broker), and the broker adds $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$.

#### 2d. The asymmetry between agents and the broker

The broker's advantage has two components:

1. **More data.** The broker accumulates observations across all client agents, giving it far more training examples than any individual agent.

2. **Regime identification from cross-agent variation.** The regime-dependent gain (§1c) creates a mixture in each agent's data: some observations come from high-gain pairings and others from low-gain pairings. The broker, by observing the *same* partner types producing *different* outcomes with *different* agents, can detect the regime structure. The regime depends on the interaction between both parties' types ($\mathbf{x}_i^\top \mathbf{B} \mathbf{x}_j$), which is visible only when $\mathbf{x}_i$ varies across observations.

An agent learns "what kind of partner works well for me" from a small, agent-specific sample, but its model averages across regimes. The broker learns "what kind of pairings work well" from a large, cross-market sample where both parties' types vary. The broker's advantage is both informational (it can identify regimes that agents cannot) and statistical (it has more data).

### 3. Match Economics

Matches form when both parties expect positive gains from trade, following a heuristic version of the standard search-and-matching framework (Rogerson, Shimer & Wright, 2005).

#### 3a. Outside options

All agents share a common outside option $r$: the minimum per-period match value an agent requires to participate. Below this threshold, the agent prefers to remain unmatched. The outside option is calibrated at initialization:

$$r = 0.60 \cdot \bar{q}_{\text{pub}}$$

where $\bar{q}_{\text{pub}}$ is the mean match output computed from a Monte Carlo sample (§11c). The 0.60 calibration sets the outside option at 60% of average match value, producing a market where approximately 40% of match output is surplus available for gains from trade. A constant $r$ means the profitability comparison is the same for every counterparty.

#### 3b. Participation constraints

A match between demander $i$ and counterparty $j$ forms only if both parties predict positive gains:

- **Demander**: $\hat{q}_{i}(\mathbf{x}_j) > r$
- **Counterparty**: $\hat{q}_{j}(\mathbf{x}_i) > r$

When the broker proposes a match, it applies the constraint using its own prediction: $\hat{q}_b([\mathbf{x}_i; \mathbf{x}_j]) > r$. The counterparty still evaluates independently using its own model.

#### 3c. Search costs

Both search channels incur costs. The broker charges a fixed per-match fee $\phi$ for each match it mediates. Self-search incurs a cost $c_s = \gamma_c \cdot \phi$ per match, reflecting the effort of evaluating candidates, conducting due diligence, and negotiating. The ratio $\gamma_c \in [0, 1]$ (default 0.5) parameterizes the relative cost of self-search: at $\gamma_c = 0$, self-search is free and the broker must overcome the full fee through better match quality; at $\gamma_c = 1$, both channels have the same cost and compete purely on match quality.

Both costs are fixed per match and independent of match quality. The broker fee $\phi$ is calibrated at initialization (§11b).

### 4. Network Structure and Turnover

Agents interact through a single undirected network $G$ that determines each agent's search opportunities and structural position.

#### 4a. Network initialization

$G$ is initialized as a small-world graph (Watts & Strogatz, 1998). Agents are arranged on a ring in random order, each connected to its $k = 6$ nearest neighbors on the ring, and each edge is rewired with probability $p_{\text{rewire}} = 0.1$. This produces the high clustering and short path lengths characteristic of small-world graphs. Agents are placed on the ring in random order (rather than, e.g., sorted by type) so that the initial network is not type-assortative: neighbors at $t = 0$ are representative of the broader population, which avoids inflating baseline match quality through an artificially favorable neighborhood structure. An optional PC1-sorted variant is retained for robustness checks.

The broker is a permanent node in $G$, connected to all roster members (edges added as agents join the roster, §7). The broker node has no type vector and is excluded from matching candidate pools, but is included in network measure computations (§10).

#### 4b. Match tie formation

Each realized match (whether through self-search or brokered) adds an undirected edge between the demander and counterparty in $G$, if one does not already exist. Ties persist unless one of the nodes exits, as former counterparties remain connected after their match dissolves. This is the only mechanism of network densification.

#### 4c. Agent turnover

Agents exit independently each period with probability $\eta$ (default 0.02), yielding an expected agent lifetime of 50 quarters (12.5 years).

Exiting agents are replaced by entrants with fresh types sampled from the curve at a random position $t \sim U[0,1]$ plus noise (same procedure as initialization), empty experience histories, and satisfaction indices initialized at $\bar{q}_{\text{pub}}$. The exiting agent's node in $G$ is removed (along with all its edges). 

The entrant is added to $G$ with $\lfloor k/2 \rfloor$ edges to agents sampled from the type neighborhood (probability $\propto \exp(-\|\mathbf{x}_{i'} - \mathbf{x}_j\|^2)$). Entrants join with fewer connections than the initial network degree $k$ to reflect the disadvantage of being new to a market: established agents have accumulated connections through prior matches, while entrants start with only a few type-similar contacts. New entrants with sparse networks are more likely to need the broker's matching service.

### 5. Search

Each period, each of an agent's open capacity slots independently generates demand with probability $p_{\text{demand}}$ (default 0.50). An agent with $K - |M_i^t|$ open slots draws demand $d_i \sim \text{Binomial}(K - |M_i^t|, \; p_{\text{demand}})$ times. Each demand is resolved independently: the agent chooses self-search or broker (§6) and evaluates candidates separately for each slot. The same counterparty may be selected for multiple slots in the same period if it has the highest evaluated quality and both parties have remaining capacity.

#### 5a. Self-search

Agent $i$'s candidate pool has two components:

**Known neighbors.** Direct network neighbors in $G$ with available capacity ($K - |M_j^t| > 0$). The agent has matched with these agents before (every edge in $G$ comes from a prior match or from initialization). For each known neighbor $j$, the agent evaluates quality using the **average of realized outcomes** from prior matches with $j$: $\bar{q}_{ij} = \frac{1}{n_{ij}} \sum q_{ij}^{(m)}$, where $n_{ij}$ is the number of times $i$ and $j$ have matched. This is a direct empirical estimate, not a model prediction.

**Strangers.** $\min(n_s, |\text{eligible}|)$ agents sampled uniformly from the population (excluding current neighbors, current matches, and the broker node), where $n_s = 10$ (default) and eligible agents are those with available capacity. The agent has no prior history with these candidates and evaluates them using its **prediction model**: $\hat{q}_i(\mathbf{x}_j)$ (§2b). Strangers represent cold outreach: attending trade events, browsing listings, or following up on indirect referrals.

The agent selects the candidate with the highest evaluated quality (whether from history or prediction), provided the participation constraint is satisfied: the evaluation exceeds $r$ (§3b). If no candidate clears the threshold, no match is proposed and the no-match penalty applies (§6a).

The proposal enters the match formation step (§9, Step 3), where all proposals from both channels are processed sequentially in random order. The counterparty evaluates the proposal using its own model (for strangers) or historical average (for known neighbors), accepting if the evaluation exceeds $r$ (§3b) and it has not already been matched this period.

#### 5b. Broker-mediated search

When agent $i$ outsources to the broker, the broker includes agent $i$ in its allocation for the current period. Agent $i$ is also added to the broker's roster if not already a member (§7).

At the end of Step 1 (after all outsourcing decisions), the broker observes its full client list $D^t$ (the set of demanders who outsourced this period) and the available roster members $\text{Roster}^t \cap \{\text{agents with available capacity}\}$. The broker computes predicted match quality $\hat{q}_b([\mathbf{x}_i; \mathbf{x}_j])$ for every (demander, available roster member) pair and assigns matches using a greedy best-pair heuristic (§9, Step 2.3): iteratively select the highest-quality pair, propose that match, and remove both demander and counterparty from consideration. This continues until all demanders are matched, the roster is exhausted, or no remaining pair has positive predicted surplus ($\hat{q}_b > r$). The broker applies the same participation constraint as self-search: it does not propose matches with non-positive predicted surplus.

Proposals enter the match formation step (§9, Step 3) alongside self-search proposals. The counterparty evaluates using its own model (§3b).

Agents whose demand is not filled (because the roster was exhausted, no candidate cleared the surplus threshold, or the counterparty rejected) receive no proposal. The agent's broker satisfaction decays toward zero (§6a).

### 6. The Outsourcing Decision

A constant, scalar **public benchmark** $\bar{q}_{\text{pub}} = E[q]$ is computed once at initialization from a Monte Carlo sample of random agent pairs (§11c). This is the unconditional mean match output. The benchmark corresponds to a neutral outcome and initializes satisfaction indices (§6a) and broker reputation (§6c).

#### 6a. Satisfaction tracking

Each agent $i$ maintains a satisfaction index $s_{i,c}^t$ for each search channel $c \in \{\text{self}, \text{broker}\}$. These scores summarize past matching outcomes and drive the outsourcing decision.

The index is an exponentially weighted moving average (recency weight $\omega = 0.3$) of realized match value, net of search costs:

$$s_{i,c}^{t+1} = (1 - \omega)\,s_{i,c}^t + \omega \cdot \tilde{q}$$

where $\tilde{q}$ is the satisfaction input for the period. When an agent has multiple demand slots resolved through the same channel in one period, all realized outcomes are averaged into a single satisfaction input for that period:

| Channel | Satisfaction input $\tilde{q}$ |
|---------|-------------------------------|
| Self-search | $\frac{1}{n_{\text{matched}}} \sum (q_{ij} - c_s)$, averaged over matched slots |
| Standard brokered | $\frac{1}{n_{\text{matched}}} \sum (q_{ij} - \phi)$, averaged over matched slots |
| Principal mode (M1, §12) | $\frac{1}{n_{\text{matched}}} \sum q_{ij}$, averaged (no fee; broker is counterparty) |

If some slots matched and some failed in the same period, the satisfaction input reflects only the matched slots (partial success). If *all* slots through a channel failed (no match on any slot), the **no-match penalty** applies: the satisfaction index decays toward zero:

$$s_{i,c}^{t+1} = (1 - \omega)\, s_{i,c}^t$$

Satisfaction indices are not floored: they can go negative. The EWMA's recency weighting ensures recovery from negative values within a few good observations. New agents initialize all indices at the public benchmark $\bar{q}_{\text{pub}}$ (§6).

#### 6b. Decision rule

Each period, an agent with demand chooses between two search channels: self-search or the broker. The agent selects the channel with the higher satisfaction score. Ties are broken uniformly at random.

If the agent has not yet used the broker (its broker satisfaction has never been updated from a realized match or no-match penalty), it substitutes broker reputation for its broker satisfaction score. An agent that has outsourced at least once (even if only receiving a no-match penalty) uses its own broker satisfaction.

#### 6c. Broker reputation

$$\text{rep}_b^{t+1} = \begin{cases} \frac{1}{|D_b^t|} \sum_{i \in D_b^t} s_{i,b}^{t+1} & \text{if } D_b^t \neq \emptyset \\[4pt] \text{rep}_b^{t} & \text{otherwise} \end{cases}$$

where $D_b^t$ is the set of agents who outsourced to the broker this period. When the broker has current clients, reputation is updated to the mean of their (post-update) broker satisfaction. When it has no clients, the value is held from the previous period. Reputation is initialized at $\bar{q}_{\text{pub}}$ (§6).

### 7. Broker Roster

The broker maintains a **roster** of agents it knows and can propose as counterparties when mediating matches.

**Initialization.** The roster is seeded with $\lceil 0.20 \cdot N \rceil$ agents (default 200 at $N = 1000$) chosen uniformly at random from the population. This ensures the broker can serve early outsourcers without frequent no-match failures that would drive broker satisfaction down before the broker has a chance to demonstrate value. The broker's history is seeded with observations from random roster member pairs in $G$ (§11c).

**Growth.** Any agent who outsources to the broker in a given period is added to the roster permanently (if not already a member). The roster thus grows organically with broker usage.

**Availability.** A roster member is available as a counterparty in a given period if it has spare capacity ($|M_j^t| < K$). An agent may act as both a demander (seeking matches for its own slots) and a counterparty (being matched with other demanders) in the same period, provided it has capacity for both. Self-matches are excluded: the broker never matches an agent with itself.

There is no fixed roster size or target. The roster grows as the broker attracts clients, creating a network effect: a larger roster offers better matching options, which improves broker satisfaction, which attracts more outsourcing, which grows the roster further.

### 8. Match Lifecycle

Matches last $\tau$ periods (default $\tau = 1$). During the match, both parties observe the realized match output. After $\tau$ periods, the match dissolves and both parties regain one unit of capacity.

**At match formation:**
1. Realized output is drawn: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$.
2. Both parties add the observation to their histories: the demander adds $(\mathbf{x}_j, q_{ij})$ to $\mathcal{H}_{i}$; the counterparty adds $(\mathbf{x}_i, q_{ij})$ to $\mathcal{H}_{j}$.
3. If brokered, the broker adds $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$.
4. An edge is added between $i$ and $j$ in $G$ (if not already present).

**At match expiration** (after $\tau$ periods): the match is removed from both parties' active match lists $M_i^t$ and $M_j^t$. Both regain one unit of capacity.

At $\tau = 1$ (the default), matches are transactional: they form and dissolve within the same period. All $K$ slots are available at the start of each period, and the agent draws demand $\text{Binomial}(K, p_{\text{demand}})$ times. At $\tau > 1$, matches persist across periods and capacity becomes binding as agents accumulate active matches that have not yet expired.

### 9. Base Model Pseudocode

At the start of the simulation, the state of the world must be initialized.

> **INITIALIZE**
>
> *Agent types and matching function.*
> I.1. &emsp;Generate random frequencies $f_k$ and phases $\theta_k$ for the sinusoidal curve (§0).
> I.2. &emsp;Draw $N$ agent types: each at a random position $t_i \sim U[0,1]$ on the curve, perturbed by noise, and projected to the unit sphere.
> I.3. &emsp;Draw ideal type $\mathbf{c}$ (perturbation of a random curve position).
> I.4. &emsp;Draw SPD interaction matrix $\mathbf{A} = \mathbf{M}_A^\top \mathbf{M}_A \cdot (d / \text{tr}(\mathbf{M}_A^\top \mathbf{M}_A))$ and SPD regime matrix $\mathbf{B}$ (same construction), where $\mathbf{M}_A, \mathbf{M}_B \in \mathbb{R}^{d \times d}$ have iid $N(0,1)$ entries. Trace normalization ensures unit-scale bilinear forms. Drawn independently.
>
> *Calibration.*
> I.5. &emsp;Compute $\bar{q}_{\text{pub}} = E[q]$ from 10,000 random agent pairs. Set $r \leftarrow 0.60 \cdot \bar{q}_{\text{pub}}$.
> I.6. &emsp;Set broker fee $\phi$ (§11b).
>
> *Network.*
> I.7. &emsp;Build $G$: Watts–Strogatz with $N$ nodes, degree $k$, rewiring $p_{\text{rewire}}$. Node order is random (non-assortative initial network).
>
> *Broker.*
> I.8. &emsp;Seed broker roster with $\lceil 0.20 \cdot N \rceil$ randomly chosen agents. Add broker-agent edges to $G$ for each roster member.
> I.9. &emsp;Seed broker history $\mathcal{H}_b$ with 20 observations sampled from random roster member pairs in $G$ (realize match outputs and record).
>
> *State variables.*
> I.10. &emsp;For each agent $i$: seed $\mathcal{H}_{i}$ with 5 pairings sampled from $i$'s neighbors in $G$ (realize match outputs, record); $s_{i,\text{self}}^0 \leftarrow \bar{q}_{\text{pub}}$; $s_{i,\text{broker}}^0 \leftarrow \bar{q}_{\text{pub}}$; $M_i^0 \leftarrow \emptyset$.
> I.11. &emsp;$\text{rep}^0 \leftarrow \bar{q}_{\text{pub}}$; $\Pi_b \leftarrow 0$.
>
> *Initial model training.*
> I.12. &emsp;For each agent $i$: train neural network on $\mathcal{H}_i$ for $E_{\text{init}}$ GD steps from random weights (§2a).
> I.13. &emsp;Train broker's neural network on $\mathcal{H}_b$ (symmetry-augmented) for $E_{\text{init}}$ GD steps from random weights (§2c).

Each period proceeds through six steps (plus recording).

> **PERIOD $t$:**
>
> **0. MATCH EXPIRATIONS**
> 0.1. &emsp;For each active match that has lasted $\tau$ periods: remove from both parties' active match lists. Both regain one unit of capacity.
>
> **1. DEMAND GENERATION AND OUTSOURCING DECISIONS**
> 1.1. &emsp;For each agent $i$: draw demand count $d_i \sim \text{Binomial}(K - |M_i^t|, \; p_{\text{demand}})$.
> 1.2. &emsp;For each agent $i$ with $d_i > 0$:
> &emsp;&emsp;$\text{score}_{\text{self}} \leftarrow s_{i,\text{self}}^t$
> &emsp;&emsp;$\text{score}_{\text{broker}} \leftarrow s_{i,\text{broker}}^t$ &ensp;(use $\text{rep}^t$ if untried; §6b)
> &emsp;&emsp;$\text{decision}_i \leftarrow \arg\max(\text{score}_{\text{self}},\; \text{score}_{\text{broker}})$ &ensp;(applies to all $d_i$ slots; channel choice is per-agent)
> &emsp;&emsp;If $\text{decision}_i = \text{broker}$: add $i$ to broker roster (if not already present); add edge $(i, b)$ to $G$ if not already present (§4a)
> &emsp;Output: for each demander, channel choice and demand count $d_i$. Broker client list $D^t$ with per-agent demand counts.
>
> **2. CANDIDATE EVALUATION**
>
> &emsp;**2.1. Fit prediction models:**
> 2.1.1. &emsp;For each agent $i$: update neural network on $\mathcal{H}_{i}^t$ (§2b). Warm start; $E_t = \max(50, \lceil E_{\text{init}} \cdot n_{\text{new}} / n_i \rceil)$ GD steps on the sliding window of the most recent $W = 500$ observations. No regularization.
> 2.1.2. &emsp;Update broker's neural network on $\mathcal{H}_b^t$ with symmetry-augmented data (§2c). Same adaptive schedule and window. No regularization.
>
> &emsp;**2.2. Self-searches:**
> 2.2.1. &emsp;For each agent $i$ with $\text{decision}_i = \text{self}$:
> &emsp;&emsp;Build candidate pool (once per agent, shared across all $d_i$ slots):
> &emsp;&emsp;&emsp;**Known neighbors:** direct neighbors of $i$ in $G$ with available capacity. Evaluate each using average of realized outcomes: $\bar{q}_{ij}$.
> &emsp;&emsp;&emsp;**Strangers:** sample $\min(n_s, |\text{eligible}|)$ agents uniformly from non-neighbors with available capacity (excluding broker node). Evaluate each using prediction model: $\hat{q}_i(\mathbf{x}_j)$.
> &emsp;&emsp;For each of $i$'s $d_i$ demand slots: select $j^* = \arg\max$ over the candidate pool (ties broken randomly); if best evaluation $\leq r$, skip this slot; else record proposed match $(i, j^*)$. The same $j^*$ may be selected for multiple slots if it remains the best candidate.
>
> &emsp;**2.3. Broker proposals:**
> 2.3.1. &emsp;Collect client list: $D^t = \{i : \text{decision}_i = \text{broker}\}$.
> 2.3.2. &emsp;$\text{available\_roster} \leftarrow \text{Roster}^t \cap \{\text{agents with available capacity}\}$.
> 2.3.3. &emsp;Compute quality matrix: $\hat{Q}[i,j] = \hat{q}_b([\mathbf{x}_i; \mathbf{x}_j])$ for all $i \in D^t$, $j \in \text{available\_roster}$, $i \neq j$ (self-matches excluded).
> 2.3.4. &emsp;While $D^t$ non-empty AND available\_roster non-empty:
> &emsp;&emsp;$(i^*, j^*) = \arg\max \hat{Q}[i,j]$ &ensp;(ties broken uniformly at random)
> &emsp;&emsp;If $\hat{Q}[i^*, j^*] \leq r$: break (no remaining pair has positive surplus)
> &emsp;&emsp;Record proposed match $(i^*, j^*)$
> &emsp;&emsp;Decrement $i^*$'s demand count; if zero, remove $i^*$ from $D^t$. Decrement $j^*$'s available capacity; if zero, remove $j^*$ from available\_roster.
> 2.3.5. &emsp;If $D^t$ non-empty (roster exhausted or no surplus-positive pair): for each remaining $i \in D^t$, mark as no-proposal.
>
> **3. MATCH FORMATION**
>
> &emsp;**3.1. Sequential acceptance:**
> 3.1.1. &emsp;Shuffle all proposed matches (from both self-search and broker) into random order.
> 3.1.2. &emsp;For each proposed match $(i, j)$ in order:
> &emsp;&emsp;If demander $i$ has no available capacity: skip (capacity consumed by earlier accepted proposals, including proposals where $i$ was a counterparty).
> &emsp;&emsp;If counterparty $j$ has no available capacity: skip.
> &emsp;&emsp;Counterparty $j$ evaluates: $\bar{q}_{ji}$ (historical average) if $i$ is a neighbor of $j$, else $\hat{q}_{j}(\mathbf{x}_i)$ (prediction model).
> &emsp;&emsp;If evaluation $\leq r$: reject.
> &emsp;&emsp;Else: accept. Decrement both $i$'s and $j$'s available capacity by one.
>
> &emsp;**3.2. Finalization** (for each accepted match $(i, j)$):
> 3.2.1. &emsp;Realize output: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$.
> 3.2.2. &emsp;Add match to active match lists: append $j$ to $M_i^{t+1}$; append $i$ to $M_j^{t+1}$. (The same pair may appear multiple times if they have concurrent matches.)
> 3.2.3. &emsp;Add edge $(i, j)$ to $G$ if not already present.
> 3.2.4. &emsp;Record: channel (self/broker), $q_{ij}$, predictions used, whether $j$ was a direct neighbor of $i$ in $G$.
>
> **4. LEARNING AND STATE UPDATES**
> 4.1. &emsp;For each finalized match $(i, j)$:
> &emsp;&emsp;Add $(\mathbf{x}_j, q_{ij})$ to $\mathcal{H}_{i}$ (demander's history).
> &emsp;&emsp;Add $(\mathbf{x}_i, q_{ij})$ to $\mathcal{H}_{j}$ (counterparty's history).
> &emsp;&emsp;If brokered: add $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$; $\Pi_b \leftarrow \Pi_b + \phi$.
>
> 4.2. &emsp;Update satisfaction indices (§6a):
> &emsp;&emsp;For each agent $i$ with $d_i > 0$, let $c$ be $i$'s chosen channel:
> &emsp;&emsp;&emsp;Let $n_{\text{matched}}$ = number of $i$'s demand slots that resulted in an accepted match via $c$.
> &emsp;&emsp;&emsp;If $n_{\text{matched}} > 0$: compute $\tilde{q} = \frac{1}{n_{\text{matched}}} \sum (q_{ij} - \text{cost}_c)$, where $\text{cost}_c = c_s$ for self-search or $\phi$ for broker. Update: $s_{i,c}^{t+1} = (1 - \omega)\, s_{i,c}^t + \omega \cdot \tilde{q}$.
> &emsp;&emsp;&emsp;If $n_{\text{matched}} = 0$ (all slots failed): $s_{i,c}^{t+1} = (1 - \omega) \cdot s_{i,c}^t$ &ensp;(no-match penalty; §6a).
>
> 4.3. &emsp;Update broker reputation (§6c):
> &emsp;&emsp;If $|D^t| > 0$: $\text{rep}^{t+1} \leftarrow \text{mean of } s_{i,\text{broker}}^{t+1} \text{ over } i \in D^t$.
> &emsp;&emsp;Else: $\text{rep}^{t+1} \leftarrow \text{rep}^{t}$ (hold previous value).
>
> **5. ENTRY AND EXIT**
> 5.1. &emsp;For each agent $i$:
> &emsp;&emsp;With probability $\eta$: agent exits.
> &emsp;&emsp;&emsp;Remove $i$ from $G$ (node and all edges).
> &emsp;&emsp;&emsp;Terminate all active matches involving $i$; counterparties regain capacity.
> &emsp;&emsp;&emsp;Remove $i$ from broker roster (if present).
> &emsp;&emsp;&emsp;Replace with entrant $i'$: fresh type from curve + noise; empty histories; satisfaction at $\bar{q}_{\text{pub}}$; added to $G$ with $\lfloor k/2 \rfloor$ edges to agents sampled from the type neighborhood (probability $\propto \exp(-\|\mathbf{x}_{i'} - \mathbf{x}_j\|^2)$).
>
> **6. RECORDING AND MEASUREMENT**
> 6.1. &emsp;Record period aggregates: match quality by channel; outsourcing rate ($|D^t| / |\text{demanders}|$); roster size.
> 6.2. &emsp;Record broker state: cumulative revenue $\Pi_b$; reputation $\text{rep}^t$; roster size; $|\mathcal{H}_b^t|$.
> 6.3. &emsp;Every $M$ periods (default $M = 10$): compute network measures on $G$ (§10): betweenness centrality $C_B(b)$; Burt's constraint (broker's ego network); effective size (broker's ego network). Compute prediction quality ($R^2$, bias, rank correlation) for broker and agents (§10).

#### Parallelism summary

Steps 0 and 1 are embarrassingly parallel across agents. Step 2.2 (self-searches) is parallel across agents. Step 3 requires a conflict resolution pass but per-match computations are parallel. Steps 4–5 involve writes to shared state that require synchronization, but writes are non-overlapping (each match writes to distinct agent records). Network measures are the most expensive single computation; they read the full state but write nothing and can be offloaded to a separate thread or deferred to a coarser schedule.

### 10. Performance Measures

Computed on $G$ (which includes the broker as a permanent node; §4a) each measurement period. No agent uses these measures in its decisions; they are outputs for analysis.

#### Network measures

**Betweenness centrality.** Standard Freeman betweenness (Freeman, 1977) computed on $G$ using the Brandes (2001) algorithm adapted for single-node computation on undirected unweighted graphs. Neighbor iteration uses a compressed sparse row (CSR) adjacency structure built once per measurement call, with pre-allocated per-thread BFS workspaces for allocation-free parallel execution. The broker's betweenness is the fraction of all shortest paths that pass through the broker node, with the standard undirected normalization:

$$C_B(b) = \frac{1}{(n-1)(n-2)} \sum_{s \neq b} \sum_{t \neq s} \frac{\sigma_{st}(b)}{\sigma_{st}}$$

where $n = N+1$, $\sigma_{st}$ is the number of shortest paths from $s$ to $t$, and $\sigma_{st}(b)$ is the number passing through $b$. The double sum counts each undirected pair from both directions; dividing by $(n-1)(n-2)$ rather than $\binom{n}{2}$ corrects for this double-counting (Brandes, 2001, p. 9). As matches create direct ties, shortest paths increasingly bypass the broker, reducing betweenness: the structural erosion that the theory predicts.

**Burt's constraint.** Computed on the broker's ego network (Burt, 1992):

$$C_b = \sum_j \left(p_{bj} + \sum_{h \neq b,j}
p_{bh}\, p_{hj}\right)^2$$

where $p_{bj}$ is the proportion of the broker's ties invested in node $j$. Low constraint = broker spans structural holes. High constraint = broker's contacts are interconnected.

**Effective size.** The number of non-redundant contacts in the broker's ego network (Burt, 1992): $\text{ES}_b = |N(b)| - \sum_j p_{bj} \sum_{h \neq b} p_{bh}\, m_{jh}$ where $m_{jh} = 1$ if $j$ and $h$ are connected.

#### Prediction quality

**Winner's curse / selection bias.** Both agents and the broker select the counterparty with the highest *predicted* match quality from their candidate set ($\arg\max_j \hat{q}_{ij}$). When predictions are noisy, the selected counterparty's prediction $\hat{q}_{ij^*}$ is systematically inflated relative to the true match quality $f(\mathbf{x}_i, \mathbf{x}_{j^*})$, because the selection picks up positive noise realizations. This is the classic winner's curse.

**Holdout $R^2$ (model quality).** Each period, 100 random agent pairs are sampled and evaluated using noiseless true match quality $f(\mathbf{x}_i, \mathbf{x}_j)$ as the target. These pairs are *not* selected by any agent's model. Holdout $R^2$ measures pure model quality: how well the prediction model approximates the true matching function. It is the cleanest measure of informational advantage because it is uncontaminated by the winner's curse or by variation in candidate pool composition.

**Selected-sample metrics.** Three metrics are computed each period over all matches formed through each channel (self-search or brokered) that period:

- *Selected $R^2$* $= 1 - \text{MSE}/\text{Var}(q)$. Because matched counterparties are those with the highest predictions, this sample is subject to the winner's curse: predictions are systematically inflated relative to outcomes, depressing $R^2$.

- *Bias* $= \frac{1}{n}\sum(\hat{q} - q)$. Tracks systematic over- or underprediction. Positive bias is expected in the selected sample due to the winner's curse.

- *Selected rank correlation* (Spearman's $\rho_S$). Measures whether the agent ranks matched counterparties correctly by realized output. The rank correlation is less affected by the winner's curse than $R^2$ because it is invariant to monotone transformations.

**Minimum variance threshold for $R^2$.** When $\text{Var}(q) < \sigma_\varepsilon^2 / 6 \approx 0.01$, the realized output variance in the sample is too small relative to the noise floor for $R^2$ to be informative. Below this threshold, $R^2$ returns NaN.

**Summary of prediction quality metrics:**

| Metric | What it measures | Selection bias? | Primary use |
|--------|-----------------|-----------------|-------------|
| Holdout $R^2$ | Model quality (approximation of $f$) | None (random sample, noiseless truth) | Informational advantage |
| Selected rank correlation | Matching decision quality (correct ordering) | Mild (order is more robust than level) | Allocation effectiveness |
| Selected $R^2$ | Prediction accuracy on actual matches | Strong (winner's curse) | Economic outcomes |

The broker-agent gap in holdout $R^2$ is the purest measure of the informational advantage. The gap in selected rank correlation shows whether the advantage translates into better matching decisions.

#### Other measures

**Access vs. assessment decomposition.** For each brokered match, record whether counterparty $j$ was a direct neighbor of demander $i$ in $G$ at the time of the match. If not: access value (the demander could not have found this counterparty through its own network). If yes: assessment value (the demander could have found this counterparty but the broker predicted match quality better).

**Match quality by channel.** Average realized match output $\bar{q}_c^t$ per period, where $c \in \{\text{self}, \text{brokered}\}$.

**Outsourcing rate.** Fraction of demand that is outsourced to the broker: $|D^t| / |\text{demanders}^t|$.

**Roster size.** Number of agents in the broker's roster, tracking the growth of the broker's candidate network.

## Part II. Parameters, Calibration, and Initialization

### 11. Parameters

#### 11a. Parameter table

Parameters are organized into four categories reflecting their role in the analysis.

**Structural constants.** Define the model's mechanisms. Values are set by design rationale and not varied.

| Symbol | Meaning | Value | Notes |
|--------|---------|-------|-------|
| $d$ | Type dimensionality | 8 | Fixed |
| $k$ | Network mean degree | 6 | Watts-Strogatz ring lattice degree |
| $p_{\text{rewire}}$ | Network rewiring probability | 0.1 | Watts-Strogatz rewiring |
| $\omega$ | Satisfaction recency weight (§6a) | 0.3 | EWMA weight |
| $p_{\text{demand}}$ | Per-slot demand probability | 0.50 | Per open capacity slot; $d_i \sim \text{Binomial}(K - |M_i^t|, p_{\text{demand}})$ |
| $n_s$ | Max strangers in self-search | 10 | Sampled uniformly from non-neighbors with capacity |
| $\sigma_x$ | Type noise scale | 0.5 | Expected distance from agent to curve position |

**Calibration parameters.** Set during model development. Constant in production runs.

| Symbol | Meaning | Default | Notes |
|--------|---------|---------|-------|
| $r$ | Outside option | $0.60 \cdot \bar{q}_{\text{pub}}$ | Constant for all agents; calibrated at initialization |
| $\eta_{lr}$ | Learning rate | 0.03 | Vanilla gradient descent, full-batch, no weight decay |
| $E_{\text{init}}$ | Initial training steps | 200 | Full convergence at initialization; per-period steps adapt as $\max(50, \lceil E_{\text{init}} \cdot n_{\text{new}} / n_{\text{total}} \rceil)$ |
| $W$ | Training window | 500 | Train on at most $W$ most recent observations (sliding window) |
| $h_a$ | Agent hidden width | 16 | One hidden layer, ReLU activations |
| $h_b$ | Broker hidden width | 32 | One hidden layer, ReLU activations |
| $b_2^{(0)}$ | Initial output bias | $Q$ | Untrained networks predict population-mean quality rather than zero |
| $\sigma_\varepsilon$ | Match output noise SD | 0.10 | |
| $\delta$ | Regime gain strength (§1c) | 0.5 | $\delta = 0$: no regime effect; $\delta = 1$: maximum gain contrast |
| $\alpha_\phi$ | Broker fee rate | 0.20 | $\phi = \alpha_\phi \cdot (\bar{q}_{\text{pub}} - r)$; §11b |
| $\gamma_c$ | Self-search cost ratio | 0.5 | $c_s = \gamma_c \cdot \phi$; self-search cost as a fraction of broker fee |

**Phase diagram axes.** Primary parameters of interest.

| Symbol | Meaning | Default | Sweep |
|--------|---------|---------|-------|
| $s$ | Active dimensions | 8 | {2, 4, 6, 8} |
| $\rho$ | Quality-interaction mixing weight | 0.50 | {0, 0.10, 0.30, 0.50, 0.70, 0.90, 1.0} |

**Model 1 parameters.** Apply only under resource capture (§12).

| Symbol | Meaning | Default | Notes |
|--------|---------|---------|-------|

**OAT sensitivity parameters.** Varied one at a time while holding all others at defaults.

| Symbol | Meaning | Default | Sweep | Notes |
|--------|---------|---------|-------|-------|
| $\tau$ | Match duration (periods) | 1 | {1, 2, 4, 8} | Transactional at $\tau = 1$; relational at $\tau > 1$ |
| $K$ | Match capacity | 5 | {1, 2, 5, 10, 20, 50} | Exclusive at $K = 1$; concurrent at $K > 1$ |
| $\eta$ | Agent entry/exit rate | 0.02 | {0.01, 0.02, 0.05, 0.10} | |
| $\delta$ | Regime gain strength | 0.5 | {0, 0.25, 0.50, 0.75} | $\delta = 0$: no regime effect (pure statistical advantage) |

The match lifecycle parameters $\tau$ and $K$ jointly determine the market regime. Because demand is per-slot, the effective activity rate scales with $K \cdot p_{\text{demand}}$: high-capacity agents generate more demands per period, reflecting their higher throughput. Different combinations map to the illustrative domains:

| Domain | $\tau$ | $K$ | Rationale |
|--------|--------|-----|-----------|
| Interdealer brokerage | 1 | 10–50 | Transactional; many concurrent positions |
| Collector networks | 1 | 2–5 | Discrete transactions; moderate concurrency |
| Import-export trading | 2–4 | 2–5 | Shipments span multiple periods; moderate concurrency |

**Implementation parameters.** Control simulation scale.

| Symbol | Meaning | Default | Scale check |
|--------|---------|---------|-------------|
| $N$ | Agent population | 1000 | {500, 1000, 2000} |
| $T$ | Simulation length (periods) | 200 | {100, 200, 400} |
| $T_{\text{burn}}$ | Burn-in periods (discarded) | 30 | — |
| $M$ | Network measure interval | 10 | — |

#### 11b. Broker fee calibration

The broker fee $\phi$ is set to a fraction of the average match surplus: $\phi = \alpha_\phi \cdot (\bar{q}_{\text{pub}} - r)$, where $\alpha_\phi = 0.20$ (default). This ensures the fee is economically meaningful (large enough that outsourcing is a real cost) but not prohibitive (small enough that better match quality can justify the expense). The fee is computed once at initialization and held constant.

#### 11c. Initial conditions

The initialization procedure is specified in the pseudocode (§9, steps I.1–I.13). The key design choices are:

- Agent types are drawn at random positions on the sinusoidal curve with noise, then projected to the unit sphere (§0).
- The matching function parameters ($\mathbf{c}$, $\mathbf{A}$, $\mathbf{B}$) are drawn once and held fixed (§1).
- Calibration quantities ($\bar{q}_{\text{pub}}$, $r$, $\phi$) are computed from 10,000 random agent pairs (§11b).
- Each agent's history is seeded with 5 pairings from its neighbors in $G$, ensuring initial predictions reflect the local network.
- The broker's roster is seeded at $\lceil 0.20 \cdot N \rceil$ agents, and its history is seeded from 20 random roster member pairs.
- All neural networks are trained from random weights for $E_{\text{init}}$ steps on their seed histories before the first period (§2a).

#### 11d. Reproducibility

All randomness flows from a single integer seed. The seed determines: type draws, the realization of $G$, matching function parameters ($\mathbf{c}$, $\mathbf{A}$, $\mathbf{B}$), broker seed roster, and all subsequent random events. Simulations are fully reproducible given (parameter dictionary, seed).

## Part III. Model Variant: Resource Capture

All base model mechanisms (§§0–10) operate unchanged. The difference: the broker can additionally act as a **principal**, acquiring a counterparty's position or resource and presenting itself as the counterparty to the demander. Rather than connecting two agents, the broker takes one side of the match. This implements the resource capture mode of Proposition 3a.

### 12. Resource Capture

#### 12a. Setup

Under resource capture, the broker transitions from intermediary to principal. Instead of connecting a demander with a counterparty, the broker acquires the counterparty's position (paying the counterparty for its resource or service) and then matches directly with the demander. The demander deals with the broker, not with the original counterparty. The broker earns the spread between what it charges the demander and what it pays the counterparty, bearing inventory risk if the match output falls short.

**Agent state additions.** Matches gain a flag: *standard* (brokerage as in the base model) or *principal* (broker takes one side). No new agent-level state variables are needed.

#### 12b. Mechanism

When the broker operates in principal mode for demander $i$:

1. The broker identifies the best counterparty $j$ using its model (same allocation as the base model, §9 Step 2.3).
2. **The broker acquires $j$'s position** at a price equal to $j$'s average realized match quality $\bar{q}_j$ (the mean of all outputs in $j$'s history, or $\bar{q}_{\text{pub}}$ if $j$ has no history). This is the counterparty's self-assessed value of its position based on its own experience. Agent $j$'s capacity slot is consumed for the period, but $j$ does not learn who the position is destined for.
3. **The broker matches with demander $i$** as the counterparty, stepping into $j$'s role. Match output is realized: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$, determined by the underlying pairing $(i, j)$ even though $i$ deals only with the broker.
4. **Both the demander and the broker experience $q_{ij}$** (the joint match value, as in any match). The broker's profit is $q_{ij} - \bar{q}_j$ (match value minus acquisition cost). This can be negative when the position underperforms the price paid, which is the broker's inventory risk.
5. **Neither party observes the other's type.** The demander observes $q_{ij}$ (it experiences the match outcome) but not $\mathbf{x}_j$ (it does not know whose position the broker acquired). The counterparty does not observe $\mathbf{x}_i$ or $q_{ij}$ (it sold its position without knowing the end use). Neither party can update its prediction history, because histories require (type, outcome) pairs (§2a).
6. **No edge is added to $G$ between $i$ and $j$.** The parties are unaware of each other's existence. The structural hole between them remains open.
7. **The broker adds $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$.** The broker is the only agent that learns from principal-mode matches.

The counterparty accepts when the broker offers at least $\bar{q}_j$. Since the broker always offers exactly $\bar{q}_j$, acceptance is automatic. The counterparty bears no risk: it receives a price consistent with its own experience. The broker absorbs the inventory risk: it paid $\bar{q}_j$ for a position that may generate more or less than that amount. This risk-bearing is a defining property of capture.

As the market evolves and counterparties accumulate better match histories (including from broker-mediated matches), their ask prices $\bar{q}_j$ rise, naturally constraining the broker's margin. The broker can only profitably acquire positions from counterparties whose self-assessed value is substantially below the broker's predicted match value for the specific pairing.

If the broker repeatedly acquires positions from the same high-value agents, those agents are effectively monopolized, available to the market only through the broker. Self-searchers are left with a thinner, lower-quality pool.

#### 12c. Broker's decision: standard vs. principal

Each time the broker fills a match for demander $i$ with counterparty $j$, it compares expected profit from standard placement against principal mode:

$$\Pi^{\text{standard}} = \phi$$

$$\Pi^{\text{principal}} = \hat{q}_b([\mathbf{x}_i; \mathbf{x}_j]) - \bar{q}_j$$

where $\phi$ is the placement fee (§3c), $\hat{q}_b$ is the broker's predicted match quality, and $\bar{q}_j$ is agent $j$'s average realized match quality (the acquisition cost). Under standard placement, the broker earns the intermediation fee. In principal mode, the broker steps into the counterparty's role and earns the spread between the match value and the acquisition cost. No additional fee is charged to the demander, because the broker is no longer intermediating but acting as a principal.

The broker chooses principal mode when $\hat{q}_b - \bar{q}_j > \phi$. Early in the simulation, the broker's predictions are inaccurate and the expected spread is uncertain. As predictions improve, the broker reliably identifies pairings where $\hat{q}_b$ substantially exceeds $\bar{q}_j$, making principal mode increasingly profitable.

The capture dynamic relies on informational dependency and supply scarcity rather than long-duration lock-in (see §12e for the full feedback mechanism).

#### 12d. Principal-mode economics

In principal mode, the broker acts as the counterparty. There is no intermediation fee: the broker's compensation is its share of the match output, just as the original counterparty would have received.

**Demander's perspective.** The demander experiences $q_{ij}$ and pays nothing to the broker (no fee, since the broker is the counterparty, not an intermediary). The demander's satisfaction input is $q_{\text{realized}}$, the same as an unmediated match. This is better for the demander than standard brokered matches (where the fee $\phi$ is deducted) or self-search (where $c_s$ is deducted), which reinforces the capture dynamic: demanders prefer principal-mode matches.

**Broker's perspective.** The broker paid $\bar{q}_j$ to acquire the position and experiences $q_{ij}$ from the match. The broker's profit is $q_{ij} - \bar{q}_j$. When the broker's predictions are accurate, it selects high-value pairings where $q_{ij} \gg \bar{q}_j$, earning a positive spread. When predictions are poor, $q_{ij} < \bar{q}_j$ and the broker takes a loss (inventory risk).

**Counterparty's perspective.** The counterparty received $\bar{q}_j$, its average realized match quality from past experience. It cannot evaluate the specific match (it doesn't know the demander's identity). Its ask price rises over time as it accumulates better match outcomes, naturally constraining the broker's margin.

The demander cannot update its prediction model (it observes $q_{ij}$ but lacks the counterparty type $\mathbf{x}_j$ needed for a history entry). The informational lock-in is preserved even though the demander experiences the match outcome.

#### 12e. Lock-in dynamics

Resource capture produces a **triple lock-in**:

**Informational lock-in.** Neither party observes the other's type. Prediction histories do not grow. The agent's neural network cannot be refitted on new data. Prediction quality stagnates at whatever level it had reached before entering principal-mode matching.

**Structural lock-in.** No direct tie forms between $i$ and $j$ in $G$. The network does not densify from principal-mode matches. Structural holes between agents remain open. The broker's betweenness centrality does not decline from these matches.

**Supply-side lock-in.** Agents whose positions are repeatedly acquired by the broker are effectively removed from the open market during those periods. Self-searchers face a thinner candidate pool, degrading the quality of self-search outcomes and pushing more agents toward the broker. This supply scarcity reinforces the information lock-in.

**Positive feedback loop.** Principal-mode matching prevents agent learning and thins the open market → agent's self-search quality stagnates or declines → agent's self-search satisfaction falls below broker satisfaction → agent continues outsourcing → broker earns the spread on each principal-mode match, continues learning, and acquires more positions → broker's predictions improve and its inventory expands → more matches are profitable in principal mode → more agents locked in, more positions acquired.

This feedback loop is self-reinforcing once initiated, producing the abrupt capture trajectory predicted by Proposition 3a. The self-liquidating dynamic of structural advantage is suspended: because principal-mode matches create no direct ties between agents, the broker's structural position stops eroding.

#### 12f. Illustrative domains

Under resource capture, the broker transitions from connecting agents to taking one side of the match: acquiring a counterparty's position or resource and reselling it, with the broker bearing inventory risk.

**Interdealer brokerage.** The broker transitions from voice intermediation to principal trading. Instead of finding a counterparty for a dealer's trade, the broker takes the other side itself, buying a position from one dealer and selling it to another. The broker warehouses the position and earns the bid-ask spread. Neither dealer knows who is on the other side; both deal with the broker. This is the well-documented transition of IDBs to principal-trading platforms.

**Collector networks.** The dealer transitions from pure intermediation to holding inventory. Instead of connecting a seller with a buyer, the dealer buys the piece outright (acquiring the seller's holding) and later sells it to a buyer. The dealer bears the risk that the piece may not find a suitable buyer at a profitable price. This is the standard transition from consignment dealer to gallery or wine merchant.

**Import-export trading companies.** The trading company transitions from pure intermediation to taking principal positions. Instead of connecting a producer with a buyer, the company buys goods from the producer (acquiring the supply position) and resells to the buyer. The company bears inventory and price risk: the goods may not find a buyer at a profitable price, or market conditions may shift between acquisition and resale. This is the canonical trajectory of trading houses that evolve from brokers to merchants to vertically integrated conglomerates.

#### 12g. Channel comparison

| | Base (no capture) | Resource capture (principal) | Data capture (§13a) |
|---|---|---|---|
| Who matches? | Agent matches directly | Broker takes one side | Agent matches directly |
| Agent observes counterparty type? | Yes | No (deals with broker) | Yes |
| Agent's prediction model improves? | Yes | No | Yes |
| Whose predictions guide selection? | Agent's own | Broker's | Broker's (sold to agent) |
| Direct tie forms? | Yes | No | Yes |
| Structural erosion? | Continues | Suspended | Continues |
| Supply scarcity? | No | Yes (broker acquires positions) | No |
| Broker bears inventory risk? | No | Yes | No |
| Broker revenue | Per-match fee $\phi$ | Spread: $q_{ij} - \bar{q}_j$ | Per-period subscription $\mu$ |
| Broker learns from match? | Yes | Yes | No (agent matched directly) |
| Predicted trajectory | Self-liquidating | Abrupt capture (Prop 3a) | Gradual capture (Prop 3b) |

The two capture modes differ on every dimension. Under resource capture, the broker becomes a principal, acquiring positions, bearing risk, and preventing clients from learning or forming direct ties. Under data capture, the broker *sells* its informational advantage, licensing predictions while clients continue matching directly, learning, and forming ties. These are two ways of monetizing the same informational asset: by exploiting it privately or by licensing it.

A subtle asymmetry in learning dynamics: under resource capture, the broker keeps learning (it observes both types in every principal-mode match). Under data capture, the broker's learning *slows* because agents match directly and the broker does not observe those outcomes unless a reporting mechanism exists. This creates a natural ceiling on data capture that resource capture does not face, and may contribute to the gradual-vs-abrupt distinction.

#### 12h. Pseudocode modifications

Steps not listed are identical to the base model pseudocode (§9).

<small>

> **2. CANDIDATE EVALUATION** (principal-mode branch added)
>
> &emsp;**2.3. Broker proposals** (unchanged from base):
> 2.3.1–2.3.5: as in §9.
>
> &emsp;**2.4. Broker mode selection** (new):
> 2.4.1. &emsp;for each proposed brokered match $(i, j)$:
> &emsp;&emsp;Compute $\Pi^{\text{standard}} = \phi$
> &emsp;&emsp;Compute acquisition cost: $\bar{q}_j$ = mean of agent $j$'s realized match history (or $\bar{q}_{\text{pub}}$ if empty)
> &emsp;&emsp;Compute $\Pi^{\text{principal}} = \hat{q}_b([\mathbf{x}_i; \mathbf{x}_j]) - \bar{q}_j$
> &emsp;&emsp;If $\Pi^{\text{principal}} > \Pi^{\text{standard}}$: mark match as principal
> &emsp;&emsp;Else: mark match as standard
>
> **3. MATCH FORMATION** (principal-mode branch added)
>
> &emsp;**3.1. Sequential acceptance** (as in base, §9 Step 3, with principal-mode additions):
> 3.1.1. &emsp;Shuffle all proposals (standard and principal-mode) into random order.
> 3.1.2. &emsp;For each proposed match $(i, j)$ in order:
> &emsp;&emsp;If demander $i$ has no available capacity: skip.
> &emsp;&emsp;If counterparty $j$ has no available capacity: skip.
> &emsp;&emsp;**If standard:** counterparty $j$ evaluates as in base (§9 Step 3.1.2).
> &emsp;&emsp;**If principal mode:** broker acquires $j$'s position at price $\bar{q}_j$ (automatic acceptance). Demander's participation constraint was applied by the broker during allocation ($\hat{q}_b > r$, §9 Step 2.3.4).
> &emsp;&emsp;If accepted: decrement both $i$'s and $j$'s available capacity by one.

> **4. OUTCOME REALIZATION AND LEARNING** (principal-mode branch added)
>
> 4.1. &emsp;for each accepted match $(i, j)$:
> &emsp;&emsp;Realize output: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$
> &emsp;&emsp;**If standard** (self-search or standard brokered):
> &emsp;&emsp;&emsp;Add $(\mathbf{x}_j, q_{ij})$ to $\mathcal{H}_i$ (demander's history)
> &emsp;&emsp;&emsp;Add $(\mathbf{x}_i, q_{ij})$ to $\mathcal{H}_j$ (counterparty's history)
> &emsp;&emsp;&emsp;If brokered: add $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$
> &emsp;&emsp;&emsp;Add edge $(i, j)$ to $G$
> &emsp;&emsp;**If principal mode:**
> &emsp;&emsp;&emsp;Agent histories $\mathcal{H}_i$ and $\mathcal{H}_j$ are **not** updated (neither party observes the other's type; demander dealt with broker, counterparty sold position to broker)
> &emsp;&emsp;&emsp;Add $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$ (broker observes both types)
> &emsp;&emsp;&emsp;**No edge** added to $G$ between $i$ and $j$
>
> 4.2. &emsp;Update satisfaction indices (as in base §9 Step 4.2, with principal-mode addition):
> &emsp;&emsp;For each agent $i$ with $d_i > 0$, let $c$ be $i$'s chosen channel:
> &emsp;&emsp;&emsp;Let $n_{\text{matched}}$ = number of $i$'s demand slots that resulted in an accepted match via $c$.
> &emsp;&emsp;&emsp;If $n_{\text{matched}} > 0$: compute $\tilde{q} = \frac{1}{n_{\text{matched}}} \sum (q_{ij} - \text{cost}_c)$, where $\text{cost}_c = c_s$ for self-search, $\phi$ for standard brokered, or $0$ for principal mode (no fee; broker is counterparty). Update: $s_{i,c}^{t+1} = (1 - \omega)\, s_{i,c}^t + \omega \cdot \tilde{q}$.
> &emsp;&emsp;&emsp;If $n_{\text{matched}} = 0$: no-match penalty (§6a).
>
> 4.3. &emsp;Broker accounting (principal-mode matches):
> &emsp;&emsp;for each accepted principal-mode match $(i, j)$:
> &emsp;&emsp;&emsp;Broker revenue: $q_{ij}$ (broker's share of match output as counterparty)
> &emsp;&emsp;&emsp;Broker cost: $\bar{q}_j$ (acquisition price paid to original counterparty)
> &emsp;&emsp;&emsp;Broker profit: $q_{ij} - \bar{q}_j$

</small>

#### 12i. Model 1 performance measures

**Principal-mode share** $P^t$: the fraction of brokered matches in period $t$ that are principal-mode (versus standard placement). This is the primary capture metric. Proposition 3a predicts an abrupt tipping point: $P^t$ should remain near zero while the broker builds its informational advantage, then jump sharply to near one as principal mode becomes economically dominant.

**Agent prediction quality by principal-mode exposure.** Average holdout $R^2$ stratified by agents' cumulative principal-mode match fraction. Agents with high exposure should show stagnating prediction quality (informational lock-in), while agents who primarily self-search or receive standard placements should continue improving.

**Broker inventory risk.** The frequency and magnitude of matches where $q_{ij} < r$ (the broker's acquired position underperforms the price paid). Early in the capture transition, when predictions are less accurate, losses should be more frequent. As predictions improve, losses should decline. Persistent losses would indicate that the broker is transitioning to principal mode too early.

**Supply scarcity.** The fraction of agents whose positions are acquired by the broker in each period, and the resulting impact on self-search candidate pool sizes. Under capture, self-searchers face a shrinking pool of available counterparties.

**Broker dependency.** For each agent $j$, the broker dependency ratio $D_j^t$ is the fraction of $j$'s recent matches (cumulative or over a rolling window) in which the broker acquired $j$'s position. At $D_j = 0$, the agent participates only in direct matches; at $D_j = 1$, the agent's position is always acquired by the broker. The distribution of $D_j$ across agents characterizes the extent and concentration of position monopolization. Summary statistics include: mean $D_j$ (overall dependency level), the fraction of agents with $D_j > 0.5$ (number of effectively monopolized agents), and the Gini coefficient of $D_j$ (whether the broker concentrates acquisitions on a few agents or spreads them broadly).

---

## Part IV. Outstanding Design Choices

### 13. Deferred Design Choices

The following design choices are deferred for future work. They are described at a conceptual level to guide subsequent development.

#### 13a. Data Capture (Model 2)

Under data capture (Proposition 3b), the broker sells access to its prediction model as a per-period subscription service. Subscribing agents use the broker's model when evaluating strangers during self-search (§5a), while continuing to match directly, learn from outcomes, and form ties. For known neighbors, subscribers still use their own historical averages. The broker earns per-period subscription revenue $\mu$ rather than per-match fees.

Data capture produces the gradual trajectory of Proposition 3b: agents keep learning and forming ties, structural erosion continues, and the broker's advantage narrows as subscribers improve their own predictions. The channel comparison table in §12g summarizes the contrast with resource capture.

**Open design questions:**

**Does the broker observe outcomes of subscriber-directed matches?** If not, the broker's learning slows under data capture: subscribers use the broker's model to find better matches with strangers, but the broker doesn't see the outcomes. This creates a natural ceiling on the broker's model quality. If the broker does observe outcomes (e.g., through a reporting requirement in the subscription contract), the ceiling disappears and data capture dynamics change.

**Does subscription replace or supplement the agent's own model for stranger evaluation?** If the subscription replaces the agent's neural network entirely (the agent uses the broker's predictions for all strangers), the agent becomes dependent and its own model atrophies. If the subscription supplements (e.g., the agent uses the better of its own prediction and the broker's for each stranger), the agent's model continues to improve alongside the broker's. The replacement version is simpler and produces stronger capture dynamics; the supplement version is more realistic.

**Can subscribers also use the broker for standard placement simultaneously?** If yes, the broker can earn revenue from both subscription fees and placement fees, and subscribers benefit from both better predictions and access to the broker's roster. If no, subscription and brokerage are mutually exclusive channels.

#### 13b. Alternative Resource Capture Mechanisms

Two alternatives to the principal-mode mechanism (§12) are noted for future exploration.

**Exclusive contracts without information lock-in.**

Agents sign exclusive contracts with the broker for $L$ periods but still observe counterparty types and form direct ties. Lock-in is contractual, not informational: the agent's prediction model and network continue to improve, but it cannot switch to self-search during the contract.

This variant serves as a **comparison case**: if capture is weaker without information lock-in, it demonstrates that the informational channel (not the contractual restriction) drives the abrupt capture dynamics of Proposition 3a.

**Partial obfuscation.**

The broker reveals noisy or partial type information: $\tilde{\mathbf{x}}_j = \mathbf{x}_j + \boldsymbol{\zeta}$, where $\boldsymbol{\zeta} \sim N(0, \sigma_{\text{obf}}^2 \mathbf{I}_d)$. The agent can update its history with $(\tilde{\mathbf{x}}_j, q_{ij})$, but the noisy type degrades the quality of its learned model. At $\sigma_{\text{obf}} = 0$, this is standard brokerage; at $\sigma_{\text{obf}} \to \infty$, this approaches the full information lock-in of principal mode.

This variant provides a continuous lock-in parameter that can be swept, serving as a **robustness check**: does the capture result survive when the information freeze is partial rather than total? The theoretical prediction is that capture requires sufficiently strong obfuscation but is not knife-edge: there should be a threshold $\sigma_{\text{obf}}^*$ above which capture dynamics emerge.

#### 13c. Prediction Confidence and Uncertainty

The current model does not track prediction confidence. All predictions are point estimates; the broker's principal-mode decision is purely economic (§12c) with no risk adjustment for prediction uncertainty.

**Bayesian last layer.** A natural extension of the current neural network architecture (§2a): the hidden layer remains a deterministic feature extractor trained by gradient descent, but the output layer is replaced with Bayesian linear regression. Given hidden features $\mathbf{h} = \text{ReLU}(\mathbf{W}_1 \mathbf{z} + \mathbf{b}_1)$ from the training data, the posterior over output weights $\mathbf{w}_2$ is available in closed form (conjugate Gaussian). For a new input $\mathbf{z}^*$, the predictive distribution is $N(\boldsymbol{\mu}_{\text{post}}^\top \mathbf{h}^*, \; \sigma_\varepsilon^2 + \mathbf{h}^{*\top} \boldsymbol{\Sigma}_{\text{post}} \mathbf{h}^*)$, where the second variance term $\mathbf{h}^{*\top} \boldsymbol{\Sigma}_{\text{post}} \mathbf{h}^*$ is the *epistemic* uncertainty (large when the input is far from training data in feature space, small when it is well-covered). Implementation cost is minimal: one $h \times h$ matrix inversion per agent per period (at $h = 16$, this is trivial).

**Uses of per-prediction uncertainty:**
- *Match selection.* An upper confidence bound (UCB) rule (select the partner with the highest $\hat{q} + \kappa \cdot \hat{\sigma}$) would balance exploitation (high predicted quality) with exploration (high uncertainty), generating more informative data and accelerating learning.
- *Principal-mode decision.* The broker could adjust expected profit by prediction uncertainty, avoiding principal positions where $q_{ij}$ is highly uncertain and inventory risk is greatest.
- *Outsourcing decision.* An agent whose average predictive uncertainty is high might rationally prefer the broker even when satisfaction scores are comparable.
- *Measuring the informational advantage.* The epistemic uncertainty gap between agent and broker (the broker's $\Sigma_{\text{post}}$ is smaller because it has more diverse training data) directly quantifies the informational advantage at the prediction level.

Deferred because the base model's point-estimate predictions are sufficient to demonstrate the core propositions. The Bayesian last layer would enrich the dynamics (especially the capture transition, where the broker's confidence determines when it begins taking principal risk) and could be added without changing the hidden-layer training procedure.

#### 13d. Pricing Alternatives

The base model uses a fixed per-match fee $\phi$. Under Model 1 (principal mode), the broker's compensation is the spread $q_{ij} - \bar{q}_j$ with no additional fee. Two alternative pricing mechanisms are noted for future exploration.

**Surplus-proportional fee.** $\phi = \alpha \cdot \hat{q}_b([\mathbf{x}_i; \mathbf{x}_j])$. The broker charges a fraction of its predicted match quality. This creates a recognition gap: the broker's revenue depends on its own prediction, while the agent's satisfaction depends on realized quality. Better predictions increase broker revenue, strengthening the incentive to invest in prediction accuracy.

**Prediction-based fee.** $\phi = \alpha \cdot (\hat{q}_b - \hat{q}_i)$. The broker charges for the prediction improvement it provides over the agent's own model. This directly prices the informational advantage but requires the broker to know (or estimate) the agent's prediction quality.

Both alternatives create richer dynamics but add parameters and complicate the satisfaction comparison between channels. The fixed-fee design isolates the informational channel by removing price as a margin of competition.

#### 13e. Other Design Choices

**Roster decay.** Inactive roster members (agents who have not outsourced in the last $L$ periods) could be pruned from the roster. This would prevent the roster from growing indefinitely and create a more realistic model of broker-client relationships. The tradeoff is additional complexity and a new parameter $L$.

**Fixed acquisition price at outside option.** The current model sets the counterparty's ask price at $\bar{q}_j$ (average realized match quality from its history). A simpler alternative: the counterparty always accepts at the fixed outside option $r$, regardless of its match history. This makes acceptance truly automatic and the acquisition cost constant across counterparties, producing a clean regime shift in the broker's principal-mode decision. The tradeoff is that the broker acquires all positions at the same low price, which may make capture too easy and remove the natural margin compression from rising counterparty experience.

**Exclusivity under principal mode.** The base Model 1 uses per-slot independence: principal-mode matches consume one capacity slot, and other slots remain available for self-search. An alternative is full exclusivity ($\xi = 1$): an agent with any principal-mode match cannot self-search at all during that period, routing all demand through the broker. This produces total information freeze (the agent gains no new observations from any source) and stronger lock-in. With per-slot demand, an agent at $K = 5$ generates ~2.5 demands per period; under per-slot independence, some of these could go through self-search even if one slot is filled by a principal-mode match. Full exclusivity would block all self-search, significantly strengthening the lock-in. Comparing dynamics under per-slot independence and full exclusivity would test whether the full information freeze is necessary for the abrupt capture trajectory of Proposition 3a.

## Figures

**Fig. 1.** The informational mechanism.
- *Purpose:* Establishes the core mechanism: the broker learns faster than individual agents, the gap widens with matching complexity, and this drives increasing outsourcing (Propositions 1.1, 1.2, 1.3).
- *Content:* All panels at default parameters ($s = 8$, $\rho = 0.50$). Each panel includes a **base model** series (dashed grey) as a no-capture reference line, plus Model 1 series.
  - Panel A: time on the horizontal axis, prediction quality (holdout $R^2$) on the vertical axis. One line for the broker, one for the average agent. The broker-agent gap reflects the informational advantage and its dynamics over time. An inset shows the effect of varying $s$.
  - Panel B: time on the horizontal axis, outsourcing rate on the vertical axis. The base model establishes the reference trajectory. Model 1 diverges.
  - Panel C: time on the horizontal axis, average realized match output by channel (self-search, standard brokered, principal mode).

**Fig. 2.** Decoupling of structural position from informational advantage.
- *Purpose:* The central empirical implication. Shows that betweenness centrality declines while the broker's informational advantage grows, and that resource capture suspends the structural erosion (Propositions 2.1, 3a).
- *Content:* Time on the horizontal axis, dual vertical axes for broker betweenness centrality and broker prediction quality. Under Model 1, betweenness plateaus or recovers once principal mode dominates.

**Fig. 3.** Access vs. assessment decomposition over time.
- *Purpose:* Traces the shift from network access to information assessment as the dominant source of broker value (Propositions 1.3a, 1.3b).
- *Content:* Time on the horizontal axis, fraction of brokered matches on the vertical axis, decomposed into access value (counterparty was not in demander's network) and assessment value (counterparty was reachable but broker predicted better).

**Fig. 4.** Capture dynamics and the lock-in mechanism.
- *Purpose:* Shows that capture occurs and the lock-in mechanism explains why resource capture is abrupt and self-reinforcing (Proposition 3a).
- *Content:*
  - Panel A: time on the horizontal axis, principal-mode share $P^t$ on the vertical axis. Shows the abrupt tipping point as the broker shifts from standard placement to principal mode.
  - Panel B: time on the horizontal axis, average agent prediction quality on the vertical axis, stratified by principal-mode exposure (high vs. low). Broker-dependent agents stagnate; others continue improving. Panel A shows the outcome; Panel B shows the mechanism.

**Fig. 5.** Phase diagram.
- *Purpose:* Maps the conditions under which capture occurs, identifying regions of no capture, partial capture, and full capture as a function of matching complexity (Proposition 2.2).
- *Content:* Main axes TBD. Heatmap or contour plot showing the broker-agent prediction quality gap (or principal-mode share at steady state) across the parameter space.

#### SI figures

**Fig. S1.** Prediction quality decomposition.
- *Content:* Three sub-panels: $R^2$, bias, and rank correlation over time (broker and average agent). Under Model 1, agent lines stratified by principal-mode exposure.

**Fig. S2.** Attributional vs. relational channel (Proposition 1.2).
- *Content:* $\rho$ on horizontal axis; broker-agent gap in holdout $R^2$; outsourcing rate at steady state.

**Fig. S3.** OAT parameter sweeps.
- *Content:* Grid of panels varying $\eta$, $\delta$, $\tau$, $K$ while holding others at defaults.

**Fig. S4.** Network visualization snapshots.
- *Content:* The network $G$ at early, middle, and late periods. Broker node positioned centrally. Under Model 1, late-period graph should show persistent structural holes between agents matched through the broker's principal mode.

**Fig. S5.** Broker risk profile.
- *Purpose:* Shows the frequency and magnitude of inventory losses the broker absorbs in principal mode.
- *Content:* Time on the horizontal axis, distribution of $q_{ij} - r$ for principal-mode matches. Early: wider distribution with more losses. Late: concentrated in positive territory as predictions improve.

## References

Bethune, Z., Sultanum, B., & Trachter, N. (2024). An information-based theory of financial intermediation. *Review of Economic Studies*, *91*(3), 1424–1454.

Brandes, U. (2001). A faster algorithm for betweenness centrality. *Journal of Mathematical Sociology*, *25*(2), 163–177.

Brenner, T. (2006). Agent learning representation: Advice on modelling economic learning. In K. Judd & L. Tesfatsion (Eds.), *Handbook of computational economics* (Vol. 2, pp. 895–947). North-Holland.

Burt, R. S. (1992). *Structural holes: The social structure of competition*. Harvard University Press.

Burt, R. S. (2005). *Brokerage and closure: An introduction to social capital*. Oxford University Press.

Duffie, D., Gârleanu, N., & Pedersen, L. H. (2005). Over-the-counter markets. *Econometrica*, *73*(6), 1815–1847.

Freeman, L. C. (1977). A set of measures of centrality based on betweenness. *Sociometry*, *40*(1), 35–41.

Li, D. D. (1998). Middlemen and private information. *Journal of Monetary Economics*, *42*(1), 131–159.

Rogerson, R., Shimer, R., & Wright, R. (2005). Search-theoretic models of the labor market: A survey. *Journal of Economic Literature*, *43*(4), 959–988.

Watts, D. J., & Strogatz, S. H. (1998). Collective dynamics of 'small-world' networks. *Nature*, *393*(6684), 440–442.
