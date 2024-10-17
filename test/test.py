# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

async def apply_reset(dut, num_cycles=2):
    """Applies reset for a specified number of clock cycles."""
    dut._log.info("Applying reset")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, num_cycles)
    dut.rst_n.value = 1
    dut._log.info("Reset released")

async def send_byte(dut, byte, serial_clock_period):
    """Sends a byte over MOSI, simulating the SPI behavior."""
    dut._log.info(f"Sending byte: {byte:02X}")
    await ClockCycles(dut.uio_in[3], 1)
    await ClockCycles(dut.clk, 10) #1/4 serial_clk_period
    dut.uio_in[0].value = 0  # SS = 0, activate
    for i in range(8):
        dut.uio_in[1].value = (byte >> (7 - i)) & 1  # Set MOSI bit
        await ClockCycles(dut.uio_in[3], 1)
    dut.uio_in[0].value = 1  # SS = 1, deactivate
    await ClockCycles(dut.clk, 10)#1/4 serial_clk_period
    await ClockCycles(dut.clk, 20)#1/2 serial_clk_period

async def wait_cycles(dut, num_cycles):
    """Waits for a specified number of clock cycles."""
    dut._log.info(f"Waiting for {num_cycles} cycles")
    await ClockCycles(dut.uio_in[3], num_cycles)


async def execute_instr(dut, address_msb, address_lsb, instruction, data_byte, serial_clock_period):
    """Executes an instruction by sending a sequence of bytes."""
    await send_byte(dut, address_msb, serial_clock_period)
    await wait_cycles(dut, 2)
    await send_byte(dut, address_lsb, serial_clock_period)
    await wait_cycles(dut, 2)
    await send_byte(dut, instruction, serial_clock_period)
    await wait_cycles(dut, 2)
    await send_byte(dut, data_byte, serial_clock_period)
    await wait_cycles(dut, 2)

async def write_input_spikes(dut, input_spikes, serial_clock_period):
    """Writes a 24-bit input spike data to the memory."""
    for i in range(3):
        byte = (input_spikes >> (8 * (2 - i))) & 0xFF
        await execute_instr(dut, 0x00, i, 0x07, byte, serial_clock_period)
        await wait_cycles(dut, 1)

async def write_parameters(dut, decay, refractory_period, threshold, div_value, delays, debug_config_in, serial_clock_period):
    """Writes network parameters to the memory."""
    await execute_instr(dut, 0x00, 0x03, 0x01, decay, serial_clock_period)
    await wait_cycles(dut, 1)
    await execute_instr(dut, 0x00, 0x04, 0x01, refractory_period, serial_clock_period)
    await wait_cycles(dut, 1)
    await execute_instr(dut, 0x00, 0x05, 0x01, threshold, serial_clock_period)
    await wait_cycles(dut, 1)
    await execute_instr(dut, 0x00, 0x06, 0x05, div_value, serial_clock_period)
    await wait_cycles(dut, 1)
    await execute_instr(dut, 0x00, 0x67, 0x01, delays, serial_clock_period)
    await wait_cycles(dut, 1)

    for i in range(59, 163):
        await execute_instr(dut, 0x00, i, 0x07, delays, serial_clock_period)
        await wait_cycles(dut, 1)

    await execute_instr(dut, 0x00, 0xA3, 0x09, debug_config_in, serial_clock_period)
    await wait_cycles(dut, 1)

async def write_weights(dut, weight, serial_clock_period):
    """Writes weight values to memory addresses from 0x07 to 0x3A."""
    weight_byte = (weight << 6) | (weight << 4) | (weight << 2) | weight
    for i in range(7, 59):
        await execute_instr(dut, 0x00, i, 0x01, weight_byte, serial_clock_period)
        await wait_cycles(dut, 1)


