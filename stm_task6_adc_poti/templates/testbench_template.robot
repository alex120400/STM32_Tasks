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
    ${ADC_POTI_Clock_Enabled}=    Execute Command    rcc ReadDoubleWord 20
    Verify Register Value        ${ADC_POTI_Clock_Enabled}    ${17}    ${2049}    ${2049}    "The ADC1/2's and/or the POTI-GPIO's clock is not enabled!"
    
    ${ADC_Status}=               Execute Command    adc ReadDoubleWord 0    # adc should be ready by now
    Verify register Value        ${ADC_Status}    ${0}    ${1}    ${1}    "The ADC is not enabled!"

    ${ADC_Control}=              Execute Command    adc ReadDoubleWord 8
    Verify register Value        ${ADC_Control}    ${0}    ${2952790019}    ${268435457}    "ADC seems to be still not calibrated after 5s, that should be possible faster... lets say within 500ms ;)"

    ${ADC_Conf}=                 Execute Command    adc ReadDoubleWord 12
    Verify register Value        ${ADC_Conf}    ${3}    ${9735}    ${512}    "Data is either not right alligned, resolution is wrong, ovr-mode is wrong or the conversion mode is wrong!"

    ${ADC_SAMP}=                 Execute Command    adc ReadDoubleWord 20    # poti hangs at channel 1
    Verify register Value        ${ADC_SAMP}    ${3}    ${7}    ${0}    "ADC sampling cycles are wrong configured!"

    ${ADC_SQR1}=                 Execute Command    adc ReadDoubleWord 48    # only channel 1 in regular sequence
    Verify register Value        ${ADC_SQR1}    ${0}    ${1999}    ${64}    "ADC is not configured for one conversion in the regular sequence list or with the wrong channel!"

    ${ADC_CCR}=                  Execute Command    adc ReadDoubleWord 776    # 
    Verify register Value        ${ADC_CCR}    ${0}    ${196639}    ${65536}    "ADC's clock is not configured as synchronous with 1 as prescaler or not in independent mode!"

# renode val - shift - mask - com_val

    # POTI is also hardware fixed: PA0
    ${POTI_GPIO_mode}=            Execute Command    gpioPortA ReadDoubleWord 0
    Verify Register Value        ${POTI_GPIO_mode}    ${0}    ${3}    ${3}    "POTI-GPIO PIN is not configured as Analog!"

    ${POTI_GPIO_pull}=            Execute Command    gpioPortA ReadDoubleWord 12
    Verify Register Value        ${POTI_GPIO_pull}    ${0}    ${3}    ${0}    "POTI-GPIO PIN should not have internal Pull-up/Pull-down resistors!"

    # Uart is fixed
    ${UART2_Clock_Enabled}=    Execute Command    rcc ReadDoubleWord 28
    Verify Register Value      ${UART2_Clock_Enabled}    ${17}    ${1}    ${1}    "UART2's clock is not enabled!"

    ${UART2_CR1}=    Execute Command    sysbus.usart2 ReadDoubleWord 0
    Verify Register Value    ${UART2_CR1}    ${0}    ${268441085}    ${13}    "UART2 is not enabled or not correctly configured!"

    ${UART2_CR2}=    Execute Command    sysbus.usart2 ReadDoubleWord 4
    Verify Register Value    ${UART2_CR2}    ${12}    ${3}    ${0}    "UART2 not configured for 1 stop-bit!" 

    ${UART2_BRR}=    Execute Command    sysbus.usart2 ReadDoubleWord 12
    Verify Register Value    ${UART2_BRR}    ${0}    ${65535}    ${833}    "UART2 is not configured for a Frequency of 38400 Hz" 

    # Timer configuration is randomized
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
    [Documentation]          Checks if the IRQ, which is used to synchronize adc-value-change and behaviour, is called and sends the correct Uart messages

    Create Nucleo Board
    Create Terminal Tester      sysbus.usart2    ${5.0}
    
    # provide adc with high value (>500), order is: channel, mV, repetitions, 0.8mV is 1 bit in adc dr   

    Execute Command          pause
    Execute Command          adc SetDefaultValue 3310 1         # maximum Voltage
    Create Log Tester        ${5.0}        # log wait statements should stop at the maximum of 5 seconds in virtual time
    Execute Command          start

    # wait for the first conversion to finish
    Wait For Expected Log    ADC conversion finished
    Wait For Expected Message    Poti is 3.3V    The returned message(s) did not match the expected pattern or the measured Voltage is wrong!
    #${currentTime}=          Execute Command    currentTime

    # decrease poti to see only the first decimal
    Execute Command          adc SetDefaultValue 410 1
    sleep                    1
    Wait For Expected Log    ADC conversion finished
    Wait For Expected Message    Poti is 0.4V    The returned message(s) did not match the expected pattern or the measured Voltage is wrong!

    # decrease poti further to see 0.0 even though there's a little voltage
    Execute Command          adc SetDefaultValue 50 1
    sleep                    1
    Wait For Expected Log    ADC conversion finished
    Wait For Expected Message    Poti is 0.0V    The returned message(s) did not match the expected pattern or the measured Voltage is wrong!


*** Keywords ***
Create Nucleo Board
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_RCC.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_EXTI.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_UART.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_FlashController.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_Timers.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F3_ADC_Common.cs
    Execute Command    include @${CURDIR}/renode/renode_stm32f3/STM32F334R8_ADC.cs

    Execute Command    $bin = @${CURDIR}/build/stm32-adc_poti.elf

    Execute Command    using sysbus
    Execute Command    mach create "STM32F334R8-Nucleo"
    Execute Command    machine LoadPlatformDescription @${CURDIR}/renode/renode_stm32f3/stm32f334R8_nucleo.repl

    Execute Command     cpu AddHookAtInterruptBegin "monitor.Parse(\\"log 'ADC conversion finished' 1\\")"


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

Wait For Expected Message
    [Arguments]    ${message}    ${err-msg}
    
    # Run Keyword And Return Status returns True if successful or False if test fails
    ${STATUS}=    Run Keyword And Return Status    Wait For Line On Uart    ${message}
    
    # Check the status
    IF    ${STATUS} == False
        # Custom Failure Message: If the line was not found, fail the test with our custom, clear message.
        Fail    ${err-msg}
    END

Verify Register Value
    [Arguments]            ${renode_value}    ${bit_shift}    ${bit_mask}    ${compare_value}    ${err_msg}
    ${reg_value}=      Convert to Integer    ${renode_value}
    ${reg_shifted_masked}    Evaluate    (${reg_value}>>${bit_shift})&${bit_mask}
    Should Be Equal              ${reg_shifted_masked}    ${compare_value}    msg = ${err_msg}


Should Be Equal Within Range
    [Arguments]              ${value0}  ${value1}  ${range}  ${msg}

    ${diff}=                 Evaluate  abs(${value0} - ${value1})

    Should Be True           ${diff} <= ${range}  msg=${msg}
