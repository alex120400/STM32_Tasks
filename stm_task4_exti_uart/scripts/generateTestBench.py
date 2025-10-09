#!/usr/bin/env python3

########################################################################
# generateTestBench.py for STM32 task exti uart
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
# commented pins and timers are combinations not available (yet) in renode
hardware_dict = {"SW1-PA10": dict(),
                 "SW2-PB3": dict()
                }

hardware_dict["SW1-PA10"].update({"MAIN_SW_PORT": "gpioPortA",
                                  "MAIN_SW": "SW1",

                                  "SECONDARY_SW_PORT": "gpioPortB",
                                  "SECONDARY_SW": "SW2",

                                  "IRQ_function_name": "EXTI15_10_IRQHandler",

                                  "SYSCFG_EXTI_conn_reg_offset": "16",
                                  "SYSCFG_EXTI_conn_bit_shift": "8", "SYSCFG_EXTI_conn_mask": "7", "SYSCFG_EXTI_conn_comp_val": "0",

                                  "EXTI_IT_reg_offset": "0",
                                  "EXTI_IT_bit_shift": "10", "EXTI_IT_mask": "1", "EXTI_IT_comp_val": "1",

                                  "EXTI_Edge_reg_offset": "12",
                                  "EXTI_Edge_bit_shift": "10", "EXTI_Edge_mask": "1", "EXTI_Edge_comp_val": "1",
                                })

hardware_dict["SW2-PB3"].update({"MAIN_SW_PORT": "gpioPortB",
                                 "MAIN_SW": "SW2",

                                 "SECONDARY_SW_PORT": "gpioPortA",
                                 "SECONDARY_SW": "SW1",

                                 "IRQ_function_name": "EXTI3_IRQHandler",

                                 "SYSCFG_EXTI_conn_reg_offset": "8",
                                 "SYSCFG_EXTI_conn_bit_shift": "12", "SYSCFG_EXTI_conn_mask": "7", "SYSCFG_EXTI_conn_comp_val": "1",

                                 "EXTI_IT_reg_offset": "0",
                                 "EXTI_IT_bit_shift": "3", "EXTI_IT_mask": "1", "EXTI_IT_comp_val": "1",

                                 "EXTI_Edge_reg_offset": "12",
                                 "EXTI_Edge_bit_shift": "3", "EXTI_Edge_mask": "1", "EXTI_Edge_comp_val": "1",
                                })




#################################################################

taskParameters = sys.argv[1].strip().split("#") # order is: char, switch
chosen_small_char = taskParameters[0]
SWITCH_key = taskParameters[1]
random_tag = sys.argv[2]
params = {}


#########################################
# SET PARAMETERS FOR TESTBENCH TEMPLATE #
#########################################
params.update({"SMALL_CHAR": chosen_small_char})
params.update(hardware_dict[SWITCH_key])
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
