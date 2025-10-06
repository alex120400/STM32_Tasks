*** Settings ***
Resource            ${RENODEKEYWORDS}

Suite Setup         Setup
Suite Teardown      Teardown
Test Teardown       Test Teardown


*** Variables ***
${desired_freq}                 {{FRQ}}
${desired_duty_cycle}           {{DUTY}}
${desired_pin}                  {{PIN}}
${desired_tim_channel}          {{TIM_CHANNEL}}
${simulation_cycles}            {{SIMCYCLES}}
${percentage_tolerance}         1


*** Test Cases ***
Test for correct implementation
    [Tags]    sels
    [Documentation]          Checks relevant Registers for correct values

    Create Nucleo Board

    Execute Command          pause
    Execute Command          emulation RunFor "5"

    # switches have fixed hardware constraints for their GPIO configuration
    ${SW_GPIO_Clock_Enabled}=    Execute Command    rcc ReadDoubleWord 20
    Verify Register Value        ${SW_GPIO_Clock_Enabled}    ${17}    ${3}    ${3}    "Switches' GPIO clocks are not enabled!"

    ${SW1_GPIO_mode}=            Execute Command    gpioPortA ReadDoubleWord 0
    Verify Register Value        ${SW1_GPIO_mode}    ${20}    ${3}    ${0}    "SW1 is not configured as Input!"

    ${SW1_GPIO_pull}=            Execute Command    gpioPortA ReadDoubleWord 12
    Verify Register Value        ${SW1_GPIO_pull}    ${20}    ${3}    ${0}    "SW1 should not have internal Pull-up/Pull-down resistors!"

    ${SW2_GPIO_mode}=            Execute Command    gpioPortB ReadDoubleWord 0
    Verify Register Value        ${SW2_GPIO_mode}    ${6}    ${3}    ${0}    "SW2 is not configured as Input!"

    ${SW2_GPIO_pull}=            Execute Command    gpioPortB ReadDoubleWord 12
    Verify Register Value        ${SW2_GPIO_pull}    ${6}    ${3}    ${0}    "SW2 should not have internal Pull-up/Pull-down resistors!"


    # LED is randomized
    ${LED_GPIO_Clock_Enabled}=   Execute Command    rcc ReadDoubleWord {{GPIO_clk_en_reg_offset}}
    Verify Register Value        ${LED_GPIO_Clock_Enabled}    ${ {{GPIO_clk_en_bit_shift}} }    ${ {{GPIO_clk_en_mask}} }    ${ {{GPIO_clk_en_comp_val}} }    "Switches' GPIO clocks are not enabled!"

    ${LED_GPIO_mode}=            Execute Command    {{GPIO_PORT}} ReadDoubleWord {{GPIO_mode_reg_offset}}
    Verify Register Value        ${LED_GPIO_mode}    ${ {{GPIO_mode_bit_shift}} }    ${ {{GPIO_mode_mask}} }    ${ {{GPIO_mode_comp_val}} }    "GPIOx PINy is not configured as Output!"

    ${LED_GPIO_outputType}=      Execute Command    {{GPIO_PORT}} ReadDoubleWord {{GPIO_outputType_reg_offset}}
    Verify Register Value        ${LED_GPIO_outputType}    ${ {{GPIO_outputType_bit_shift}} }    ${ {{GPIO_outputType_mask}} }    ${ {{GPIO_outputType_comp_val}} }    "GPIOx PINy is not configured as Push/Pull!"

    ${LED_GPIO_pull}=            Execute Command    {{GPIO_PORT}} ReadDoubleWord {{GPIO_pull_reg_offset}}
    Verify Register Value        ${LED_GPIO_pull}    ${ {{GPIO_pull_bit_shift}} }    ${ {{GPIO_pull_mask}} }    ${ {{GPIO_pull_comp_val}} }    "GPIOx PINy should not have internal Pull-up/Pull-down resistors!"

    # renode val - shift - mask - com_val
    # EXTI & SYSCFG configuration is partly randomized
    ${SYSCFG_Clock_Enabled}=    Execute Command    rcc ReadDoubleWord 24
    Verify Register Value       ${SYSCFG_Clock_Enabled}    ${0}    ${1}    ${1}    "SYSCFG's clock is not enabled!"

    ${SYSCFG_EXTI_conn}=        Execute Command     syscfg ReadDoubleWord 16
    Verify Register Value       ${SYSCFG_EXTI_conn}    ${8}    ${7}    ${0}    "SYSCFG's EXTI connection is not configured correctly!"

    ${EXTI_IT_Setting}=         Execute Command    exti ReadDoubleWord 0
    Verify Register Value       ${EXTI_IT_Setting}    ${10}    ${1}    ${1}    "EXTI is not configured for Interrupt generation!"

    ${EXTI_Edge_Setting}=       Execute Command    exti ReadDoubleWord 12
    Verify Register Value       ${EXTI_Edge_Setting}    ${10}    ${1}    ${1}    "EXTI is not configured to trigger an Interrupt at the Falling Edge of the Input signal!"




