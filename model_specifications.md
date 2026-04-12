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

The model is domain-agnostic: it formalizes brokered matching between heterogeneous agents in a single population. The theoretical propositions apply wherever a broker facilitates pairwise matches, accumulates cross-market data, and faces structural erosion from the direct ties it creates. Four empirical domains illustrate the framework.

**Interdealer brokerage in OTC financial markets.** Dealers in over-the-counter markets (interest rate swaps, foreign exchange, corporate bonds) need counterparties for trades. Interdealer brokers (IDBs) sit between dealers, matching buy and sell interests across the market. Each successful brokered trade creates a direct relationship between two dealers who can subsequently trade bilaterally. The IDB accumulates cross-market knowledge of which dealer pairings clear efficiently. The well-documented transition from voice brokerage to electronic trading platforms (ICAP → NEX/CME, BGC → Fenics) is an instance of data capture; IDBs that became principal traders illustrate resource capture.

**Strategic alliance and joint venture brokerage.** Firms seeking partners for joint ventures, technology licensing, or co-development rely on intermediaries — management consultancies, investment banks, or specialized alliance brokers — to identify compatible partners. Match quality depends on capability complementarity: the best alliances combine partners with non-overlapping strengths. After a successful partnership, firms know each other and can pursue follow-on deals directly. The broker's informational advantage lies in knowing which capability combinations produce value across different market segments.

**Dealer networks in collectible markets.** Collectors of art, wine, rare books, or similar specialty goods seek trades or sales through dealers who know the market. Each collector has distinct tastes and holdings; match quality depends on multidimensional complementarity between what one party has and what another wants. Dealers accumulate knowledge of collector preferences across transactions. A dealer who transitions from pure intermediation to holding inventory (gallery, wine merchant) illustrates resource capture; one who builds a valuation database or subscription advisory service illustrates data capture.

**Import-export trading companies.** Producers and buyers across international markets rely on trading intermediaries to find counterparties they cannot easily reach or evaluate. Trading companies (*sōgō shōsha*, commodity brokers, Hong Kong trading houses) bridge geographically and informationally separated markets, matching exporters' goods with importers' needs. Match quality depends on multidimensional compatibility of product specifications, volumes, timing, and quality standards. Each successful brokered trade creates a direct relationship between producer and buyer who can subsequently trade bilaterally. The trading company's informational advantage lies in knowing which supplier-buyer combinations work across many markets. The transition from pure intermediation to taking principal positions — buying commodities from producers and reselling to buyers, bearing inventory and price risk — is the canonical resource capture trajectory. Some trading companies evolve further into vertically integrated conglomerates.

## Part I. Base Model

The model is a discrete-time agent-based simulation of a matching market with two participant types: *agents* and a *broker*. Agents seeking pairwise matches either search their own network or outsource the search to the broker. Each period represents one calendar quarter. All economic quantities (match output, fees, surplus) are in the same monetary units.

A single broker serves the market. This is a simplification: with multiple brokers, the data pool fragments, there is competition for informational rents, and no single broker consolidates as large an informational advantage. The model can be interpreted as a monopolistic broker or as a single broker's segment within a competitive market. Analysis of broker competition is deferred to future work.

All agents use heuristic decision rules. No agent solves an optimization problem or holds beliefs about other agents' strategies, in line with the tradition of ABM agents using simple, bounded-rationality rules grounded in empirically observable behavior (Brenner, 2006).

The base model specifies agents (§0), the matching problem (§1), how agents learn to predict match quality (§2), match economics (§3), network structure and agent turnover (§4), how agents and the broker find counterparties (§5), the outsourcing decision (§6), the broker's roster (§7), the match lifecycle (§8), and the complete step ordering (§9). There is no capture in the base model. Resource capture is specified in Part III (§13).

### 0. Agents

The model has $N$ agents (default 500) and a single broker. Agents are nodes in an undirected network $G$ that determines their search opportunities: an agent can only find counterparties among its direct connections in $G$ (§5). The network is initialized as a small-world graph with type-assortative structure (nearby types are more likely to be connected). It evolves over time as matches create new edges between matched agents (§4).

Each agent $i$ is characterized by:

- **Type** $\mathbf{x}_i \in \mathbb{R}^d$: a fixed vector of observable characteristics assigned at initialization. Types determine general quality and productive compatibility with other agents through the matching function (§1). The dimensionality $d = 8$ is fixed.
- **Active matches** $M_i^t$: the set of agents currently matched with $i$. Each agent can sustain at most $K$ simultaneous active matches (default $K = 5$).
- **Available capacity**: $K - |M_i^t|$, the number of additional matches the agent can enter.
- **Experience history** $\mathcal{H}_{i}^t = \{(\mathbf{x}_j, q_{ij})\}$: the set of (other party's type, realized match output) pairs from all matches $i$ has participated in, regardless of whether $i$ was the demander or the counterparty (§2a). Because the matching function is symmetric (§1a), both roles produce the same prediction target.
- **Satisfaction indices** $s_{i,c}^t$: one scalar per search channel $c \in \{\text{self}, \text{broker}\}$, tracking realized match value via an EWMA (§6a). Drives the outsourcing decision (§6).
- **Outside option** $r$: the minimum match value any agent requires to participate in a match (§3). Constant across agents, calibrated at initialization.

Agents exit independently each period with probability $\eta$ (default 0.02) and are replaced by new entrants with fresh types, empty histories, and satisfaction initialized at the public benchmark (§4).

#### Agent types

Agents are described by type vectors in $\mathbb{R}^d$ ($d = 8$). These types are the observable characteristics that determine productive compatibility through the matching function (§1).

Agent types lie near a smooth one-dimensional curve on the surface of the unit sphere in $\mathbb{R}^d$. The curve is parameterized by a position $t \in [0, 1]$:

$$\mathbf{x}(t) = \frac{\tilde{\mathbf{x}}(t)}{\|\tilde{\mathbf{x}}(t)\|}, \qquad \tilde{x}_k(t) = \begin{cases} \sin(2\pi f_k t + \theta_k) & k = 1, \ldots, s \\ 0 & k = s+1, \ldots, d \end{cases}$$

where $f_k \sim U\{1, 2, 3, 4, 5\}$ are random integer frequencies and $\theta_k \sim U[0, 2\pi)$ are random phases, both drawn once per simulation, and $s \leq d$ is the number of **active dimensions** — the dimensions along which the curve has nonzero variation. The remaining $d - s$ dimensions receive only noise (see below).

Each agent is drawn at a random position $t_i \sim U[0,1]$ on the curve, then perturbed:

$$\mathbf{x}_i = \frac{\mathbf{x}(t_i) + \boldsymbol{\epsilon}_i}{\|\mathbf{x}(t_i) + \boldsymbol{\epsilon}_i\|}, \qquad \boldsymbol{\epsilon}_i \sim N\!\left(\mathbf{0}, \frac{\sigma_x^2}{d} \mathbf{I}_d\right)$$

The noise $\boldsymbol{\epsilon}_i$ is applied in all $d$ dimensions (including inactive ones), so that type vectors are not exactly confined to the $s$-dimensional subspace of the curve. The per-dimension noise scale $\sigma_x / \sqrt{d}$ is chosen so that the expected Euclidean distance from an agent to its curve position is approximately $\sigma_x$ regardless of $d$. The result is then re-projected to the unit sphere.

The parameter $s$ controls the complexity of the matching problem. When $s = d$, the curve spans all $d$ dimensions: agents nearby on the curve have similar types, while agents far apart point in genuinely different directions across all of $\mathbb{R}^d$. When $s < d$, the curve is confined to a lower-dimensional subspace.

#### Broker

A single broker serves the market. The broker is a permanent node in $G$, connected to all agents on its roster. The broker is characterized by:

- **Experience history** $\mathcal{H}_b^t = \{(\mathbf{x}_i, \mathbf{x}_j, q_{ij})\}$: the set of (demander type, counterparty type, realized match output) triples from all matches the broker has mediated (§2b).
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

where $Q = 1.0$ is a constant offset that shifts $q$ positive for downstream economic computations (surplus, fees, satisfaction), and $\sigma_\varepsilon = 0.25$. The noise term $\varepsilon_{ij}$ represents idiosyncratic match-specific variation (unobserved characteristics, timing, context) that is irreducible even with perfect knowledge of $f$.

The matching function $f: \mathbb{R}^d \times \mathbb{R}^d \to \mathbb{R}$ is unknown to all agents and fixed for the duration of the simulation. $f$ represents the pure signal structure of the data-generating process.

The deterministic matching function has two components, the first relating to each party's general quality and the second to their pairing complementarity:

$$f(\mathbf{x}_i, \mathbf{x}_j) = \rho \cdot \frac{1}{2}\!\left[\text{sim}(\mathbf{x}_i, \mathbf{c}) + \text{sim}(\mathbf{x}_j, \mathbf{c})\right] + (1 - \rho) \cdot \frac{1}{2}\!\left[\text{sim}(\mathbf{x}_i, \mathbf{A}\mathbf{x}_j) + \text{sim}(\mathbf{x}_j, \mathbf{A}\mathbf{x}_i)\right]$$

where $\text{sim}(\mathbf{a}, \mathbf{b}) = \mathbf{a}^\top \mathbf{b} / (\|\mathbf{a}\| \|\mathbf{b}\|)$ denotes cosine similarity between two vectors, and $\mathbf{A}$ is a $d \times d$ random matrix with iid $N(0, 1)$ entries drawn once at initialization (see §1c). Both components are symmetric under exchange of $i$ and $j$, so $f(\mathbf{x}_i, \mathbf{x}_j) = f(\mathbf{x}_j, \mathbf{x}_i)$.

#### 1b. General quality

General quality captures the portable value each party brings to any match, independent of who the counterparty is. Both parties contribute quality along the same dimension: alignment with an **ideal type vector** $\mathbf{c} \in \mathbb{R}^d$, which represents a quality archetype. Agents whose types are aligned with $\mathbf{c}$ (high cosine similarity) are high-quality counterparties in any match.

The vector $\mathbf{c}$ is drawn at initialization as a perturbation of a random point on the agent type curve with the same $\sigma_x / \sqrt{d}$ per-dimension noise used for regular agents.

The quality component is:

$$\frac{1}{2}\!\left[\text{sim}(\mathbf{x}_i, \mathbf{c}) + \text{sim}(\mathbf{x}_j, \mathbf{c})\right]$$

Each term is a cosine similarity in $[-1, 1]$, so the average is also in $[-1, 1]$. A match between two high-quality agents produces a high quality component; a match involving a low-quality agent is penalized regardless of the other party's quality.

Because agent types are projected to the unit sphere ($\|\mathbf{x}\| = 1$), cosine similarity reduces to the dot product $\mathbf{x}^\top \mathbf{c} / \|\mathbf{c}\|$, which is linear in $\mathbf{x}$ and learnable by ridge regression. The parameter $\rho$ (§1d) controls how much the general quality component contributes to total match output.

#### 1c. Match-specific interaction

The match-specific interaction is the symmetrized cosine similarity between each agent's type and the $\mathbf{A}$-transformed type of the other:

$$\frac{1}{2}\!\left[\text{sim}(\mathbf{x}_i, \mathbf{A}\mathbf{x}_j) + \text{sim}(\mathbf{x}_j, \mathbf{A}\mathbf{x}_i)\right]$$

The matrix $\mathbf{A} \in \mathbb{R}^{d \times d}$ has iid $N(0, 1)$ entries and is drawn once at initialization. Because $\mathbf{A}$ mixes all $d$ dimensions, the interaction introduces cross-dimensional terms: the match-specific quality of the pairing depends on all $d^2$ products $x_{i,k} \cdot x_{j,l}$ (for $k, l = 1, \ldots, d$), not just the $d$ diagonal products $x_{i,k} \cdot x_{j,k}$.

The symmetrization averages both orderings of the $\mathbf{A}$-transformed interaction, ensuring $f(\mathbf{x}_i, \mathbf{x}_j) = f(\mathbf{x}_j, \mathbf{x}_i)$ even though $\mathbf{A}$ itself is not symmetric.

Each cosine similarity term is bounded in $[-1, 1]$, so the symmetrized interaction is also bounded. For a fixed agent $i$, the interaction varies smoothly with $\mathbf{x}_j$ and is approximately linear (learnable by ridge regression). The diagonal products $\mathbf{x}_i \odot \mathbf{x}_j$ capture only $d$ of the $d^2$ interaction terms induced by $\mathbf{A}$, while the full outer product $\mathbf{x}_i \otimes \mathbf{x}_j$ — the vectorization $\text{vec}()$ of the $d \times d$ matrix $\mathbf{x}_i \mathbf{x}_j^\top$, yielding $d^2$ features — captures all of them.

#### 1d. What controls the difficulty of the matching problem

- **$s$ (active dimensions).** When $s = d$, the type curve spans all $d$ dimensions, creating maximum diversity in interaction effects across agents. When $s < d$, the curve is confined to a lower-dimensional subspace, making the interaction structure lower-dimensional and easier for individual agents to learn from their own history. The broker's advantage is largest when $s$ is high.

- **Agent geometry.** Two aspects interact: (1) how agents are distributed around the curve ($\sigma_x$ relative to inter-agent spacing), and (2) how much of type space the curve spans (controlled by $s$). At the default $\sigma_x$, agents overlap with multiple neighbors' type regions, creating meaningful variation in match quality that requires data to learn.

- **$\rho$ (mixing weight).** At low $\rho$, the interaction dominates and cross-agent data is essential; the broker's advantage is large. At high $\rho$, general quality dominates and agents can learn from their own matches; the broker's advantage shrinks.

- **$\mathbf{A}$ (interaction matrix).** The random matrix $\mathbf{A}$ creates $d^2$ cross-dimensional interaction terms $x_{i,k} \cdot x_{j,l}$ that contribute to match quality. An agent observing only its own matches sees a fixed self-type and varying partner types, and can learn the interaction from the $d$ features in $\mathbf{x}_{\text{partner}}$ alone. The broker, observing matches across many pairs with varying types on both sides, benefits from representing all $d^2$ cross-terms via the outer product $\mathbf{x}_i \otimes \mathbf{x}_j$. This is the primary source of the broker's feature advantage.

- **$\sigma_\varepsilon$ (noise scale).** With $\sigma_\varepsilon = 0.25$ and signal in $[-1, 1]$, the signal-to-noise ratio is approximately 4:1.

### 2. Learning

Agents and the broker use predicted match quality $\hat{q}_{ij}$ in every core decision: which counterparties to select (§5), and whether to outsource matching (§6).

Both agents and the broker learn from experience using ridge regression, fitted each period on their accumulated history.

#### 2a. Agent $i$'s prediction

Agent $i$'s history $\mathcal{H}_i^t = \{(\mathbf{x}_j, q_{ij})\}_{m=1}^{n_i}$ records the other party's type and the realized match output from every match $i$ has participated in, regardless of role. Because $f$ is symmetric (§1a), observations from both roles pool into a single history.

Agent $i$ knows its own type $\mathbf{x}_i$, so $f(\mathbf{x}_i, \mathbf{x}_j)$ is a function of the other party's type $\mathbf{x}_j$ alone. The agent fits a ridge regression on $\mathcal{H}_i^t$ using $d$ features:

$$\hat{q}_{i}(\mathbf{x}_j) = \hat{\boldsymbol{\beta}}_{i}^\top \mathbf{x}_j + \hat{\alpha}_{i}$$

where $\hat{\boldsymbol{\beta}}_{i}, \hat{\alpha}_{i}$ are fitted on $\{(\mathbf{x}_j, q_{ij})\}$ with regularization $\lambda$ (default 1.0). Because types are on the unit sphere, cosine similarity reduces to the dot product, and a linear model suffices without quadratic features. The same model serves both roles (evaluating potential counterparties and evaluating incoming proposals). Refitted each period.

#### 2b. Broker's prediction

The broker's history $\mathcal{H}_b^t = \{(\mathbf{x}_i, \mathbf{x}_j, q_{ij})\}_{m=1}^{n_b}$ records both parties' types and the realized match output from every match the broker has mediated. The ordering of $\mathbf{x}_i$ and $\mathbf{x}_j$ in the record is arbitrary (both orderings produce the same $q$ because $f$ is symmetric). The broker's history is seeded at initialization with observations from random pairings (§11c).

Unlike an individual agent, the broker observes the same agent types producing different outcomes with different partners. The broker fits a single pooled ridge regression on both parties' types and their full outer-product interaction:

$$\hat{q}_b(\mathbf{x}_i, \mathbf{x}_j) = \hat{\boldsymbol{\beta}}_1^\top \mathbf{x}_i + \hat{\boldsymbol{\beta}}_2^\top \mathbf{x}_j + \hat{\boldsymbol{\beta}}_{\times}^\top \text{vec}(\mathbf{x}_i \otimes \mathbf{x}_j) + \hat{\alpha}_b$$

where the coefficients are fitted on $\{([\mathbf{x}_i; \mathbf{x}_j; \text{vec}(\mathbf{x}_i \otimes \mathbf{x}_j)], q_{ij})\}$ with regularization $\lambda$. The feature vector is $[\mathbf{x}_i; \mathbf{x}_j; \text{vec}(\mathbf{x}_i \otimes \mathbf{x}_j)]$, giving $d^2 + 2d$ features total. The outer-product features $\mathbf{x}_i \otimes \mathbf{x}_j$ capture all $d^2$ cross-dimensional interactions induced by the matrix $\mathbf{A}$ in the matching function (§1c), while the separate $\mathbf{x}_i$ and $\mathbf{x}_j$ blocks capture linear main effects. Because agent types are on the unit sphere, cosine similarity reduces to the dot product and quadratic features are unnecessary. To exploit the symmetry of $f$, the broker augments its training data by including both orderings of each observation: for each $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ in $\mathcal{H}_b$, the broker trains on both $[\mathbf{x}_i; \mathbf{x}_j; \text{vec}(\mathbf{x}_i \otimes \mathbf{x}_j)]$ and $[\mathbf{x}_j; \mathbf{x}_i; \text{vec}(\mathbf{x}_j \otimes \mathbf{x}_i)]$ with the same target $q_{ij}$. This doubles the effective training set and ensures the regression learns that the two input slots are interchangeable. Refitted each period.

The broker's pooled model has three advantages over any individual agent's model:

1. **More data.** The broker accumulates observations across all client agents, giving it far more data points than any individual agent. With $n_b \gg n_i$, the broker's coefficient estimates have lower variance.

2. **Richer features.** By including both $\mathbf{x}_i$ and $\mathbf{x}_j$ as features, the broker's model captures how match quality varies across different pairings. Individual agents, with their own type fixed, cannot learn how the interaction structure varies with both parties' types.

3. **Outer-product interaction features.** The full outer product $\mathbf{x}_i \otimes \mathbf{x}_j$ gives the broker's linear model $d^2$ features that capture all cross-dimensional interactions $x_{i,k} \cdot x_{j,l}$ for every pair $(k, l)$. The matrix $\mathbf{A}$ in the matching function creates these cross-dimensional terms. An individual agent does not need these features (its own type is fixed, so the interaction is already a function of the other party's type alone), but the broker, fitting across agents with varying types on both sides, benefits from explicitly representing the full interaction structure.