@cocotb.test()
async def test_project(dut):
    dut._log.info("Starting testbench")
    
    #Inizialization
    dut.ena.value = 1
    dut.ui_in.value = 0 # input_ready=ui_in[0]
    dut.uio_in.value = 0 #MOSI= uio_in[1]
    dut.uio_in[0].value = 1 #SS
    
    
    # Set the clock periods for system and SPI clocks
    serial_clock_period = 1000  # 1 MHz
    system_clock_period = serial_clock_period/40  # 40 MHz


    # Initialize clocks
    system_clock = Clock(dut.clk, system_clock_period, units="ns")
    cocotb.start_soon(system_clock.start())

    serial_clock = Clock(dut.uio_in[3], serial_clock_period, units="ns")
    cocotb.start_soon(serial_clock.start())

    # Apply reset
    await apply_reset(dut)

    # Test case 1: Write 0xA5 into memory at address 0x1234
    dut._log.info("Test case 1: Write 0xA5 to address 0x1234")
    await execute_instr(dut, 0x12, 0x34, 0x01, 0xA5, serial_clock_period)

    # Test case 2: Write 0xFF into memory at address 0x1200
    dut._log.info("Test case 2: Write 0xFF to address 0x1200")
    await execute_instr(dut, 0x12, 0x00, 0x01, 0xFF, serial_clock_period)

    # Test case 3: Write 0xB6 to clk_div register
    dut._log.info("Test case 3: Write 0xB6 to clk_div register")
    await execute_instr(dut, 0x00, 0x06, 0x05, 0xB6, serial_clock_period)
    await wait_cycles(dut, 4)

    # Test case 4: Write input spikes
    dut._log.info("Test case 4: Write input spikes (0xFEDCBA)")
    await write_input_spikes(dut, 0xFEDCBA, serial_clock_period)

    # Test case 5: Write 0xD8 to debug config register
    dut._log.info("Test case 5: Write 0xD8 to debug config register")
    await execute_instr(dut, 0x00, 0xA3, 0x09, 0xD8, serial_clock_period)
    await wait_cycles(dut, 4)

    # Test case 6: Read from memory at 0x4534
    dut._log.info("Test case 6: Read from memory at 0x4534")
    await execute_instr(dut, 0x45, 0x34, 0x00, 0x00, serial_clock_period)
    await wait_cycles(dut, 4)

    # Test case 7: Write to multiple addresses
    dut._log.info("Test case 7: Write sequentially to addresses 0x03 to 0xA2")
    data_byte = 1
    for i in range(3, 163):
        await execute_instr(dut, 0x00, i, 0x01, data_byte, serial_clock_period)
        data_byte = data_byte * 2 if data_byte <= 0x7F else 0x01
        await wait_cycles(dut, 2)

    # Test case 8: Write new clk_div value 0x45
    dut._log.info("Test case 8: Write 0x45 to clk_div register")
    await execute_instr(dut, 0x00, 0x06, 0x05, 0x45, serial_clock_period)
    await wait_cycles(dut, 4)
    
    
    # Test case 9: Write new input spikes
    dut._log.info("Test case 9: Write input spikes (0x654321)")
    await write_input_spikes(dut, 0x654321, serial_clock_period)

    # Test case 10: Update debug config value
    dut._log.info("Test case 10: Write 0xF3 to debug config register")
    await execute_instr(dut, 0x00, 0xA3, 0x09, 0xF3, serial_clock_period)
    await wait_cycles(dut, 4)

    # Test case 11: Write parameters
    dut._log.info("Test case 11: Write parameters")
    await write_parameters(dut, 0x00, 0x00, 0x05, 0x00, 0x00, 0x00, serial_clock_period)

    # Test case 12: Write weights
    dut._log.info("Test case 12: Write weights with 0b00 pattern")
    await write_weights(dut, 0b00, serial_clock_period)
    
    await write_input_spikes(dut, 0xFFFFFF, serial_clock_period)
    
    await wait_cycles(dut, 100)
    
    #Start computation
    dut.ui_in.value = 1 # input_ready=ui_in[0]
    await write_parameters(dut, 0x1F, 0x17, 0x19, 0x03, 0xA9, 0xCB, serial_clock_period)
    await write_weights(dut, 0b10, serial_clock_period)
    await write_input_spikes(dut, 0xFFFFFF, serial_clock_period)
    await wait_cycles(dut, 100)
    dut._log.info("End of testbench")
    await ClockCycles(dut.clk, 1000)
    
    
    
# async def write_input_spikes(dut, input_spikes, serial_clock_period)


    # # Test case 12: Write weights
    # dut._log.info("Test case 12: Write weights with 0b10 pattern")
    # await write_weights(dut, 0b10, serial_clock_period)

    # # End of testing
    # dut._log.info("End of testbench")
    # await ClockCycles(dut.clk, 1000)
