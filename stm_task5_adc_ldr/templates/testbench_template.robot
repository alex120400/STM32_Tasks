*** Settings ***
Resource            ${RENODEKEYWORDS}

Suite Setup         Setup
Suite Teardown      Teardown
Test Teardown       Test Teardown


*** Test Cases ***
Test for correct implementation
    [Tags]    sels
    [Documentation]          Checks relevant Registers for correct values

    Create Nucleo Board

    Execute Command          pause
    Execute Command          emulation RunFor "5"

    # ADC hardware is constrained for itself and its GPIO configuration
    ${ADC_LDR_Clock_Enabled}=    Execute Command    rcc ReadDoubleWord 20
    Verify Register Value        ${ADC_LDR_Clock_Enabled}    ${17}    ${2049}    ${2049}    "The ADC1/2's and/or the LDR-GPIO' clock is not enabled!"
    
    ${ADC_Status}=               Execute Command    adc ReadDoubleWord 0    # adc should be ready by now
    Verify register Value        ${ADC_Status}    ${0}    ${1}    ${1}    "The ADC is not enabled!"

    ${ADC_Control}=              Execute Command    adc ReadDoubleWord 8
    Verify register Value        ${ADC_Control}    ${0}    ${2952790019}    ${268435457}    "ADC seems to be still not calibrated after 5s, that should be possible faster... lets say within 500ms ;)"

    ${ADC_Conf}=                 Execute Command    adc ReadDoubleWord 12
    Verify register Value        ${ADC_Conf}    ${3}    ${9735}    ${512}    "Data is either not right alligned, resolution is wrong, ovr-mode is wrong or the conversion mode is wrong!"

    ${ADC_SAMP}=                 Execute Command    adc ReadDoubleWord 20    # ldr hangs at channel 2
    Verify register Value        ${ADC_SAMP}    ${6}    ${7}    ${0}    "ADC sampling cycles are wrong configured!"

    ${ADC_SQR1}=                 Execute Command    adc ReadDoubleWord 48    # only channel two in regular sequence
    Verify register Value        ${ADC_SQR1}    ${0}    ${1999}    ${128}    "ADC is not configured for one conversion in the regular sequence list or with the wrong channel!"

    ${ADC_CCR}=                  Execute Command    adc ReadDoubleWord 776    # only channel two in regular sequence
    Verify register Value        ${ADC_CCR}    ${0}    ${196639}    ${65536}    "ADC's clock is not configured as synchronous with 1 as prescaler or not in independent mode!"

# renode val - shift - mask - com_val

    # LDR is also hardware fixed: PA1
    ${LDR_GPIO_mode}=            Execute Command    gpioPortA ReadDoubleWord 0
    Verify Register Value        ${LDR_GPIO_mode}    ${2}    ${3}    ${3}    "LDR-GPIO PIN is not configured as Analog!"

    ${LDR_GPIO_pull}=            Execute Command    gpioPortA ReadDoubleWord 12
    Verify Register Value        ${LDR_GPIO_pull}    ${2}    ${3}    ${0}    "LDR-GPIO PIN should not have internal Pull-up/Pull-down resistors!"

    # LED is randomized
    ${LED_GPIO_Clock_Enabled}=   Execute Command    rcc ReadDoubleWord {{GPIO_clk_en_reg_offset}}
    Verify Register Value        ${LED_GPIO_Clock_Enabled}    ${ {{GPIO_clk_en_bit_shift}} }    ${ {{GPIO_clk_en_mask}} }    ${ {{GPIO_clk_en_comp_val}} }    "The LED's GPIO clock is not enabled!"

    ${LED_GPIO_mode}=            Execute Command    {{GPIO_PORT}} ReadDoubleWord {{GPIO_mode_reg_offset}}
    Verify Register Value        ${LED_GPIO_mode}    ${ {{GPIO_mode_bit_shift}} }    ${ {{GPIO_mode_mask}} }    ${ {{GPIO_mode_comp_val}} }    "The LED's GPIO PIN is not configured as output!"

    ${LED_GPIO_pull}=            Execute Command    {{GPIO_PORT}} ReadDoubleWord {{GPIO_pull_reg_offset}}
    Verify Register Value        ${LED_GPIO_pull}    ${ {{GPIO_pull_bit_shift}} }    ${ {{GPIO_pull_mask}} }    ${ {{GPIO_pull_comp_val}} }    "The LED's GPIO PIN should not have internal Pull-up/Pull-down resistors!"

    ${LED_GPIO_outputType}=      Execute Command    {{GPIO_PORT}} ReadDoubleWord {{GPIO_outputType_reg_offset}}
    Verify Register Value        ${LED_GPIO_outputType}    ${ {{GPIO_outputType_bit_shift}} }    ${ {{GPIO_outputType_mask}} }    ${ {{GPIO_outputType_comp_val}} }    "The LED's GPIO PIN is not configured as Push/Pull!"

    # Timer configuration is partly randomized
    ${TIM_Clock_Enabled}=       Execute Command    sysbus.rcc ReadDoubleWord {{TIM_clk_en_reg_offset}}
    Verify Register Value        ${TIM_Clock_Enabled}    ${ {{TIM_clk_en_bit_shift}} }    ${ {{TIM_clk_en_mask}} }    ${ {{TIM_clk_en_comp_val}} }    "The TIMx's clock is not enabled!"

    ${TIM_Control1}=            Execute Command    sysbus.timer{{TIM}} ReadDoubleWord {{TIM_control1_reg_offset}}
    Verify Register Value        ${TIM_Control1}    ${ {{TIM_control1_bit_shift}} }    ${ {{TIM_control1_mask}} }    ${ {{TIM_control1_comp_val}} }    "Either counter not enabled or direction of counter is wrong!"

    ${TIM_ISREN}=               Execute Command    sysbus.timer{{TIM}} ReadDoubleWord {{TIM_ISREN_reg_offset}}
    Verify Register Value        ${TIM_ISREN}    ${ {{TIM_ISREN_bit_shift}} }    ${ {{TIM_ISREN_mask}} }    ${ {{TIM_ISREN_comp_val}} }    "The Update-Interrupt is not enabled!"
    
    # check sampling frequency
    ${prescaler}=    Execute Command    sysbus.timer{{TIM}} ReadDoubleWord {{PRESCALER_reg_offset}}
    ${prescaler}=    Convert to Integer    ${prescaler}
    ${auto_reload}=    Execute Command    sysbus.timer{{TIM}} ReadDoubleWord {{ARR_reg_offset}}
    ${auto_reload}=    Convert to Integer    ${auto_reload}
    ${actual_frequency}=    Evaluate    ${64000000} / (${prescaler} + 1) / (${auto_reload} + 1)
    ${expected_frequency}=    Convert To Number    2
    Should Be Equal Within Range    ${expected_frequency}  ${actual_frequency}  ${0.00001}  "Wrong Timer Frequency. Expected: ${expected_frequency} vs Acutal: ${actual_frequency}"