#### 2c. The asymmetry between agents and the broker

An agent learns "what kind of partner works well for me" from a small, agent-specific sample ($d$ features). The broker learns "what kind of pairings work well" from a large, cross-market sample ($d^2 + 2d$ features). The broker's richer features and larger data volume produce better predictions, especially when $s$ is high. As agents accumulate matches, their estimates improve and the broker's advantage narrows; the advantage is largest when agents have few observations.

#### 2d. Public information

A constant, scalar **public benchmark** $\bar{q}_{\text{pub}} = E[q]$ is computed once at initialization from a Monte Carlo sample of random agent pairs (§11c). This is the unconditional mean match output.

The benchmark initializes satisfaction indices (§6a) and broker reputation (§6c).

### 3. Match Economics

Matches form when both parties expect positive gains from trade, following the standard search-and-matching framework.

#### 3a. Outside options

All agents share a common outside option $r$: the minimum per-period match value an agent requires to participate. Below this threshold, the agent prefers to remain unmatched. The outside option is calibrated at initialization:

$$r = 0.60 \cdot \bar{q}_{\text{pub}}$$

where $\bar{q}_{\text{pub}}$ is the mean match output computed from a Monte Carlo sample (§11c). The 0.60 calibration sets the outside option at 60% of average match value, producing a market where approximately 40% of match output is surplus available for gains from trade. A constant $r$ simplifies the broker's principal-mode decision (§13d) to a clean regime shift: the profitability comparison is the same for every counterparty.

#### 3b. Participation constraints

A match between demander $i$ and counterparty $j$ forms only if both parties predict positive gains:

- **Demander**: $\hat{q}_{i}(\mathbf{x}_j) > r$
- **Counterparty**: $\hat{q}_{j}(\mathbf{x}_i) > r$

Because the matching function is symmetric, both parties are predicting the same quantity — the match quality of the pairing — using the same type of model. Each evaluates whether the match is worth entering from its own perspective.

When the broker proposes a match, it applies the participation constraint using its own prediction: $\hat{q}_b(\mathbf{x}_i, \mathbf{x}_j) > r$. The counterparty still evaluates the proposal independently using its own model.

#### 3c. Broker fee

The broker charges a fixed per-match fee $\phi$ for each match it mediates. The fee is paid by the demander and is independent of match quality. The default $\phi$ is calibrated at initialization (§11c).

The fixed fee isolates the informational channel: the broker competes with agents' self-search solely on the quality of its match predictions, not on price. If the broker can attract and retain clients at a fixed fee, its value must derive from prediction accuracy rather than price adjustments.

### 4. Network Structure and Turnover

Agents interact through a single undirected network $G$ that determines each agent's search opportunities and structural position.

#### 4a. Network initialization

$G$ is initialized as a small-world graph (Watts & Strogatz, 1998), starting from a ring lattice where each agent is connected to its $k = 6$ nearest neighbors in the type space, with rewiring probability $p_{\text{rewire}} = 0.1$. Produces high clustering, short path lengths, and moderate type assortativity. Agents are ordered by first principal component of their type vectors before constructing the ring lattice, so that initial neighborhoods reflect type similarity.

The broker is a permanent node in $G$. When an agent joins the broker's roster (§7), an edge between the agent and the broker node is added to $G$. The broker node is excluded from matching candidate pools (it has no type vector and is not eligible for self-search), but its presence in $G$ allows network measures (betweenness centrality, constraint, effective size) to be computed directly on $G$ without constructing a separate augmented graph.

#### 4b. Match tie formation

Each realized match (whether through self-search or brokered) adds an undirected edge between the demander and counterparty in $G$, if one does not already exist. Ties persist permanently — former counterparties remain connected after their match dissolves.

This is the sole mechanism of network densification. Each brokered match closes a structural hole that the broker bridged, contributing to the self-liquidating dynamic of structural-hole brokerage.

#### 4c. Agent turnover

Agents exit independently each period with probability $\eta$ (default 0.02), yielding an expected agent lifetime of 50 quarters (12.5 years).

Exiting agents are replaced by entrants with fresh types sampled from the curve at a random position $t \sim U[0,1]$ plus noise (same procedure as initialization), empty experience histories, and satisfaction indices initialized at $\bar{q}_{\text{pub}}$. The exiting agent's node in $G$ is removed (along with all its edges). The entrant is added to $G$ with $\lfloor k/2 \rfloor$ edges to agents sampled from the type neighborhood (probability $\propto \exp(-\|\mathbf{x}_{i'} - \mathbf{x}_j\|^2)$). Entrants join with fewer connections than the initial network degree $k$ to reflect the disadvantage of being new to a market: established agents have accumulated connections through prior matches, while entrants start with only a few type-similar contacts.

Turnover refreshes the broker's structural advantage: new entrants with sparse networks are more likely to need the broker's matching service.

### 5. Search

Each period, each agent with available capacity ($K - |M_i^t| > 0$) independently draws demand once with probability $p_{\text{demand}}$ (default 0.50). The draw is per agent, not per capacity slot: an agent either has demand this period or does not, regardless of how many slots are open. An agent with demand either searches its own network (§5a) or outsources to the broker (§5b); the choice between the two channels is governed by the outsourcing decision rule (§6).

#### 5a. Self-search

Agent $i$ evaluates its direct network neighbors in $G$ as potential counterparties. Only neighbors with available capacity ($K - |M_j^t| > 0$) who are not already matched with $i$ are considered.

If no direct neighbor has available capacity, the agent goes unmatched this period and the no-match penalty applies (§6a).

For each candidate $j$, the agent predicts match quality using its model: $\hat{q}_{i}(\mathbf{x}_j)$. The agent selects the candidate with the highest predicted quality, provided the participation constraint is satisfied: $\hat{q}_{i}(\mathbf{x}_j) > r$ (§3b). If multiple candidates achieve the same maximum, one is selected uniformly at random. If no candidate yields positive predicted surplus, no match is proposed.

The proposal enters the match formation step (§9, Step 3), where all proposals from both channels are processed sequentially in random order. The counterparty evaluates the proposal using its own model and accepts if $\hat{q}_{j}(\mathbf{x}_i) > r$ (§3b), provided it has not already been matched this period.

#### 5b. Broker-mediated search

When agent $i$ outsources to the broker, the broker includes agent $i$ in its allocation for the current period. Agent $i$ is also added to the broker's roster if not already a member (§7).

At the end of Step 1 (after all outsourcing decisions), the broker observes its full client list $D^t$ (the set of demanders who outsourced this period) and the available roster members $\text{Roster}^t \cap \{\text{agents with available capacity}\}$. The broker computes predicted match quality $\hat{q}_b(\mathbf{x}_i, \mathbf{x}_j)$ for every (demander, available roster member) pair and assigns matches using a greedy best-pair heuristic (§9, Step 2b): iteratively select the highest-quality pair, propose that match, and remove both demander and counterparty from consideration. This continues until all demanders are matched, the roster is exhausted, or no remaining pair has positive predicted surplus ($\hat{q}_b > r$). The broker applies the same participation constraint as self-search: it does not propose matches with non-positive predicted surplus.

Proposals enter the match formation step (§9, Step 3) alongside self-search proposals. The counterparty evaluates using its own model (§3b).

Agents whose demand is not filled (because the roster was exhausted, no candidate cleared the surplus threshold, or the counterparty rejected) receive no proposal. The agent's broker satisfaction decays toward zero (§6a).

After a brokered match forms, the realized match output $q_{ij}$ is observed by all parties involved (the two agents and the broker). The broker adds the observation to its experience history for future predictions (§2). The broker does not observe outcomes of self-search matches — it learns only from matches it mediates.

### 6. The Outsourcing Decision

#### 6a. Satisfaction tracking

Each agent $i$ maintains a satisfaction index $s_{i,c}^t$ for each search channel $c \in \{\text{self}, \text{broker}\}$. These scores summarize past matching outcomes and drive the outsourcing decision.

The index is an exponentially weighted moving average (recency weight $\omega = 0.3$) of realized match value, net of broker fees when applicable:

$$s_{i,c}^{t+1} = (1 - \omega)\,s_{i,c}^t + \omega \cdot \tilde{q}$$

where $\tilde{q}$ is the satisfaction input:

| Channel | Satisfaction input $\tilde{q}$ |
|---------|-------------------------------|
| Self-search | $q_{ij}$ |
| Brokered match | $q_{ij} - \phi$ |

**No-match penalty.** When a search channel fails to produce a match — either the broker makes no proposal (roster exhausted or no surplus-positive pair) or self-search yields no acceptable candidate — the corresponding satisfaction index decays toward zero:

$$s_{i,c}^{t+1} = (1 - \omega)\, s_{i,c}^t$$

Satisfaction indices are not floored: they can go negative. The EWMA's recency weighting ensures recovery from negative values within a few good observations. New agents initialize all indices at the public benchmark $\bar{q}_{\text{pub}}$ (§2d).

#### 6b. Decision rule

Each period, an agent with demand chooses between two search channels: self-search or the broker. The agent selects the channel with the higher satisfaction score. Ties are broken uniformly at random.

If the agent has not yet used the broker (its broker satisfaction has never been updated from a realized match or no-match penalty), it substitutes broker reputation for its broker satisfaction score. An agent that has outsourced at least once — even if only receiving a no-match penalty — uses its own broker satisfaction.

#### 6c. Broker reputation

$$\text{rep}_b^{t+1} = \begin{cases} \frac{1}{|D_b^t|} \sum_{i \in D_b^t} s_{i,b}^{t+1} & \text{if } D_b^t \neq \emptyset \\[4pt] \text{rep}_b^{t} & \text{otherwise} \end{cases}$$

