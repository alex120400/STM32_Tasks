*** Settings ***
Resource            ${RENODEKEYWORDS}

Suite Setup         Setup
Suite Teardown      Teardown
Test Teardown       Test Teardown


*** Variables ***
${small_char}=    {{SMALL_CHAR}}


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


    # Uart is fixed
    ${UART2_Clock_Enabled}=    Execute Command    rcc ReadDoubleWord 28
    Verify Register Value      ${UART2_Clock_Enabled}    ${17}    ${1}    ${1}    "UART2's clock is not enabled!"

    ${UART2_CR1}=    Execute Command    sysbus.usart2 ReadDoubleWord 0
    Verify Register Value    ${UART2_CR1}    ${0}    ${268441085}    ${13}    "UART2 is not enabled or not correctly configured!"

    ${UART2_CR2}=    Execute Command    sysbus.usart2 ReadDoubleWord 4
    Verify Register Value    ${UART2_CR2}    ${12}    ${3}    ${0}    "UART2 not configured for 1 stop-bit!" 

    ${UART2_BRR}=    Execute Command    sysbus.usart2 ReadDoubleWord 12
    Verify Register Value    ${UART2_BRR}    ${0}    ${65535}    ${833}    "UART2 is not configured for a Frequency of 38400 Hz" 

    # ${UART2_}=    Execute Command    sysbus.usart2    ReadDoubleWord
    # Verify Register Value    ${UART2_}    ${}    ${}    ${}    "UART2 ..." 
    
    # renode val - shift - mask - com_val
    # EXTI & SYSCFG configuration is partly randomized
    ${SYSCFG_Clock_Enabled}=    Execute Command    rcc ReadDoubleWord 24
    Verify Register Value       ${SYSCFG_Clock_Enabled}    ${0}    ${1}    ${1}    "SYSCFG's clock is not enabled!"

    ${SYSCFG_EXTI_conn}=        Execute Command     syscfg ReadDoubleWord {{SYSCFG_EXTI_conn_reg_offset}}
    Verify Register Value       ${SYSCFG_EXTI_conn}    ${ {{SYSCFG_EXTI_conn_bit_shift}} }    ${ {{SYSCFG_EXTI_conn_mask}} }    ${ {{SYSCFG_EXTI_conn_comp_val}} }    "SYSCFG's EXTI connection is not configured correctly!"

    ${EXTI_IT_Setting}=         Execute Command    exti ReadDoubleWord {{EXTI_IT_reg_offset}}
    Verify Register Value       ${EXTI_IT_Setting}    ${ {{EXTI_IT_bit_shift}} }    ${ {{EXTI_IT_mask}} }    ${ {{EXTI_IT_comp_val}} }    "EXTI is not configured for Interrupt generation!"

    ${EXTI_Edge_Setting}=       Execute Command    exti ReadDoubleWord {{EXTI_Edge_reg_offset}}
    Verify Register Value       ${EXTI_Edge_Setting}    ${ {{EXTI_Edge_bit_shift}} }    ${ {{EXTI_Edge_mask}} }    ${ {{EXTI_Edge_comp_val}} }    "EXTI is not configured to trigger an Interrupt at the Falling Edge of the Input signal!"




Test for correct behaviour
    [Tags]    sels
    [Documentation]          Checks if the button presses work correctly
    Create Nucleo Board
    Create Terminal Tester      sysbus.usart2
    Start Emulation

    ${big_char}=    Evaluate    "${small_char}".upper()
    # check if Uart is idle
    Test If Uart Is Idle    ${0.2}    
    

    ${other_sw_state}=    Return SW State    {{SECONDARY_SW_PORT}}.{{SECONDARY_SW}}
    Should Not Be True    ${other_sw_state}     msg="{{SECONDARY_SW}} should not be pressed at the beginning!"
    Execute Command     {{MAIN_SW_PORT}}.{{MAIN_SW}} Press
    Execute Command     {{MAIN_SW_PORT}}.{{MAIN_SW}} Release
    # press buttons and check uart msg
    Wait For Expected Char    ${small_char}    ${0.5}    "The expected char ${small_char} was NOT sent via UART2 after pressing {{MAIN_SW}}!"

    Execute Command     {{SECONDARY_SW_PORT}}.{{SECONDARY_SW}} Press
    Execute Command     {{MAIN_SW_PORT}}.{{MAIN_SW}} Press
    Execute Command     {{MAIN_SW_PORT}}.{{MAIN_SW}} Release
    Wait For Expected Char    ${big_char}    ${0.5}    "The expected char ${big_char} was NOT sent via UART2 after pressing {{MAIN_SW}} while holding {{SECONDARY_SW}}!"



Test for IRQ
    [Tags]    sels
    [Documentation]          Checks if the button push triggers the interrupt request

    Create Nucleo Board
    Execute Command     sysbus.cpu LogFunctionNames true "{{IRQ_function_name}}"
    Create Log Tester   ${1.0}
    
    Start Emulation
    Execute Command     {{MAIN_SW_PORT}}.{{MAIN_SW}} Press
    Wait For Expected Log      .*Entering function {{IRQ_function_name}}.*     ${0.5}    # .* is wildcard matching anything
            





*** Keywords ***
Create Nucleo Board
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_RCC.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_EXTI.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_UART.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_FlashController.cs

    Execute Command    $bin = @${CURDIR}/build/stm32-exti_uart.elf

    Execute Command    using sysbus
    Execute Command    mach create "STM32F334R8-Nucleo"
    Execute Command    machine LoadPlatformDescription @${CURDIR}/renode/renode_stm32f3/stm32f334R8_nucleo.repl
    


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


Wait For Expected Char
    [Arguments]    ${char}    ${timeout}    ${msg}
    
    # Run Keyword And Return Status returns True if successful or False if test fails
    ${STATUS}=    Run Keyword And Return Status    Wait For Prompt On Uart    ${char}    timeout=${timeout}   #treatAsRegex=True
    
    # Check the status
    IF    ${STATUS} == False
        # Custom Failure Message: If the line was not found, fail the test with our custom, clear message.
        Fail    ${msg}
    END

Verify Register Value
    [Arguments]            ${renode_value}    ${bit_shift}    ${bit_mask}    ${compare_value}    ${err_msg}
    ${reg_value}=      Convert to Integer    ${renode_value}
    ${reg_shifted_masked}    Evaluate    (${reg_value}>>${bit_shift})&${bit_mask}
    Should Be Equal              ${reg_shifted_masked}    ${compare_value}    msg = ${err_msg}

Return SW State
    [Arguments]        ${sw}
    sleep                100milliseconds    # very important as simulation apparently needs some time to act
    ${loc_sw_state}=    Execute Command    ${sw} Pressed
    ${loc_sw_state}=    Remove String    ${loc_sw_state}    \n
    ${loc_sw_state}=    Convert To Boolean    ${loc_sw_state}