Test for IRQ and correct behaviour
    [Tags]    sels
    [Documentation]          Checks if the IRQ, which is used to synchronize adc-value-change and behaviour, is called and changes the LED State

    Create Nucleo Board
    
    # provide adc with high value (>500), order is: channel, mV, repetitions, 0.8mV is 1 bit in adc dr
    # pauseEmulation=True, timeout=${1.4}    

    Execute Command          pause
    Execute Command          adc SetDefaultValue 3300 2         # maximum Voltage, room's light is on
    Create Log Tester        ${5.0}        # log wait statements should stop at the maximum of 5 seconds in virtual time
    Execute Command          start

    # wait for the first conversion to finish and pause simulation
    Wait For Expected Log    ADC conversion finished    
    #${currentTime}=          Execute Command    currentTime
    ${led_state}=            Return LED State
    Should Not Be True       ${led_state}    msg="The LED must be off if light shines on the LDR!"

    # turn of the light
    Execute Command          adc SetDefaultValue 495 2         # room's light is dimmed to trigger the LED
    sleep                    1
    Wait For Expected Log    ADC conversion finished
    ${led_state}=            Return LED State
    #${currentTime}=          Execute Command    currentTime
    Should Be True           ${led_state}    msg="The LED did not turn on in the dark!"


    # increase light a little
    Execute Command          adc SetDefaultValue 505 2         # room's light is dimmed to trigger the LED
    sleep                    1
    Wait For Expected Log    ADC conversion finished
    ${led_state}=            Return LED State
    #${currentTime}=          Execute Command    currentTime
    Should Not Be True       ${led_state}    msg="The LED was not turned off again if light shined on the LDR!"
            


*** Keywords ***
Create Nucleo Board
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_RCC.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_EXTI.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_UART.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_FlashController.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_Timers.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_ADC_Common.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F334R8_ADC.cs

    Execute Command    $bin = @${CURDIR}/build/stm32-adc_ldr.elf

    Execute Command    using sysbus
    Execute Command    mach create "STM32F334R8-Nucleo"
    Execute Command    machine LoadPlatformDescription @${CURDIR}/renode/renode_stm32f3/stm32f334R8_nucleo.repl

    Execute Command     machine LoadPlatformDescriptionFromString "LED: Miscellaneous.LED @ {{GPIO_PORT}} {{GPIO_PIN}}"
    Execute Command     machine LoadPlatformDescriptionFromString "{{GPIO_PORT}}: { {{GPIO_PIN}} -> LED@0 }"

    Execute Command     cpu AddHookAtInterruptEnd "monitor.Parse(\\"log 'ADC conversion finished' 1\\")"


    Execute Command    sysbus LoadELF $bin

Wait For Expected Log
    [Arguments]    ${pattern}
    
    # Run Keyword And Return Status returns True if successful or False if test fails
    ${STATUS}=    Run Keyword And Return Status    Wait For Log Entry    ${pattern}    treatAsRegex=False
    
    # Check the status
    IF    ${STATUS} == False
        # Custom Failure Message: If the log was not found, fail the test with our custom, clear message.
        Fail    The expected log entry for the IRQ handler was NOT found. Are you using the Timer-Update-Interrupt to manage ADC-Conversions?
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

Should Be Equal Within Range
    [Arguments]              ${value0}  ${value1}  ${range}  ${msg}

    ${diff}=                 Evaluate  abs(${value0} - ${value1})

    Should Be True           ${diff} <= ${range}  msg=${msg}
