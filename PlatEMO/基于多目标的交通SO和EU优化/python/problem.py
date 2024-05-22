import jax
import jax.numpy as jnp
from evox import Problem, State, jit_method
import networkx


# 定义多目标交通SO和EU问题
# transportation state optimization problem

class TSOP(Prolem):
    def __init__(self, G):
        super().__init__()
        self.G = G