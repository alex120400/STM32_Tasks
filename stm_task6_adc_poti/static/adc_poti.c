/* Task 6: ADC POTI

In this task, your goal is to utilize the ADC1, which is connected
to the POTI on our Extension Board Board, measure its voltage drop
and transmit the value over UART.

Put relevant code for setting up the peripherals in their respective functions and
put code to start relevant peripherals at the respective position in the code below
Use the timer update interrupt for polling the ADC conversion
(start it, wait, act on result)

Hint: You could use the timer also for calibrating the adc, but without interrupt routine

Good Luck!

*/

#include "stm32f3xx_ll_rcc.h"
#include "stm32f3xx_ll_bus.h"
#include "stm32f3xx_ll_system.h"
#include "stm32f3xx_ll_utils.h"
#include "stm32f3xx_ll_tim.h"
#include "stm32f3xx_ll_gpio.h"
#include "stm32f3xx_ll_adc.h"
#include "stm32f3xx_ll_usart.h"
#include <stdint.h>
#include <stdio.h>


void SystemClock_Config(void);
static void GPIO_Init(void);
static void ADC1_Init(void);
static void TIM_Init(void);
static void UART2_Init(void);
// implement the respective interupt service routine using one of the following function headers
//void TIM2_IRQHandler(void);
//void TIM3_IRQHandler(void);
//void TIM1_UP_TIM16_IRQHandler(void);
//void TIM1_TRG_COM_TIM17_IRQHandler(void)


int main(void)
{
  /* System interrupt init*/
  uint32_t priority_grouping = 5;
  NVIC_SetPriorityGrouping(priority_grouping);

  SystemClock_Config(); // Configure the system clock

  GPIO_Init(); // initializes GPIO
  TIM_Init(); // initializes Timer
  UART2_Init(); // initializes UART
  ADC1_Init();

  /* put further relevant code for starting peripherals here*/

  while (1)
  {

  }
}

/** GPIO Initialization Function
 * put here all code relevant to the gpio configuration
*/
static void GPIO_Init(void)
{
  
}

/** TIM Initialization Function
 * put here all code relevant to the timer configuration
*/
static void TIM_Init(void)
{
  
}


/**
  * ADC1 Initialization Function
  * configure it here and also calibrate it! Start conversions in the timer update interrupt
*/
static void ADC1_Init(void)
{
  
}


/** USART2 Initialization Function
  * put here all code relevant to the UART2 configuration
*/
static void UART2_Init(void)
{
  
}


/** Interrupt Service Routine
  * implement down below the Interrupt service routine with one of the names exactly as stated at the beginning
*/
//void TIM2_IRQHandler(void)
// {
  
// }

// void TIM3_IRQHandler(void)
// {

// }

// void TIM1_UP_TIM16_IRQHandler(void)
// {

// }

// void TIM1_TRG_COM_TIM17_IRQHandler(void)
// {

// }



/* System Clock Configuration, do not change code here, CPU frequency is 64 MHz */
void SystemClock_Config(void)
{
  LL_FLASH_SetLatency(LL_FLASH_LATENCY_2);
  while(LL_FLASH_GetLatency()!= LL_FLASH_LATENCY_2)
  {
  }
  LL_RCC_HSI_Enable();

   /* Wait till HSI is ready */
  while(LL_RCC_HSI_IsReady() != 1)
  {

  }
  LL_RCC_HSI_SetCalibTrimming(16);
  LL_RCC_PLL_ConfigDomain_SYS(LL_RCC_PLLSOURCE_HSI_DIV_2, LL_RCC_PLL_MUL_16);
  LL_RCC_PLL_Enable();

   /* Wait till PLL is ready */
  while(LL_RCC_PLL_IsReady() != 1)
  {

  }
  LL_RCC_SetAHBPrescaler(LL_RCC_SYSCLK_DIV_1);
  LL_RCC_SetAPB1Prescaler(LL_RCC_APB1_DIV_2);
  LL_RCC_SetAPB2Prescaler(LL_RCC_APB2_DIV_1);
  LL_RCC_SetSysClkSource(LL_RCC_SYS_CLKSOURCE_PLL);

   /* Wait till System clock is ready */
  while(LL_RCC_GetSysClkSource() != LL_RCC_SYS_CLKSOURCE_STATUS_PLL)
  {

  }
  LL_Init1msTick(64000000);
  LL_SetSystemCoreClock(64000000);
}
