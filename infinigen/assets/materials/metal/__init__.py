# Copyright (C) 2023, Princeton University.
# This source code is licensed under the BSD 3-Clause license found in the LICENSE file in the root directory of this source tree.

# Authors: Lingjie Mei


import numpy as np

import numpy as np

from .aluminum import Aluminum
from .appliance import BlackGlass, BrushedBlackMetal, WhiteMetal
from .brushed_metal import BrushedMetal
from .galvanized_metal import GalvanizedMetal
from .grained_and_polished_metal import GrainedMetal
from .hammered_metal import HammeredMetal
from .metal_basic import MetalBasic
from .mirror import Mirror

import numpy as np
from numpy.random import uniform
from infinigen.core.util.color import hsv2rgba, rgb2hsv, hex2rgb
from infinigen.core.util.random import log_uniform
from infinigen.core.util.random import random_general as rg


from .. import common

def apply(obj, selection=None, metal_color=None, **kwargs):
    color = sample_metal_color(metal_color)
    shader = get_shader()
    common.apply(obj, shader, selection, base_color=color, **kwargs)


def get_shader():
    return np.random.choice(
        [
            brushed_metal.shader_brushed_metal,
            galvanized_metal.shader_galvanized_metal,
            grained_and_polished_metal.shader_grained_metal,
            hammered_metal.shader_hammered_metal,
        ]
    )

plain_colors = (
    "weighted_choice",
    (0.5, 0xFDD017),
    (1, 0xC0C0C0),
    (1, 0x8C7853),
    (0.5, 0xB87333),
    (0.5, 0xB5A642),
    (1, 0xBDBAAE),
    (1, 0xA9ACB6),
    (1, 0xB6AFA9),
)
natural_colors = (
    "weighted_choice",
    (1, 0xC0C0C0),
    (1, 0x8C7853),
    (1, 0xBDBAAE),
    (1, 0xA9ACB6),
    (1, 0xB6AFA9),
)


def sample_metal_color(metal_color=None, **kwargs):
    match metal_color:
        case np.ndarray():
            return metal_color
        case "plain":
            h, s, v = rgb2hsv(hex2rgb(rg(plain_colors))[:-1])
            return hsv2rgba(
                h + uniform(-0.1, 0.1),
                s + uniform(-0.1, 0.1),
                v * log_uniform(0.5, 0.2),
            )
        case "natural":
            h, s, v = rgb2hsv(hex2rgb(rg(natural_colors))[:-1])
            return hsv2rgba(
                h + uniform(-0.1, 0.1),
                s + uniform(-0.1, 0.1),
                v * log_uniform(0.5, 0.2),
            )
        case "bw":
            return hsv2rgba(uniform(0, 1), uniform(0.0, 0.2), log_uniform(0.01, 0.2))
        case "bw+natural":
            return (
                sample_metal_color("bw")
                if uniform() < 0.5
                else sample_metal_color("natural")
            )
        case _:
            if uniform() < 0.2:
                return sample_metal_color("natural")
            return hsv2rgba(uniform(0, 1), uniform(0.3, 0.6), log_uniform(0.02, 0.5))
