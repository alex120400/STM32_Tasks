#!/usr/bin/env python3

########################################################################
# generateTask.py for STM32 task exti led
# Generates random tasks, generates TaskParameters
#
# Copyright (C) 2015 Martin  Mosbeck   <martin.mosbeck@gmx.at>
# Copyright (C) 2025 Alexander Dvorak   <alexander120400@gmail.com>
# License GPL V2 or later (see http://www.gnu.org/licenses/gpl2.txt)
########################################################################

import random
import sys

from jinja2 import FileSystemLoader, Environment
#################################################################

userId=sys.argv[1]
taskNr=sys.argv[2]
submissionEmail=sys.argv[3]
language=sys.argv[4]

paramsDesc={}

# for task one, a led and a switch mussed be picked

# available pins and switches
led_switch_combinations =  [("PA5", "SW1-PA10"), # einzel-blau, user LED
                             ("PA6", "SW1-PA10"), # einzel-rot
                             ("PA7", "SW1-PA10"), # rgb rot
                             ("PC7", "SW1-PA10"), # rgb grün

                             ("PA5", "SW2-PB3"), # einzel-blau, user LED
                             ("PA6", "SW2-PB3"), # einzel-rot
                             ("PA7", "SW2-PB3"), # rgb rot
                             ("PC7", "SW2-PB3"), # rgb grün
                             #("PB6", "") # rgb blau, not testable via renode as N channels are not implemented
                            ]

tmp = led_switch_combinations[random.randrange(len(led_switch_combinations))] # random pin chosen and switch
chosen_led = tmp[0]
chosen_switch = tmp[1]


##############################
## PARAMETER SPECIFYING TASK##
##############################
taskParameters= f"{chosen_led}#{chosen_switch}"

############### ONLY FOR TESTING #######################
filename ="tmp/solution_{0}_Task{1}.txt".format(userId,taskNr)
with open (filename, "w") as solution:
    solution.write("Chosen TaskParameters:\n")
    for text, param in zip(["LED on PIN:", "Switch-PIN:"], taskParameters.split("#")):
        solution.write(f"{text}\t{param}\n")


###########################################
# SET PARAMETERS FOR DESCRIPTION TEMPLATE #
###########################################
# PIN led
# SW  switch
paramsDesc.update({"PIN":chosen_led, "SW":chosen_switch})
paramsDesc.update({"TASKNR":str(taskNr),"SUBMISSIONEMAIL":submissionEmail})

#############################
# FILL DESCRIPTION TEMPLATE #
#############################
env = Environment()
env.loader = FileSystemLoader('templates/')
filename ="task_description/task_description_template_{0}.tex".format(language)
template = env.get_template(filename)
template = template.render(paramsDesc)

filename ="tmp/desc_{0}_Task{1}.tex".format(userId,taskNr)
with open (filename, "w") as output_file:
    output_file.write(template)

###########################
### PRINT TASKPARAMETERS ##
###########################
print(taskParameters)   # "returns" task parameters to give it on to taskBench generator 