where $D_b^t$ is the set of agents who outsourced to the broker this period. When the broker has current clients, reputation is updated to the mean of their (post-update) broker satisfaction. When it has no clients, the value is held from the previous period. Reputation is initialized at $\bar{q}_{\text{pub}}$ (§2d).

### 7. Broker Roster

The broker maintains a **roster** of agents it knows and can propose as counterparties when mediating matches.

**Initialization.** The roster is seeded with $\lceil 0.20 \cdot N \rceil$ agents (default 100 at $N = 500$) chosen uniformly at random from the population. This ensures the broker can serve early outsourcers without frequent no-match failures that would drive broker satisfaction down before the broker has a chance to demonstrate value. The broker's history is seeded with observations from random pairings among these initial roster members (§11c).

**Growth.** Any agent who outsources to the broker in a given period is added to the roster permanently (if not already a member). The roster thus grows organically with broker usage.

**Availability.** A roster member is available for matching in a given period only if:
1. It has spare capacity: $|M_j^t| < K$.
2. It is not a demander being matched in the current period's allocation (an agent cannot be simultaneously a demander and a counterparty in the same broker allocation round).

There is no fixed roster size or target. The roster grows as the broker attracts clients, creating a network effect: a larger roster offers better matching options, which improves broker satisfaction, which attracts more outsourcing, which grows the roster further. In the early periods, when the roster is small, the broker has few counterparties to offer, naturally limiting its initial appeal.

### 8. Match Lifecycle

Matches last $\tau$ periods (default $\tau = 1$). During the match, both parties observe the realized match output. After $\tau$ periods, the match dissolves and both parties regain one unit of capacity.

**At match formation:**
1. Realized output is drawn: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$.
2. Both parties add the observation to their histories: the demander adds $(\mathbf{x}_j, q_{ij})$ to $\mathcal{H}_{i}$; the counterparty adds $(\mathbf{x}_i, q_{ij})$ to $\mathcal{H}_{j}$.
3. If brokered, the broker adds $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$.
4. An edge is added between $i$ and $j$ in $G$ (if not already present).

**At match expiration** (after $\tau$ periods): the match is removed from both parties' active match sets $M_i^t$ and $M_j^t$. Both regain one unit of capacity.

At $\tau = 1$ (the default), matches are transactional: they form and dissolve within the same period. Agents are always at full capacity at the start of each period, so the capacity constraint $K$ is effectively the maximum number of matches an agent can form per period. At $\tau > 1$, matches persist, and the capacity constraint becomes binding as agents accumulate active matches that have not yet expired.

### 9. Base Model Pseudocode

At the start of the simulation, the state of the world must be initialized.

> **INITIALIZE**
>
> *Agent types and matching function.*
> I.1. &emsp;Generate random frequencies $f_k$ and phases $\theta_k$ for the sinusoidal curve (§0).
> I.2. &emsp;Draw $N$ agent types: each at a random position $t_i \sim U[0,1]$ on the curve, perturbed by noise, and projected to the unit sphere.
> I.3. &emsp;Draw ideal type $\mathbf{c}$ (perturbation of a random curve position).
> I.4. &emsp;Draw interaction matrix $\mathbf{A} \in \mathbb{R}^{d \times d}$ with iid $N(0,1)$ entries.
>
> *Calibration.*
> I.5. &emsp;Compute $\bar{q}_{\text{pub}} = E[q]$ from 10,000 random agent pairs. Set $r \leftarrow 0.60 \cdot \bar{q}_{\text{pub}}$.
> I.6. &emsp;Set broker fee $\phi$ (§11b).
>
> *Network.*
> I.7. &emsp;Build $G$: Watts–Strogatz with $N$ nodes, degree $k$, rewiring $p_{\text{rewire}}$. Node order = agents sorted by first principal component of type.
>
> *Broker.*
> I.8. &emsp;Seed broker roster with $\lceil 0.20 \cdot N \rceil$ randomly chosen agents. Add broker-agent edges to $G$ for each roster member.
> I.9. &emsp;Seed broker history $\mathcal{H}_b$ with 20 observations from random pairings among roster members (realize match outputs and record).
>
> *State variables.*
> I.10. &emsp;For each agent $i$: seed $\mathcal{H}_{i}$ with 5 pairings sampled from $i$'s neighbors in $G$ (realize match outputs, record); $s_{i,\text{self}}^0 \leftarrow \bar{q}_{\text{pub}}$; $s_{i,\text{broker}}^0 \leftarrow \bar{q}_{\text{pub}}$; $M_i^0 \leftarrow \emptyset$.
> I.11. &emsp;$\text{rep}^0 \leftarrow \bar{q}_{\text{pub}}$; $\Pi_b \leftarrow 0$.

Each period proceeds through seven steps.

