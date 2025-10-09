#!/usr/bin/env python3

########################################################################
# generateTask.py for STM32 task exti uart
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

# for this task, a random character and a switch mussed be picked

# available characters and switches
chosen_character = "abcdefghijklmnopqrstuvwxyz"[random.randrange(26)]
chosen_switch = ["SW1-PA10","SW2-PB3"][random.randrange(2)]


##############################
## PARAMETER SPECIFYING TASK##
##############################
taskParameters= f"{chosen_character}#{chosen_switch}"

############### ONLY FOR TESTING #######################
filename ="tmp/solution_{0}_Task{1}.txt".format(userId,taskNr)
with open (filename, "w") as solution:
    solution.write("Chosen TaskParameters:\n")
    for text, param in zip(["Character:", "Switch-PIN:"], taskParameters.split("#")):
        solution.write(f"{text}\t{param}\n")


###########################################
# SET PARAMETERS FOR DESCRIPTION TEMPLATE #
###########################################
# CHAR character
# SW  switch
paramsDesc.update({"CHAR":chosen_character, "SW":chosen_switch})
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