Test for correct behaviour
    [Tags]    sels
    [Documentation]          Checks if the button presses work correctly
    Create Nucleo Board
    Start Emulation

    ${led_state}=       Return LED State
    Should Not Be True    ${led_state}    msg="The LED must be off initially!" 

    ${other_sw_state}=    Return SW State    gpioPortB.SW2
    Should Not Be True    ${other_sw_state}
    Execute Command     gpioPortA.SW1 Press
    Execute Command     gpioPortA.SW1 Release
    ${led_state}=       Return LED State
    Should Be True      ${led_state}    msg="The LED did not turn on after pressing SW1!"

    Execute Command     gpioPortB.SW2 Press
    Execute Command     gpioPortA.SW1 Press
    Execute Command     gpioPortA.SW1 Release
    ${led_state}=       Return LED State
    Should Not Be True    ${led_state}    msg="The LED did not turn off after pressing SW1 and holding the other!"


Test for IRQ
    [Tags]    sels
    [Documentation]          Checks if the button push triggers the interrupt request

    Create Nucleo Board
    Execute Command     sysbus.cpu LogFunctionNames true "EXTI15_10_IRQHandler"
    Create Log Tester   ${1.0}
    
    Start Emulation
    Execute Command     gpioPortA.SW1 Press
    Wait For Expected Log      .*Entering function EXTI15_10_IRQHandler.*     ${0.5}    # .* is wildcard matching anything
            





*** Keywords ***
Create Nucleo Board
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_RCC.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_EXTI.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_UART.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_FlashController.cs

    Execute Command    $bin = @${CURDIR}/build/stm32-exti_led.elf

    Execute Command    using sysbus
    Execute Command    mach create "STM32F334R8-Nucleo"
    Execute Command    machine LoadPlatformDescription @${CURDIR}/renode/renode_stm32f3/stm32f334R8_nucleo.repl

    Execute Command     machine LoadPlatformDescriptionFromString "LED: Miscellaneous.LED @ {{GPIO_PORT}} {{GPIO_PIN}}"
    Execute Command     machine LoadPlatformDescriptionFromString "{{GPIO_PORT}}: { {{GPIO_PIN}} -> LED@0 }"

    Execute Command    sysbus LoadELF $bin

    #syscfg: Miscellaneous.STM32_SYSCFG @ sysbus 0x40010000

Wait For Expected Log
    [Arguments]    ${pattern}    ${timeout}
    
    # Run Keyword And Return Status returns True if successful or False if test fails
    ${STATUS}=    Run Keyword And Return Status    Wait For Log Entry    ${pattern}    timeout=${timeout}    treatAsRegex=True
    
    # Check the status
    IF    ${STATUS} == False
        # Custom Failure Message: If the log was not found, fail the test with our custom, clear message.
        Fail    The expected log entry for the IRQ handler was NOT found. Check if the button press triggered the IRQ correctly.
    END

Verify Register Value
    [Arguments]            ${renode_value}    ${bit_shift}    ${bit_mask}    ${compare_value}    ${err_msg}
    ${reg_value}=      Convert to Integer    ${renode_value}
    ${reg_shifted_masked}    Evaluate    (${reg_value}>>${bit_shift})&${bit_mask}
    Should Be Equal              ${reg_shifted_masked}    ${compare_value}    msg = ${err_msg}

Return LED State
    sleep                100milliseconds    # very important as simulation apparently needs some time to really activate the LED
    ${loc_led_state}=    Execute Command    {{GPIO_PORT}}.LED State
    ${loc_led_state}=    Remove String    ${loc_led_state}    \n
    ${loc_led_state}=    Convert To Boolean    ${loc_led_state}
    [Return]    ${loc_led_state}

Return SW State
    [Arguments]        ${sw}
    sleep                100milliseconds    # very important as simulation apparently needs some time to act
    ${loc_sw_state}=    Execute Command    ${sw} Pressed
    ${loc_sw_state}=    Remove String    ${loc_sw_state}    \n
    ${loc_sw_state}=    Convert To Boolean    ${loc_sw_state}
