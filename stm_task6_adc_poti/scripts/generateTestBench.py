#!/usr/bin/env python3

########################################################################
# generateTestBench.py for STM32 task adc poti
# Generates testvectors and fills a testbench for specified taskParameters
#
# Copyright (C) 2015 Martin  Mosbeck   <martin.mosbeck@gmx.at>
# Copyright (C) 2025 Alexander Dvorak   <alexander120400@gmail.com>
# License GPL V2 or later (see http://www.gnu.org/licenses/gpl2.txt)
########################################################################

import sys
import random

from jinja2 import FileSystemLoader, Environment


##################### Hardware Information ######################
hardware_dict = {"TIM2": dict(),
                 "TIM3": dict(),
                 "TIM16": dict(),
                 "TIM17": dict()
                }



hardware_dict["TIM2"].update({"TIM": "2",   # all values verified

                                  "PRESCALER_reg_offset": "40",
                                  "ARR_reg_offset": "44",

                                  "TIM_clk_en_reg_offset": "28", 
                                  "TIM_clk_en_bit_shift": "0", "TIM_clk_en_mask": "1", "TIM_clk_en_comp_val": "1",

                                  "TIM_control1_reg_offset": "0",
                                  "TIM_control1_bit_shift": "0", "TIM_control1_mask": "17", "TIM_control1_comp_val": "1",

                                  "TIM_ISREN_reg_offset": "12",
                                  "TIM_ISREN_bit_shift": "0", "TIM_ISREN_mask": "1", "TIM_ISREN_comp_val": "1",
                                  })

hardware_dict["TIM3"].update({"TIM": "3",

                                  "PRESCALER_reg_offset": "40",
                                  "ARR_reg_offset": "44",

                                  "TIM_clk_en_reg_offset": "28", 
                                  "TIM_clk_en_bit_shift": "1", "TIM_clk_en_mask": "1", "TIM_clk_en_comp_val": "1",

                                  "TIM_control1_reg_offset": "0",
                                  "TIM_control1_bit_shift": "0", "TIM_control1_mask": "17", "TIM_control1_comp_val": "1",

                                  "TIM_ISREN_reg_offset": "12",
                                  "TIM_ISREN_bit_shift": "0", "TIM_ISREN_mask": "1", "TIM_ISREN_comp_val": "1",
                                  })

hardware_dict["TIM16"].update({"TIM": "16",

                                  "PRESCALER_reg_offset": "40",
                                  "ARR_reg_offset": "44",

                                  "TIM_clk_en_reg_offset": "24", 
                                  "TIM_clk_en_bit_shift": "17", "TIM_clk_en_mask": "1", "TIM_clk_en_comp_val": "1",

                                  "TIM_control1_reg_offset": "0",
                                  "TIM_control1_bit_shift": "0", "TIM_control1_mask": "1", "TIM_control1_comp_val": "1",

                                  "TIM_ISREN_reg_offset": "12",
                                  "TIM_ISREN_bit_shift": "0", "TIM_ISREN_mask": "1", "TIM_ISREN_comp_val": "1",
                                  })

hardware_dict["TIM17"].update({"TIM": "17",

                                  "PRESCALER_reg_offset": "40",
                                  "ARR_reg_offset": "44",

                                  "TIM_clk_en_reg_offset": "24", 
                                  "TIM_clk_en_bit_shift": "18", "TIM_clk_en_mask": "1", "TIM_clk_en_comp_val": "1",

                                  "TIM_control1_reg_offset": "0",
                                  "TIM_control1_bit_shift": "0", "TIM_control1_mask": "1", "TIM_control1_comp_val": "1",

                                  "TIM_ISREN_reg_offset": "12",
                                  "TIM_ISREN_bit_shift": "0", "TIM_ISREN_mask": "1", "TIM_ISREN_comp_val": "1",
                                  })


#################################################################

TIMER_key = sys.argv[1].strip() # just timer
random_tag = sys.argv[2]
params = {}


#########################################
# SET PARAMETERS FOR TESTBENCH TEMPLATE #
#########################################
params.update(hardware_dict[TIMER_key])
#params.update(hardware_dict[TIM_CHANNEL_key])

###########################
# FILL TESTBENCH TEMPLATE #
###########################
env = Environment()
env.loader = FileSystemLoader("templates/")
filename = "testbench_template.robot"
template = env.get_template(filename)
template = template.render(params)

print(template)
