#!/usr/bin/env python3

########################################################################
# generateTask.py for STM32 task adc poti
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


# available timers
timers = ["TIM2", "TIM3", "TIM16", "TIM17"]

# random pin chosen and timer
chosen_timer = timers[random.randrange(len(timers))]


##############################
## PARAMETER SPECIFYING TASK##
##############################
taskParameters= f"{chosen_timer}"

############### ONLY FOR TESTING #######################
filename ="tmp/solution_{0}_Task{1}.txt".format(userId,taskNr)
with open (filename, "w") as solution:
    solution.write("Chosen TaskParameters:\n")
    solution.write(f"Timer:\t{taskParameters}\n")


###########################################
# SET PARAMETERS FOR DESCRIPTION TEMPLATE #
###########################################
# PIN led
# SW  switch
paramsDesc.update({"TIM":chosen_timer})
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
