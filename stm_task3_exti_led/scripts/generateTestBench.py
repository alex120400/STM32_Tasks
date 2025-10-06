#!/usr/bin/env python3

########################################################################
# generateTestBench.py for STM32 task pwm
# Generates testvectors and fills a testbench for specified taskParameters
#
# Copyright (C) 2015 Martin  Mosbeck   <martin.mosbeck@gmx.at>
# License GPL V2 or later (see http://www.gnu.org/licenses/gpl2.txt)
########################################################################

import sys
import random

from jinja2 import FileSystemLoader, Environment


##################### Hardware Information ######################
# commented pins and timers are combinations not available (yet) in renode
hardware_dict = {"PA5": dict(),
                 "PA6": dict(),
                 "PA7": dict(),
                 #"PB6": dict(),
                 "PC7": dict()
                }

hardware_dict["PA5"].update({"GPIO_PORT": "gpioPortA",  # all values verified
                             "GPIO_PIN": "5",

                             "GPIO_clk_en_reg_offset": "20", 
                             "GPIO_clk_en_bit_shift": "17", "GPIO_clk_en_mask": "1", "GPIO_clk_en_comp_val": "1",

                             "GPIO_mode_reg_offset": "0",
                             "GPIO_mode_bit_shift": "10", "GPIO_mode_mask": "3", "GPIO_mode_comp_val": "1",
                             
                             "GPIO_outputType_reg_offset": "4",
                             "GPIO_outputType_bit_shift": "5", "GPIO_outputType_mask": "1", "GPIO_outputType_comp_val": "0",

                             "GPIO_pull_reg_offset": "12",
                             "GPIO_pull_bit_shift": "10", "GPIO_pull_mask": "3", "GPIO_pull_comp_val": "0",
                             })

hardware_dict["PA6"].update({"GPIO_PORT": "gpioPortA",  # all values verified
                             "GPIO_PIN": "6",

                             "GPIO_clk_en_reg_offset": "20", 
                             "GPIO_clk_en_bit_shift": "17", "GPIO_clk_en_mask": "1", "GPIO_clk_en_comp_val": "1",

                             "GPIO_mode_reg_offset": "0",
                             "GPIO_mode_bit_shift": "12", "GPIO_mode_mask": "3", "GPIO_mode_comp_val": "1",
                             
                             "GPIO_outputType_reg_offset": "4",
                             "GPIO_outputType_bit_shift": "6", "GPIO_outputType_mask": "1", "GPIO_outputType_comp_val": "0",
                             
                             "GPIO_pull_reg_offset": "12",
                             "GPIO_pull_bit_shift": "12", "GPIO_pull_mask": "3", "GPIO_pull_comp_val": "0",
                             })

hardware_dict["PA7"].update({"GPIO_PORT": "gpioPortA",  # all values verified
                             "GPIO_PIN": "7",

                             "GPIO_clk_en_reg_offset": "20", 
                             "GPIO_clk_en_bit_shift": "17", "GPIO_clk_en_mask": "1", "GPIO_clk_en_comp_val": "1",

                             "GPIO_mode_reg_offset": "0",
                             "GPIO_mode_bit_shift": "14", "GPIO_mode_mask": "3", "GPIO_mode_comp_val": "1",

                             "GPIO_outputType_reg_offset": "4",
                             "GPIO_outputType_bit_shift": "7", "GPIO_outputType_mask": "1", "GPIO_outputType_comp_val": "0",
                             
                             "GPIO_pull_reg_offset": "12",
                             "GPIO_pull_bit_shift": "14", "GPIO_pull_mask": "3", "GPIO_pull_comp_val": "0",
                             })

# hardware_dict["PB6"].update({"GPIO_PORT": "gpioPortB",  # all values verified
#                              "GPIO_PIN": "6",

#                              "GPIO_clk_en_reg_offset": "20", 
#                              "GPIO_clk_en_bit_shift": "18", "GPIO_clk_en_mask": "1", "GPIO_clk_en_comp_val": "1",

#                              "GPIO_mode_reg_offset": "0",
#                              "GPIO_mode_bit_shift": "12", "GPIO_mode_mask": "3", "GPIO_mode_comp_val": "2",
#                              })

hardware_dict["PC7"].update({"GPIO_PORT": "gpioPortC",  # all values verified
                             "GPIO_PIN": "7",

                             "GPIO_clk_en_reg_offset": "20", 
                             "GPIO_clk_en_bit_shift": "19", "GPIO_clk_en_mask": "1", "GPIO_clk_en_comp_val": "1",

                             "GPIO_mode_reg_offset": "0",
                             "GPIO_mode_bit_shift": "14", "GPIO_mode_mask": "3", "GPIO_mode_comp_val": "1",

                             "GPIO_outputType_reg_offset": "4",
                             "GPIO_outputType_bit_shift": "7", "GPIO_outputType_mask": "1", "GPIO_outputType_comp_val": "0",
                             
                             "GPIO_pull_reg_offset": "12",
                             "GPIO_pull_bit_shift": "14", "GPIO_pull_mask": "3", "GPIO_pull_comp_val": "0",
                             })






#################################################################

taskParameters = sys.argv[1].strip().split("#") # order is: frq(in Hz), duty(in %), pin, tim/channel
GPIO_key = taskParameters[2]
TIM_CHANNEL_key = taskParameters[3]
random_tag = sys.argv[2]
params = {}

simCycles = random.randrange(5, 30)
# periodClks = taskParameters >> 18
# dutyClks = taskParameters & (2**18 - 1)

#########################################
# SET PARAMETERS FOR TESTBENCH TEMPLATE #
#########################################
params.update(
    {
        "random_tag": random_tag,
        "FRQ": taskParameters[0],
        "DUTY": taskParameters[1],
        "PIN": taskParameters[2],
        "TIM_CHANNEL": taskParameters[3],
        "SIMCYCLES": simCycles,
    }
)

params.update(hardware_dict[GPIO_key])
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
