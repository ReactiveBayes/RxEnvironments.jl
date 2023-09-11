# [Design Philosophy](@id lib-design-philosophy)

`RxEnvironments` is designed with [Active Inference](https://doi.org/10.1007/s00422-010-0364-z) in mind. The philosophy behind Active Inference is different from classical control or reinforcement learning, and may even seem confusing if one is well-versed in either control or reinforcement learning. However, as explained on this page, the Active Inference philosophy gives us many advantages by design, such as multi-agent environments, compositional environments and nested environments. This page aims to clarify the design principles of `RxEnvironments`. 

## Agent-Environment interaction

Classical reinforcement learning literature often makes the explicit distinction between an agent and the environment in which it lives. The interaction between agents and environments flows through the [Markov Blanket](https://en.wikipedia.org/wiki/Markov_blanket) of the agent; the agent emits actions and receives sensory observations. Similarly, the environment receives actions and emits observations to the agent. This symmetry of the Markov Blanket of both the agent and environment is crucial to notice: The actions of the agent are the observations of the environment, and vice versa. Consequently, one can argue that the environment is also an agent, which communicates to the agent through its Markov Blanket.

## Entities and Markov Blankets
The observation in the previous paragraph calls for an overarching term for both agents and environments. `RxEnvironments` realizes this with the `AbstractEntity` type. An entity is anything that has a Markov Blanket and can therefore communicate with other entities. Both agents and environments are `AbstractEntity`'s under the hood. The difference is that an environment should implement the `update!` function to encode the state transition, whereas in agents this should be replaced by an inference process that selects an action to perform. We do not explicitly funnel rewards back from environments to agents, instead, agents should interpret the observations it receives and attach value to them instead.

## The power of Markov Blankets

All logic of `RxEnvironments` is written on the `Entity` level, this means that all logic holds for both agents and environments. For example: The fact that we support multi-agent environments also implies that an agent could emit actions to multiple environments as well, or that an agent can communicate with other agents in the same environment through its Markov Blanket. The concept of an `Entity` is what makes `RxEnvironments` so powerful and versatile. 

