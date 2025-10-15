//
// Copyright (c) 2010-2024 Antmicro
//
// This file is licensed under the MIT License.
// Full license text is available in 'licenses/MIT.txt'.
//

using Antmicro.Renode.Core;
using Antmicro.Renode.Peripherals.DMA;

namespace Antmicro.Renode.Peripherals.Analog
{
    public class STM32F334R8_ADC : STM32F3_ADC_Common
    {
        public STM32F334R8_ADC(IMachine machine, double referenceVoltage, uint externalEventFrequency, int dmaChannel = 0, IDMA dmaPeripheral = null)
            : base(
                machine,
                referenceVoltage,
                externalEventFrequency,
                dmaChannel,
                dmaPeripheral,
                // Base class configuration
                watchdogCount: 3,
                hasCalibration: true,
                channelCount: 19,
                hasPrescaler: false, // changed: true -> false
                hasVbatPin: true, // changed: false -> true
                hasChannelSelect: false,
                hasChannelSequence: true,
                hasPowerRegister: false // changed: true -> false
            )
        { }
    }
}