> **PERIOD $t$:**
>
> **0. MATCH EXPIRATIONS**
> 0.1. &emsp;For each active match that has lasted $\tau$ periods: remove from both parties' active match sets. Both regain one unit of capacity.
>
> **1. DEMAND GENERATION AND OUTSOURCING DECISIONS**
> 1.1. &emsp;For each agent $i$ with available capacity ($K - |M_i^t| > 0$): generate demand with probability $p_{\text{demand}}$.
> 1.2. &emsp;For each agent $i$ with demand:
> &emsp;&emsp;$\text{score}_{\text{self}} \leftarrow s_{i,\text{self}}^t$
> &emsp;&emsp;$\text{score}_{\text{broker}} \leftarrow s_{i,\text{broker}}^t$ &ensp;(use $\text{rep}^t$ if untried; §6b)
> &emsp;&emsp;$\text{decision}_i \leftarrow \arg\max(\text{score}_{\text{self}},\; \text{score}_{\text{broker}})$
> &emsp;&emsp;If $\text{decision}_i = \text{broker}$: add $i$ to broker roster (if not already present); add edge $(i, b)$ to $G$ if not already present (§4a)
> &emsp;Output: partition of demanders into self-searchers and broker client list $D^t$.
>
> **2. CANDIDATE EVALUATION**
>
> &emsp;**2.1. Fit prediction models:**
> 2.1.1. &emsp;For each agent $i$: refit ridge model on $\mathcal{H}_{i}^t$ (§2a).
> 2.1.2. &emsp;Refit broker's pooled ridge model on $\mathcal{H}_b^t$ (§2b).
>
> &emsp;**2.2. Self-searches:**
> 2.2.1. &emsp;For each agent $i$ with $\text{decision}_i = \text{self}$:
> &emsp;&emsp;Collect candidates: direct neighbors of $i$ in $G$ with available capacity, not already matched with $i$.
> &emsp;&emsp;For each candidate $j$: predict $\hat{q}_{i}(\mathbf{x}_j)$ using agent's model.
> &emsp;&emsp;Select $j^* = \arg\max \hat{q}_{i}(\mathbf{x}_j)$ &ensp;(ties broken uniformly at random)
> &emsp;&emsp;If $\hat{q}_{i}(\mathbf{x}_{j^*}) \leq r$: no match this period.
> &emsp;&emsp;Else: record proposed match $(i, j^*)$.
>
> &emsp;**2.3. Broker proposals:**
> 2.3.1. &emsp;Collect client list: $D^t = \{i : \text{decision}_i = \text{broker}\}$.
> 2.3.2. &emsp;$\text{available\_roster} \leftarrow \text{Roster}^t \cap \{\text{agents with available capacity}\} \setminus D^t$.
> 2.3.3. &emsp;Compute quality matrix: $\hat{Q}[i,j] = \hat{q}_b(\mathbf{x}_i, \mathbf{x}_j)$ for all $i \in D^t$, $j \in \text{available\_roster}$.
> 2.3.4. &emsp;While $D^t$ non-empty AND available\_roster non-empty:
> &emsp;&emsp;$(i^*, j^*) = \arg\max \hat{Q}[i,j]$ &ensp;(ties broken uniformly at random)
> &emsp;&emsp;If $\hat{Q}[i^*, j^*] \leq r$: break (no remaining pair has positive surplus)
> &emsp;&emsp;Record proposed match $(i^*, j^*)$
> &emsp;&emsp;Remove $i^*$ from $D^t$; remove $j^*$ from available\_roster.
> 2.3.5. &emsp;If $D^t$ non-empty (roster exhausted or no surplus-positive pair): for each remaining $i \in D^t$, mark as no-proposal.
>
> **3. MATCH FORMATION**
>
> &emsp;**3.1. Sequential acceptance:**
> 3.1.1. &emsp;Shuffle all proposed matches (from both self-search and broker) into random order.
> 3.1.2. &emsp;For each proposed match $(i, j)$ in order:
> &emsp;&emsp;If counterparty $j$ is already matched this period: skip (demander $i$ goes unmatched).
> &emsp;&emsp;Counterparty $j$ evaluates: $\hat{q}_{j}(\mathbf{x}_i)$ using its model.
> &emsp;&emsp;If $\hat{q}_{j}(\mathbf{x}_i) \leq r$: reject.
> &emsp;&emsp;Else: accept. Mark $j$ as matched for this period.
>
> &emsp;**3.2. Finalization** (for each accepted match $(i, j)$):
> 3.2.1. &emsp;Realize output: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$.
> 3.2.2. &emsp;Add match to active sets: $M_i^{t+1} \leftarrow M_i^t \cup \{j\}$; $M_j^{t+1} \leftarrow M_j^t \cup \{i\}$.
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
> &emsp;&emsp;For each agent $i$ that formed a new match via channel $c$:
> &emsp;&emsp;&emsp;If self-search: $\tilde{q} = q_{ij}$
> &emsp;&emsp;&emsp;If brokered: $\tilde{q} = q_{ij} - \phi$
> &emsp;&emsp;&emsp;$s_{i,c}^{t+1} = (1 - \omega)\, s_{i,c}^t + \omega \cdot \tilde{q}$
> &emsp;&emsp;For each agent $i$ whose chosen channel produced no match this period:
> &emsp;&emsp;&emsp;$s_{i,c}^{t+1} = (1 - \omega) \cdot s_{i,c}^t$ &ensp;(no-match penalty; §6a)
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
> **6. NETWORK MEASURES** (computed every $M$ periods, default $M = 10$):
> 6.1. &emsp;Compute on $G$ (which includes the broker node; §4a): betweenness centrality $C_B(b)$; Burt's constraint (broker's ego network); effective size (broker's ego network).
> 6.2. &emsp;Compute prediction quality ($R^2$, bias, rank correlation) for broker and agents (§10).
>
> **7. PERIOD RECORDING** (every period):
> 7.1. &emsp;Record period aggregates: match quality by channel; outsourcing rate ($|D^t| / |\text{demanders}|$); roster size.
> 7.2. &emsp;Record broker state: cumulative revenue $\Pi_b$; reputation $\text{rep}^t$; roster size; $|\mathcal{H}_b^t|$.

#### Parallelism summary

Steps 0 and 1 are embarrassingly parallel across agents. Step 2.2 (self-searches) is parallel across agents. Step 3 requires a conflict resolution pass but per-match computations are parallel. Steps 4–5 involve writes to shared state that require synchronization, but writes are non-overlapping (each match writes to distinct agent records). Network measures are the most expensive single computation; they read the full state but write nothing and can be offloaded to a separate thread or deferred to a coarser schedule.

### 10. Performance Measures

Computed on $G$ (which includes the broker as a permanent node; §4a) each measurement period. No agent uses these measures in its decisions; they are outputs for analysis.

#### Network measures

**Betweenness centrality.** Standard Freeman betweenness (Freeman, 1977) computed on $G$. The broker's betweenness is the fraction of all shortest paths that pass through the broker node, normalized by $\binom{N+1}{2}$:

$$C_B(b) = \frac{1}{\binom{N+1}{2}} \sum_{i \neq j \neq b} \frac{\sigma_{ij}(b)}{\sigma_{ij}}$$

where $\sigma_{ij}$ is the number of shortest paths from $i$ to $j$, and $\sigma_{ij}(b)$ is the number of those paths passing through broker node $b$. As matches create direct ties, shortest paths increasingly bypass the broker, reducing betweenness — the structural erosion that the theory predicts.

**Burt's constraint.** Computed on the broker's ego network (Burt, 1992):

$$C_b = \sum_j \left(p_{bj} + \sum_{h \neq b,j}
p_{bh}\, p_{hj}\right)^2$$

where $p_{bj}$ is the proportion of the broker's ties invested in node $j$. Low constraint = broker spans structural holes. High constraint = broker's contacts are interconnected.

**Effective size.** The number of non-redundant contacts in the broker's ego network (Burt, 1992): $\text{ES}_b = |N(b)| - \sum_j p_{bj} \sum_{h \neq b} p_{bh}\, m_{jh}$ where $m_{jh} = 1$ if $j$ and $q$ are connected.

#### Prediction quality

**Winner's curse / selection bias.** Both agents and the broker select the counterparty with the highest *predicted* match quality from their candidate set ($\arg\max_j \hat{q}_{ij}$). When predictions are noisy, the selected counterparty's prediction $\hat{q}_{ij^*}$ is systematically inflated relative to the true match quality $f(\mathbf{x}_i, \mathbf{x}_{j^*})$, because the selection picks up positive noise realizations. This is the classic winner's curse.

**Holdout $R^2$ (model quality).** Each period, a sample of random agent pairs is evaluated using noiseless true match quality $f(\mathbf{x}_i, \mathbf{x}_j)$ as the target. These pairs are *not* selected by any agent's model. Holdout $R^2$ measures pure model quality: how well the regression model approximates the true matching function. It is the cleanest measure of informational advantage because it is uncontaminated by the winner's curse or by variation in candidate pool composition.

**Selected-sample metrics.** Three metrics are computed over a rolling window of the last 50 actual matches:

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
| $p_{\text{demand}}$ | Per-period demand probability | 0.50 | Per agent with available capacity |
| $\sigma_x$ | Type noise scale | 0.5 | Expected distance from agent to curve position |

**Calibration parameters.** Set during model development. Constant in production runs.

| Symbol | Meaning | Default | Notes |
|--------|---------|---------|-------|
| $r$ | Outside option | $0.60 \cdot \bar{q}_{\text{pub}}$ | Constant for all agents; calibrated at initialization |
| $\lambda$ | Ridge regularization | 1.0 | For all ridge regression models |
| $\sigma_\varepsilon$ | Match output noise SD | 0.25 | SNR ≈ 4:1 |
| $\phi$ | Broker fee | See §11b | Fixed per match |

**Phase diagram axes.** Primary parameters of interest.

| Symbol | Meaning | Default | Sweep |
|--------|---------|---------|-------|
| $s$ | Active dimensions | 8 | {2, 4, 6, 8} |
| $\rho$ | Quality-interaction mixing weight | 0.50 | {0, 0.10, 0.30, 0.50, 0.70, 0.90, 1.0} |

**Model 1 parameters.** Apply only under resource capture (§13).

| Symbol | Meaning | Default | Notes |
|--------|---------|---------|-------|
| $\psi$ | Principal-mode fee | See §13e | Fixed per period per match; calibrated as $\alpha_\psi \cdot \bar{q}_{\text{pub}}$ |

**OAT sensitivity parameters.** Varied one at a time while holding all others at defaults.

| Symbol | Meaning | Default | Sweep | Notes |
|--------|---------|---------|-------|-------|
| $\tau$ | Match duration (periods) | 1 | {1, 2, 4, 8} | Transactional at $\tau = 1$; relational at $\tau > 1$ |
| $K$ | Match capacity | 5 | {1, 2, 5, 10, 20, 50} | Exclusive at $K = 1$; concurrent at $K > 1$ |
| $\eta$ | Agent entry/exit rate | 0.02 | {0.01, 0.02, 0.05, 0.10} | |
| $\psi$ | Principal-mode fee | See §13e | Sweep around default | |

The match lifecycle parameters $\tau$ and $K$ jointly determine the market regime. Different combinations map to the illustrative domains:

| Domain | $\tau$ | $K$ | Rationale |
|--------|--------|-----|-----------|
| Interdealer brokerage | 1 | 5–10 | Trades are transactional; dealers maintain many concurrent positions |
| Collector networks | 1 | 2–5 | Transactions are discrete; collectors handle a moderate number |
| Import-export trading | 2–4 | 2–5 | Shipments span multiple periods; moderate concurrency |
| Strategic alliances / JV | 4–8 | 1–2 | Partnerships are long-lived and near-exclusive |

**Implementation parameters.** Control simulation scale.

| Symbol | Meaning | Default | Scale check |
|--------|---------|---------|-------------|
| $N$ | Agent population | 500 | {250, 500, 1000} |
| $T$ | Simulation length (periods) | 200 | {100, 200, 400} |
| $T_{\text{burn}}$ | Burn-in periods (discarded) | 30 | — |
| $M$ | Network measure interval | 10 | — |

#### 11b. Broker fee calibration

The broker fee $\phi$ is set to a fraction of the average match surplus: $\phi = \alpha_\phi \cdot (\bar{q}_{\text{pub}} - r)$, where $\alpha_\phi = 0.20$ (default). This ensures the fee is economically meaningful (large enough that outsourcing is a real cost) but not prohibitive (small enough that better match quality can justify the expense). The fee is computed once at initialization and held constant.

#### 11c. Initial conditions

The initialization procedure generates the matching environment, agents, and network in the following order.

1. **Agent types** (§0). Generate random frequencies and phases for the sinusoidal curve. Draw $N$ agent types at random curve positions with noise. Project to unit sphere.
2. **Matching function** (§1). Draw ideal type $\mathbf{c}$ (perturbation of a random curve position). Draw interaction matrix $\mathbf{A}$.
3. **Calibration.** Compute $\bar{q}_{\text{pub}}$ from 10,000 random agent pairs. Set $r = 0.60 \cdot \bar{q}_{\text{pub}}$. Set $\phi$ per §11b.
4. **Network** (§4a). Build Watts-Strogatz graph with agents ordered by first principal component.
5. **Agent histories.** For each agent $i$: seed $\mathcal{H}_i$ with 5 pairings sampled from $i$'s neighbors in $G$ (realize match outputs, record). This ensures initial predictions reflect the agent's local network, matching the self-search mechanism.
6. **Broker** (§7). Seed roster with $\lceil 0.20 \cdot N \rceil$ random agents; add broker-agent edges to $G$. Seed $\mathcal{H}_b$ with 20 random pairings among roster members (realize outputs, record).
7. **State variables.** For each agent: satisfaction at $\bar{q}_{\text{pub}}$, empty active match sets. Broker reputation at $\bar{q}_{\text{pub}}$.

#### 11d. Reproducibility

All randomness flows from a single integer seed. The seed determines: type draws, the realization of $G$, matching function parameters ($\mathbf{c}$, $\mathbf{A}$), broker seed roster, and all subsequent random events. Simulations are fully reproducible given (parameter dictionary, seed).

### 12. Verification and Robustness

#### 12a. Verifying the no-capture region

The model must produce parameter combinations where the broker remains a commodity intermediary. If capture occurs for every parameter setting, the model does not demonstrate transient brokerage but inevitable capture.

The key verification concern is that the positive feedback loop (more outsourcing → more broker data → better predictions → more outsourcing) produces capture in some regimes and not in others.

#### 12b. Analytic benchmark for the broker's advantage

All agents use ridge regression. For a linear target with Gaussian noise, ridge regression MSE scales as $\text{MSE} \sim p / n + \lambda \|\beta^*\|^2$, where $p$ is the number of features and the first term is estimation error (decreasing in $n$).

**Agent.** Agent $i$ fits $q \approx \beta^\top \mathbf{x}_j + c$ from $n_i$ observations ($d + 1$ parameters).

**Broker.** The broker fits $q \approx \beta^\top [\mathbf{x}_i; \mathbf{x}_j; \text{vec}(\mathbf{x}_i \otimes \mathbf{x}_j)] + c$ from $n_b$ observations ($d^2 + 2d + 1$ parameters).

**Advantage condition.** The broker outperforms the agent when:

$$\frac{d^2 + 2d}{n_b} < \frac{d}{n_i} \quad \Longrightarrow \quad n_b > (d + 2) \cdot n_i$$

At $d = 8$, the broker needs $n_b > 10 \cdot n_i$. Since the broker pools observations across all clients, this is easily satisfied after a few periods.

## Part III. Model Variant: Resource Capture

All base model mechanisms (§§0–10) operate unchanged. The difference: the broker can additionally act as a **principal**, acquiring a counterparty's position or resource and presenting itself as the counterparty to the demander. Rather than connecting two agents, the broker takes one side of the match. This implements the resource capture mode of Proposition 3a.

### 13. Resource Capture

#### 13a. Setup

Under resource capture, the broker transitions from intermediary to principal. Instead of connecting a demander with a counterparty, the broker acquires the counterparty's position — paying the counterparty for its resource or service — and then matches directly with the demander. The demander deals with the broker, not with the original counterparty. The broker earns the spread between what it charges the demander and what it pays the counterparty, bearing inventory risk if the match output falls short.

**Agent state additions.** Matches gain a flag: *transparent* (standard brokerage, as in the base model) or *principal* (broker takes one side). No new agent-level state variables are needed. Principal-mode matches consume one capacity slot independently — other slots remain available for self-search or further broker matches.

#### 13b. Mechanism

When the broker operates in principal mode for demander $i$:

1. The broker identifies the best counterparty $j$ using its model (same allocation as the base model, §9 Step 2.3).
2. **The broker acquires $j$'s position**: it pays agent $j$ the outside option $r$ for $j$'s resource or service. Agent $j$ is compensated and its capacity slot is consumed for the period, but $j$ does not learn who the resource is destined for.
3. **The broker matches with demander $i$**, presenting the acquired position. Match output is realized: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$, determined by the underlying pairing $(i, j)$ even though $i$ deals only with the broker.
4. **The broker captures the match output $q_{ij}$** and charges the demander $\psi$ (the principal-mode fee). The broker's per-period profit is $\psi + q_{ij} - r$, which can be negative when $q_{ij} < r - \psi$.
5. **Neither party observes the other's type.** The demander observes $q_{ij}$ (it experiences the outcome of using the acquired position) but not $\mathbf{x}_j$ (it does not know whose position the broker acquired). The counterparty does not observe $\mathbf{x}_i$ or $q_{ij}$ — it sold its position to the broker without knowing the end use. Neither party can update its prediction history, because histories require (type, outcome) pairs (§2a).
6. **No edge is added to $G$ between $i$ and $j$.** The parties are unaware of each other's existence. The structural hole between them remains open.
7. **The broker adds $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$.** The broker is the only agent that learns from principal-mode matches.

The counterparty $j$, having sold its position to the broker, is unavailable for other matches during this period. If the broker repeatedly acquires positions from the same high-value agents, those agents are effectively monopolized — available to the market only through the broker. Self-searchers are left with a thinner, lower-quality pool.

#### 13c. Counterparty participation

The broker acquires the counterparty's position at a price of $r$ (the outside option). From the counterparty's perspective, this is a straightforward sale: the counterparty receives $r$ regardless of how the broker uses the acquired position. Acceptance is automatic — the counterparty receives at least its outside option and bears no risk.

The broker absorbs the inventory risk. The broker's per-period cash flow on a principal-mode match is $\psi + q_{ij} - r$: it charges the demander $\psi$, captures the match output from the acquired position, and has already paid $r$ to the counterparty. When the broker's predictions are accurate, it acquires positions that produce high match output, and $q_{ij}$ is reliably above $r$, yielding positive margins. When predictions are noisy (early in the transition), $q_{ij}$ can fall below $r$, and the broker absorbs the shortfall. This inventory risk is a defining property of capture — the broker is acting as a principal, bearing risk that the acquired position will generate sufficient value.

#### 13d. Broker's decision: transparent vs. principal

Each time the broker fills a match for demander $i$ with counterparty $j$, it compares expected profit from transparent placement against principal mode:

$$\Pi^{\text{transparent}} = \phi$$

$$\Pi^{\text{principal}} = \psi + \hat{q}_b(\mathbf{x}_i, \mathbf{x}_j) - r$$

where $\phi$ is the one-time placement fee (§3c), $\psi$ is the per-period principal-mode fee (§13e), and $\hat{q}_b$ is the broker's predicted match quality. Under transparent placement, the broker earns only the fee. In principal mode, the broker acquires the counterparty's position, captures the match output, and earns the principal-mode fee. Both quantities are evaluated per period (at $\tau = 1$, each match lasts one period).

The broker chooses principal mode when $\psi + \hat{q}_b - r > \phi$. This is a purely economic comparison with no prediction confidence threshold. Early in the simulation, the broker's predictions are inaccurate, so $\hat{q}_b$ for selected candidates tends to be moderate and the expected margin $\hat{q}_b - r$ is small or uncertain. As predictions improve, the broker reliably identifies high-value positions where $\hat{q}_b \gg r$, making principal mode increasingly profitable.

The capture dynamic relies on informational dependency and supply scarcity rather than long-duration lock-in (see §13f for the full feedback mechanism).

#### 13e. Principal-mode fee

The principal-mode fee $\psi$ is fixed per period per match, parallel to the placement fee $\phi$ (§3c). The broker competes on match quality at a fixed price in both modes, isolating the informational channel.

The calibration follows the same logic as $\phi$ (§11b): $\psi = \alpha_\psi \cdot \bar{q}_{\text{pub}}$, where $\alpha_\psi = 0.10$ (default). This ensures the principal-mode fee is modest relative to match value: the broker's profit comes primarily from capturing $q_{ij}$ (the match output), not from the fee. The fee must be low enough that the demander's satisfaction ($\hat{q}_b - \psi$) remains competitive with self-search satisfaction.

Under principal mode, the demander experiences the match outcome $q_{ij}$ (it uses the acquired position) but does not observe $\mathbf{x}_j$ (it does not know whose position the broker acquired). The demander pays $\psi$ for the broker's service. The demander's satisfaction input is $q_{\text{realized}} - \psi$, grounded in the actual experienced outcome. For comparison, under transparent placement the input is $q_{\text{realized}} - \phi$, and under self-search it is $q_{\text{realized}}$ (§6a). The informational lock-in is preserved: the demander cannot update its prediction model (it lacks the counterparty type needed for a history entry), even though it observes the match outcome.

#### 13f. Lock-in dynamics

Resource capture produces a **triple lock-in**:

**Informational lock-in.** Neither party observes the other's type. Prediction histories do not grow. Ridge regression models cannot be refitted on new data. The agent's prediction quality stagnates at whatever level it had reached before entering principal-mode matching.

**Structural lock-in.** No direct tie forms between $i$ and $j$ in $G$. The network does not densify from principal-mode matches. Structural holes between agents remain open. The broker's betweenness centrality does not decline from these matches.

**Supply-side lock-in.** Agents whose positions are repeatedly acquired by the broker are effectively removed from the open market during those periods. Self-searchers face a thinner candidate pool, degrading the quality of self-search outcomes and pushing more agents toward the broker. This supply scarcity reinforces the information lock-in.

**Positive feedback loop.** Principal-mode matching prevents agent learning and thins the open market → agent's self-search quality stagnates or declines → agent's self-search satisfaction falls below broker satisfaction → agent continues outsourcing → broker earns $\psi$ per period, continues learning, and acquires more positions → broker's predictions improve and its inventory expands → more matches are profitable in principal mode → more agents locked in, more positions acquired.

This feedback loop is self-reinforcing once initiated, producing the abrupt capture trajectory predicted by Proposition 3a. The self-liquidating dynamic of structural advantage is suspended: because principal-mode matches create no direct ties between agents, the broker's structural position stops eroding.

#### 13g. Illustrative domains

Under resource capture, the broker transitions from connecting agents to taking one side of the match — acquiring a counterparty's position or resource and reselling it, with the broker bearing inventory risk.

**Interdealer brokerage.** The broker transitions from voice intermediation to principal trading. Instead of finding a counterparty for a dealer's trade, the broker takes the other side itself — buying a position from one dealer and selling it to another. The broker warehouses the position and earns the bid-ask spread. Neither dealer knows who is on the other side; both deal with the broker. This is the well-documented transition of IDBs to principal-trading platforms.

**JV / alliance brokerage.** The broker transitions from advisory to principal investing. Instead of connecting two firms for a partnership, the broker acquires capabilities or assets from one firm (investing in or acquiring it) and deploys them in combination with another firm's needs. The broker assembles a portfolio of complementary capabilities and manages their deployment. This is the transition from management consultancy to private equity.

**Collector networks.** The dealer transitions from pure intermediation to holding inventory. Instead of connecting a seller with a buyer, the dealer buys the piece outright — acquiring the seller's holding — and later sells it to a buyer. The dealer bears the risk that the piece may not find a suitable buyer at a profitable price. This is the standard transition from consignment dealer to gallery or wine merchant.

**Import-export trading companies.** The trading company transitions from pure intermediation to taking principal positions. Instead of connecting a producer with a buyer, the company buys goods from the producer — acquiring the supply position — and resells to the buyer. The company bears inventory and price risk: the goods may not find a buyer at a profitable price, or market conditions may shift between acquisition and resale. This is the canonical trajectory of trading houses that evolve from brokers to merchants to vertically integrated conglomerates.

#### 13h. Channel comparison

| | Base (no capture) | Resource capture (principal) | Data capture (§14) |
|---|---|---|---|
| Who matches? | Agent matches directly | Broker takes one side | Agent matches directly |
| Agent observes counterparty type? | Yes | No (deals with broker) | Yes |
| Agent's prediction model improves? | Yes | No | Yes |
| Whose predictions guide selection? | Agent's own | Broker's | Broker's (sold to agent) |
| Direct tie forms? | Yes | No | Yes |
| Structural erosion? | Continues | Suspended | Continues |
| Supply scarcity? | No | Yes (broker acquires positions) | No |
| Broker bears inventory risk? | No | Yes | No |
| Broker revenue | Per-match fee $\phi$ | Per-period fee $\psi$ + match output | Per-period subscription $\mu$ |
| Broker learns from match? | Yes | Yes | No (agent matched directly) |
| Predicted trajectory | Self-liquidating | Abrupt capture (Prop 3a) | Gradual capture (Prop 3b) |

The two capture modes differ on every dimension. Under resource capture, the broker becomes a principal — acquiring positions, bearing risk, and preventing clients from learning or forming direct ties. Under data capture, the broker *sells* its informational advantage — licensing predictions while clients continue matching directly, learning, and forming ties. These are two ways of monetizing the same informational asset: by exploiting it privately or by licensing it.

A subtle asymmetry in learning dynamics: under resource capture, the broker keeps learning (it observes both types in every principal-mode match). Under data capture, the broker's learning *slows* because agents match directly and the broker does not observe those outcomes unless a reporting mechanism exists. This creates a natural ceiling on data capture that resource capture does not face, and may contribute to the gradual-vs-abrupt distinction.

#### 13i. Pseudocode modifications

Steps not listed are identical to the base model pseudocode (§9).

<small>

> **2. CANDIDATE EVALUATION** (principal-mode branch added)
>
> &emsp;**2.3. Broker proposals** (unchanged from base):
> 2.3.1–2.3.5: as in §9.
>
> &emsp;**2.4. Broker mode selection** (new):
> 2.4.1. &emsp;for each proposed brokered match $(i, j)$:
> &emsp;&emsp;Compute $\Pi^{\text{transparent}} = \phi$
> &emsp;&emsp;Compute $\Pi^{\text{principal}} = \psi + \hat{q}_b(\mathbf{x}_i, \mathbf{x}_j) - r$
> &emsp;&emsp;If $\Pi^{\text{principal}} > \Pi^{\text{transparent}}$: mark match as principal
> &emsp;&emsp;Else: mark match as transparent
>
> **3. MATCH FORMATION** (principal-mode branch added)
>
> &emsp;**3.1. Sequential acceptance** (as in base, §9 Step 3, with principal-mode additions):
> 3.1.1. &emsp;Shuffle all proposals (transparent and principal-mode) into random order.
> 3.1.2. &emsp;For each proposed match $(i, j)$ in order:
> &emsp;&emsp;If $j$ already matched this period: skip.
> &emsp;&emsp;**If transparent:** counterparty $j$ evaluates as in base.
> &emsp;&emsp;**If principal mode:** broker acquires $j$'s position at price $r$ (automatic acceptance). Mark $j$ as matched. Demander's participation constraint was applied by the broker during allocation ($\hat{q}_b > r$, §9 Step 2.3.4).

> **4. OUTCOME REALIZATION AND LEARNING** (principal-mode branch added)
>
> 4.1. &emsp;for each accepted match $(i, j)$:
> &emsp;&emsp;Realize output: $q_{ij} = Q + f(\mathbf{x}_i, \mathbf{x}_j) + \varepsilon_{ij}$
> &emsp;&emsp;**If transparent** (self-search or transparent brokered):
> &emsp;&emsp;&emsp;Add $(\mathbf{x}_j, q_{ij})$ to $\mathcal{H}_i$ (demander's history)
> &emsp;&emsp;&emsp;Add $(\mathbf{x}_i, q_{ij})$ to $\mathcal{H}_j$ (counterparty's history)
> &emsp;&emsp;&emsp;If brokered: add $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$
> &emsp;&emsp;&emsp;Add edge $(i, j)$ to $G$
> &emsp;&emsp;**If principal mode:**
> &emsp;&emsp;&emsp;Agent histories $\mathcal{H}_i$ and $\mathcal{H}_j$ are **not** updated (neither party observes the other's type; demander dealt with broker, counterparty sold position to broker)
> &emsp;&emsp;&emsp;Add $(\mathbf{x}_i, \mathbf{x}_j, q_{ij})$ to $\mathcal{H}_b$ (broker observes both types)
> &emsp;&emsp;&emsp;**No edge** added to $G$ between $i$ and $j$
>
> 4.2. &emsp;Update satisfaction indices:
> &emsp;&emsp;for each agent that completed a match via channel $c$:
> &emsp;&emsp;&emsp;If self-search: $\tilde{q} = q_{ij}$
> &emsp;&emsp;&emsp;If transparent brokered: $\tilde{q} = q_{ij} - \phi$
> &emsp;&emsp;&emsp;If principal mode (demander): $\tilde{q} = q_{ij} - \psi$ &ensp;(demander observes outcome but not counterparty type)
> &emsp;&emsp;&emsp;$s_{i,c}^{t+1} = (1 - \omega)\, s_{i,c}^t + \omega \cdot \tilde{q}$
> &emsp;&emsp;No-match penalty: unchanged (§6a).
>
> 4.3. &emsp;Broker accounting (principal-mode matches):
> &emsp;&emsp;for each accepted principal-mode match $(i, j)$:
> &emsp;&emsp;&emsp;Broker revenue: $\psi$ (from demander) $+ \; q_{ij}$ (match output from acquired position)
> &emsp;&emsp;&emsp;Broker cost: $r$ (paid to counterparty for position)
> &emsp;&emsp;&emsp;Broker profit: $\psi + q_{ij} - r$

</small>

#### 13j. Model 1 performance measures

**Principal-mode share** $P^t$: the fraction of brokered matches in period $t$ that are principal-mode (versus transparent placement). This is the primary capture metric. Proposition 3a predicts an abrupt tipping point: $P^t$ should remain near zero while the broker builds its informational advantage, then jump sharply to near one as principal mode becomes economically dominant.

**Agent prediction quality by principal-mode exposure.** Average holdout $R^2$ stratified by agents' cumulative principal-mode match fraction. Agents with high exposure should show stagnating prediction quality (informational lock-in), while agents who primarily self-search or receive transparent placements should continue improving.

**Broker inventory risk.** The frequency and magnitude of matches where $q_{ij} < r$ (the broker's acquired position underperforms the price paid). Early in the capture transition, when predictions are less accurate, losses should be more frequent. As predictions improve, losses should decline. Persistent losses would indicate that the broker is transitioning to principal mode too early.

**Supply scarcity.** The fraction of agents whose positions are acquired by the broker in each period, and the resulting impact on self-search candidate pool sizes. Under capture, self-searchers face a shrinking pool of available counterparties.

---

## Part IV. Outstanding Design Choices

The following design choices are deferred for future work. They are described at a conceptual level to guide subsequent development.

### 14. Data Capture (Model 2)

Under data capture (Proposition 3b), the broker sells access to its prediction model as a per-period subscription service. Subscribing agents use the broker's model for their self-search while continuing to match directly, learn from outcomes, and form ties. The broker earns per-period subscription revenue $\mu$ rather than per-match fees.

Data capture produces the gradual trajectory of Proposition 3b: agents keep learning and forming ties, structural erosion continues, and the broker's advantage narrows as subscribers improve their own predictions using the broker's model. The channel comparison table in §13h summarizes the contrast with resource capture.

**Open design questions:**

**Does the broker observe outcomes of subscriber-directed matches?** If not, the broker's learning slows under data capture — subscribers use the broker's model to find better matches, but the broker doesn't see the outcomes. This creates a natural ceiling: the broker's model improves only from its own brokered matches (which decline as subscribers self-search more effectively), while subscribers' models improve from both their own matches and the broker's predictions. If the broker does observe outcomes (e.g., through a reporting requirement in the subscription contract), the ceiling disappears and data capture dynamics change.

**Does subscription replace or supplement the agent's own model?** If the subscription replaces the agent's model entirely, the agent becomes dependent on the broker's predictions and its own model atrophies. If the subscription supplements (e.g., the agent uses the better of its own prediction and the broker's), the agent's model continues to improve alongside the broker's. The replacement version is simpler and produces stronger capture dynamics; the supplement version is more realistic.

**Can subscribers also use the broker for standard placement simultaneously?** If yes, the broker can earn revenue from both subscription fees and placement fees, and subscribers benefit from both better predictions and access to the broker's roster. If no, subscription and brokerage are mutually exclusive channels.

### 15. Alternative Resource Capture Mechanisms

Two alternatives to the principal-mode mechanism (§13) are noted for future exploration.

#### 15a. Exclusive contracts without information lock-in

Agents sign exclusive contracts with the broker for $L$ periods but still observe counterparty types and form direct ties. Lock-in is contractual, not informational: the agent's prediction model and network continue to improve, but it cannot switch to self-search during the contract.

This variant serves as a **comparison case**: if capture is weaker without information lock-in, it demonstrates that the informational channel (not the contractual restriction) drives the abrupt capture dynamics of Proposition 3a.

#### 15b. Partial obfuscation

The broker reveals noisy or partial type information: $\tilde{\mathbf{x}}_j = \mathbf{x}_j + \boldsymbol{\zeta}$, where $\boldsymbol{\zeta} \sim N(0, \sigma_{\text{obf}}^2 \mathbf{I}_d)$. The agent can update its history with $(\tilde{\mathbf{x}}_j, q_{ij})$, but the noisy type degrades the quality of its ridge regression. At $\sigma_{\text{obf}} = 0$, this is standard transparent brokerage; at $\sigma_{\text{obf}} \to \infty$, this approaches the full information lock-in of principal mode.

This variant provides a continuous lock-in parameter that can be swept, serving as a **robustness check**: does the capture result survive when the information freeze is partial rather than total? The theoretical prediction is that capture requires sufficiently strong obfuscation but is not knife-edge — there should be a threshold $\sigma_{\text{obf}}^*$ above which capture dynamics emerge.

### 16. Prediction Confidence Tracking

The current model does not track prediction confidence. The broker's decision to switch from transparent placement to principal mode is purely economic (§13d): the broker operates in principal mode whenever $\psi + \hat{q}_b - r > \phi$, regardless of how confident it is in its match quality predictions.

A richer model could track prediction confidence — for example, posterior variance from Bayesian linear regression, or leave-one-out cross-validation error from ridge regression — and condition the transition on a confidence threshold. The broker would only take principal positions when it is confident enough in its predictions to bear the inventory risk.

This would produce a more natural transition: the broker waits until it "knows enough" before assuming principal risk. It would also connect to the literature on expert confidence and market-making readiness. Deferred because it adds complexity to the learning model (§2) and requires choosing between several confidence metrics, each with different computational and interpretive properties.

### 17. Pricing Alternatives

The base model uses a fixed per-match fee $\phi$ and Model 1 uses a fixed per-period fee $\psi$. Two alternative pricing mechanisms are noted for future exploration.

**Surplus-proportional fee.** $\phi = \alpha \cdot \hat{q}_b(\mathbf{x}_i, \mathbf{x}_j)$. The broker charges a fraction of its predicted match quality. This creates a recognition gap: the broker's revenue depends on its own prediction, while the agent's satisfaction depends on realized quality. Better predictions increase broker revenue, strengthening the incentive to invest in prediction accuracy.

**Prediction-based fee.** $\phi = \alpha \cdot (\hat{q}_b - \hat{q}_i^d)$. The broker charges for the prediction improvement it provides over the agent's own model. This directly prices the informational advantage but requires the broker to know (or estimate) the agent's prediction quality.

Both alternatives create richer dynamics but add parameters and complicate the satisfaction comparison between channels. The fixed-fee design isolates the informational channel by removing price as a margin of competition.

### 18. Other Design Choices

**Turnover elimination.** Setting $\eta = 0$ (no agent turnover) simplifies the model and produces monotonic structural erosion without the refresh from new entrants. This is the cleanest setting for demonstrating the self-liquidating dynamic but may produce dynamics that converge too quickly. Could be tested as a robustness check.

**Roster decay.** Inactive roster members (agents who have not outsourced in the last $L$ periods) could be pruned from the roster. This would prevent the roster from growing indefinitely and create a more realistic model of broker-client relationships. The tradeoff is additional complexity and a new parameter $L$.

**Exclusivity under principal mode.** The base Model 1 uses per-slot independence: principal-mode matches consume one capacity slot, and other slots remain available for self-search. An alternative is full exclusivity ($\xi = 1$): an agent with any principal-mode match cannot self-search at all during that period, routing all demand through the broker. This produces total information freeze (the agent gains no new observations from any source) and stronger lock-in. This matters primarily at $\tau > 1$ with $K > 1$, when agents accumulate multiple active matches and the question of whether principal-mode matches block self-search on other slots has behavioral content. At $\tau = 1$, agents generate at most one demand per period and the distinction is moot. Comparing dynamics under per-slot independence and full exclusivity would test whether the full information freeze is necessary for the abrupt capture trajectory of Proposition 3a.

## Figures

#### Phase diagram

The phase diagram maps the conditions under which the broker develops a sustained informational advantage and transitions to capture. Its two axes are the primary drivers of matching difficulty: $s$ (active dimensions) on the vertical axis and $\rho$ (quality-interaction mixing weight) on the horizontal axis.

Low complexity (low $s$, high $\rho$) corresponds to markets where agents learn quickly and the broker does not develop a decisive advantage. High complexity (high $s$, low $\rho$) corresponds to markets where the broker's cross-market data provides a durable advantage, enabling capture.

#### Main figures

**Fig. 1.** The informational mechanism.
- *Purpose:* Establishes the core mechanism: the broker learns faster than individual agents, the gap widens with matching complexity, and this drives increasing outsourcing (Propositions 1.1, 1.2, 1.3).
- *Content:* All panels at default parameters ($s = 8$, $\rho = 0.50$). Each panel includes a **base model** series (dashed grey) as a no-capture reference line, plus Model 1 series.
  - Panel A: time on the horizontal axis, prediction quality (holdout $R^2$, rolling window) on the vertical axis. One line for the broker, one for the average agent. The broker-agent gap reflects the informational advantage and its dynamics over time. An inset shows the effect of varying $s$.
  - Panel B: time on the horizontal axis, outsourcing rate on the vertical axis. The base model establishes the reference trajectory. Model 1 diverges.
  - Panel C: time on the horizontal axis, average realized match output by channel (self-search, transparent brokered, principal mode).

**Fig. 2.** Decoupling of structural position from informational advantage.
- *Purpose:* The central empirical implication. Shows that betweenness centrality declines while the broker's informational advantage grows, and that resource capture suspends the structural erosion (Propositions 2.1, 3a).
- *Content:* Time on the horizontal axis, dual vertical axes for broker betweenness centrality and broker prediction quality. Under Model 1, betweenness plateaus or recovers once principal mode dominates.

**Fig. 3.** Access vs. assessment decomposition over time.
- *Purpose:* Traces the shift from network access to information assessment as the dominant source of broker value (Propositions 1.3a, 1.3b).
- *Content:* Time on the horizontal axis, fraction of brokered matches on the vertical axis, decomposed into access value (counterparty was not in demander's network) and assessment value (counterparty was reachable but broker predicted better).

**Fig. 4.** Capture dynamics and the lock-in mechanism.
- *Purpose:* Shows that capture occurs and the lock-in mechanism explains why resource capture is abrupt and self-reinforcing (Proposition 3a).
- *Content:*
  - Panel A: time on the horizontal axis, principal-mode share $P^t$ on the vertical axis. Shows the abrupt tipping point as the broker shifts from transparent placement to principal mode.
  - Panel B: time on the horizontal axis, average agent prediction quality on the vertical axis, stratified by principal-mode exposure (high vs. low). Broker-dependent agents stagnate; others continue improving. Panel A shows the outcome; Panel B shows the mechanism.

**Fig. 5.** Phase diagram.
- *Purpose:* Maps the conditions under which capture occurs, identifying regions of no capture, partial capture, and full capture as a function of matching complexity (Proposition 2.2).
- *Content:* $\rho$ on the horizontal axis, $s$ on the vertical axis. Heatmap or contour plot showing the broker-agent prediction quality gap (or principal-mode share at steady state) across the parameter space.

#### SI figures

**Fig. S1.** Prediction quality decomposition.
- *Content:* Three sub-panels: $R^2$, bias, and rank correlation over time (broker and average agent). Under Model 1, agent lines stratified by principal-mode exposure.

**Fig. S2.** Attributional vs. relational channel (Proposition 1.2).
- *Content:* $\rho$ on horizontal axis; broker-agent gap in holdout $R^2$; outsourcing rate at steady state.

**Fig. S3.** OAT parameter sweeps.
- *Content:* Grid of panels varying $\eta$, $\psi$, $\tau$, $K$ while holding others at defaults.

**Fig. S4.** Network visualization snapshots.
- *Content:* Augmented graph at early, middle, and late periods. Broker node positioned centrally. Under Model 1, late-period graph should show persistent structural holes between agents matched through the broker's principal mode.

**Fig. S5.** Broker risk profile.
- *Purpose:* Shows the frequency and magnitude of inventory losses the broker absorbs in principal mode.
- *Content:* Time on the horizontal axis, distribution of $q_{ij} - r$ for principal-mode matches. Early: wider distribution with more losses. Late: concentrated in positive territory as predictions improve.

## References

Bethune, Z., Sultanum, B., & Trachter, N. (2024). An information-based theory of financial intermediation. *Review of Economic Studies*, *91*(3), 1424–1454.

Brenner, T. (2006). Agent learning representation: Advice on modelling economic learning. In K. Judd & L. Tesfatsion (Eds.), *Handbook of computational economics* (Vol. 2, pp. 895–947). North-Holland.

Burt, R. S. (1992). *Structural holes: The social structure of competition*. Harvard University Press.

Burt, R. S. (2005). *Brokerage and closure: An introduction to social capital*. Oxford University Press.

Duffie, D., Gârleanu, N., & Pedersen, L. H. (2005). Over-the-counter markets. *Econometrica*, *73*(6), 1815–1847.

Freeman, L. C. (1977). A set of measures of centrality based on betweenness. *Sociometry*, *40*(1), 35–41.

Li, D. D. (1998). Middlemen and private information. *Journal of Monetary Economics*, *42*(1), 131–159.

Watts, D. J., & Strogatz, S. H. (1998). Collective dynamics of 'small-world' networks. *Nature*, *393*(6684), 440–442.
