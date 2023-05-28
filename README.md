# TetrisAI

#### __TetrisAI Documentation__
| Recent |
|:-------:|
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://docs.tetrisaitrainer.com)

TetrisAI is an open source Julia framework that implements and interfaces the classic Tetris game to train and test intelligent agents in. The environment is true to the Tetris NES implementation except that it has a little more information on the next pieces.

Since the framework is 100% written in Julia, in can be used by anyone to train different kinds of models in their own code and its use is simple. The original intent behind this development was to test reinforcement learning techniques, but contributions to this repository can introduce more algorithms and even different ones. For instance, only DQN and PPO were implemented in this project, but a handful of other algorithms remain to be tested. See the [contribution ideas](#contribution-ideas) section below for more information on future work.

## Quick start

> You might encounter a problem with too much open files when using the GUI of the framework. This is a known issue that's caused by the underlying GameZero.jl package that's used for displaying the GUI. The issue was fixed, but the package wasn't redeployed since the fix. So you might need to clone the GameZero.jl repository and use the cloned version of the package which is up-to-date. 

### Develop/use the package itself
1. [Download and install Julia](https://julialang.org/downloads/). Please refer to the official documentation. You should be able to do `julia` in your terminal and see a new Julia interactive session start.
2. Clone the TetrisAI repository
``` bash
# Using SSH Keys (recommended)
git clone git@github.com:leochartrand/TetrisAI.jl.git
# Using HTTP
git clone https://github.com/leochartrand/TetrisAI.jl.git
```
3. Change into the project's directory.
``` bash
cd TetrisAI.jl
```
4. Open a julia interactive session from the current directory and activate the current directory as the activated package in Julia's package manager. Then, precompile the package.
``` bash
# 1 - Open interactive session
julia
# 2 - Enter Julia package manager by pressing "]"

# 3 - Activate the current directory in the package manager.
activate .

# 4 - Precompile the package
precompile
```

5. You can exit the package manager and start using the TetrisAI framework in your current interactive session. The importation process of the TetrisAI module might take a few seconds.
```Julia
# 1 - Exit the package manager by pressing the RETURN button.

# 2 - Include/Import the TetrisAI package
using TetrisAI

# 3 - Start using the package, for example:
agent = DQNAgent()
train_agent(agent, N=100)
```

## Contribution Ideas
- [ ] Heuristic search exploration implementation (i.e. MTCS) or path planning algorithms to find the best sequence of movements from where the piece is to the desired place.
- [ ] Possibly improve the training time for DQN & PPO.
- [ ] Benchmark the models on a dedicated server to better assess the performance of the algorithms in the environment.
- [ ] Pre-train the algorithms using the provided dataset.
- [ ] Implement unit tests.
- [ ] Deploy the framework to make it usable from the Julia package manager.
- [ ] Fine-tune and deploy the documentation with Documenter.jl.
- [ ] Implement a CI-CD pipeline.

