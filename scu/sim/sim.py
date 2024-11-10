from enum import Enum
from typing import Union

import json

import cocotb
from cocotb.clock import Clock, Timer
from cocotb.triggers import RisingEdge, FallingEdge
from cocotb.types import Logic, LogicArray, Range
from cocotb.handle import Freeze, Release
from cocotb.utils import get_sim_time

def init_signal(dut):
    dut.i_nrst.value = Logic('1')
    dut.i_r_nw.value = Logic('1')
    dut.i_nas.value = Logic('1')
    dut.i_nds.value = Logic('1')
    dut.i_size.value = LogicArray("00")
    dut.i_fc.value = LogicArray("000")
    dut.i_a.value = LogicArray('0' * 32)
    dut.io_d.value = Release()
    dut.i_ncbreq.value = Logic('1')
    
class MC68030:
    class AddressSpace(Enum):
        USER_DATA   = 1
        USER_PROG   = 2
        SUPER_DATA  = 5
        SUPER_PROG  = 6
        CPU_SPACE   = 7
        
    def __init__(self, dut):
        self.dut = dut

    async def reset(self):
        await RisingEdge(self.dut.o_clk)
        init_signal(self.dut)
        self.dut.i_nrst.value = Logic('0')
        
        for i in range(512):
            await FallingEdge(self.dut.o_clk)
            await RisingEdge(self.dut.o_clk)
            
        self.dut.i_nrst.value = Logic('1')
        self.ipl_status = 0
    
    async def read(self, asp: AddressSpace, addr: int, size: int = 0, burst: bool = False) -> dict:
        if size not in [1, 2, 4] and not burst:
            print(f"Invalid operation size: {size}")
            return
        if addr not in range(0, 0x100000000):
            print(f"Invalid address: {hex(addr)}")
            return
        if burst:
            size = 4
        if addr + size - 1 not in range(0, 0x100000000):
            print(f"Invalid address and size: {hex(addr)}, {size}")
            return

        bytes_left = size
        bytes_read = 0
        io_result = {
            "operation": "read",
            "address_space": asp.name,
            "address": addr,
            "burst": burst,
            "cycles": [],
            "start_ns": get_sim_time("ns")
        }
        
        while bytes_left > 0:
            io_cycle_result = {
                "ack_size": 0,
                "sync": False,
                "clocks": 0,
                "wait_states": 0
            }
            
            await RisingEdge(self.dut.o_clk)  # Beginning of S0
            self.dut.io_d.value = Release()
            self.dut.i_a.value = LogicArray(addr + bytes_read, range=Range(31, "downto", 0))
            self.dut.i_fc.value = LogicArray(asp.value, range=Range(2, "downto", 0))
            self.dut.i_r_nw.value = Logic('1')
            self.dut.i_size.value = LogicArray(["01", "10", "11", "00"][bytes_left - 1])
            
            await FallingEdge(self.dut.o_clk)  # Beginning of S1
            self.dut.i_nas.value = Logic('0')
            self.dut.i_nds.value = Logic('0')
            io_cycle_result["clocks"] += 1
            
            if burst and bytes_read == 0:
                self.dut.i_ncbreq.value = Logic('0')
            
            await RisingEdge(self.dut.o_clk)  # Beginning of S2
            
            await FallingEdge(self.dut.o_clk)  # Beginning of S3/wait state
            io_cycle_result["clocks"] += 1
            
            if str(self.dut.o_nsterm.value) == 'Z':  # Wait for acknowledgement
                while str(self.dut.o_ndsack.value) == "ZZ" and str(self.dut.o_nsterm.value) == 'Z':
                    await RisingEdge(self.dut.o_clk)  # wait state
                    await FallingEdge(self.dut.o_clk)  # wait state
                    io_cycle_result["clocks"] += 1
                    io_cycle_result["wait_states"] += 1
                
            if str(self.dut.o_nsterm.value) == '0':  # S3 sync
                io_cycle_result["sync"] = True
                io_cycle_result["ack_size"] = 4
                if not bool(self.dut.o_ncback.value) and bool(self.dut.o_nci.value): # burst
                    io_result["burst"] = True
                    for i in range(4):
                        if bool(self.dut.o_ncback.value) or not bool(self.dut.o_nci.value):
                            break
                        
                        io_cycle_result["address"] = (addr & 0xFFFFFFF0) | (((addr & 0xF) + i) & 0xF)
                        io_cycle_result["data"] = int(self.dut.io_d.value)
                        
                        if i < 3:
                            io_result["cycles"].append(io_cycle_result)
                            io_cycle_result["clocks"] = 0
                            io_cycle_result["wait_states"] = 0
                            
                            # wait for one clock cycle
                            await RisingEdge(self.dut.o_clk)
                            await FallingEdge(self.dut.o_clk)
                            io_cycle_result["clocks"] += 1
                            
                            while str(self.dut.o_nsterm.value) == 'Z':  # wait state
                                await RisingEdge(self.dut.o_clk)
                                await FallingEdge(self.dut.o_clk)
                                io_cycle_result["clocks"] += 1
                                io_cycle_result["wait_states"] += 1
                    self.dut.i_ncbreq.value = Logic('1')
                else:
                    data = int(self.dut.io_d.value)
                port_size = 4
            else:  # S3 async
                await RisingEdge(self.dut.o_clk)  # Beginning of S4
                
                if str(self.dut.o_ndsack.value) == "00":  # 32-bit port
                    io_cycle_result["data"] = int(self.dut.io_d.value)
                    port_size = 4
                elif str(self.dut.o_ndsack.value) == "0Z":  # 16-bit port
                    if bytes_read == 0:
                        data = 0
                    io_cycle_result["data"] = int(self.dut.io_d.value[0:15]) << (8 * bytes_read)
                    port_size = 2
                elif str(self.dut.o_ndsack.value) == "Z0":  # 8-bit port
                    if bytes_read == 0:
                        data = 0
                    io_cycle_result["data"] = int(self.dut.io_d.value[0:7]) << (8 * bytes_read)
                    port_size = 1
                    
                await FallingEdge(self.dut.o_clk)  # Beginning of S5
                io_cycle_result["ack_size"] = port_size
                io_cycle_result["clocks"] += 1
                
                io_result["cycles"].append(io_cycle_result)
            self.dut.i_nas.value = Logic('1')
            self.dut.i_nds.value = Logic('1')
            
            if bytes_left < port_size:
                bytes_left -= size
                bytes_read += size
            else:
                bytes_left -= port_size
                bytes_read += port_size
                
        if not io_result["burst"]:
            io_result["size"] = size
        
        io_result["end_ns"] = get_sim_time("ns")

        return io_result
            
    async def write(self, asp: AddressSpace, addr: int, size: int, data: int) -> dict:
        if size not in [1, 2, 4]:
            print(f"Invalid operation size: {size}")
            return
        if addr not in range(0, 0x100000000):
            print(f"Invalid address: {hex(addr)}")
            return
        if addr + size - 1 not in range(0, 0x100000000):
            print(f"Invalid address and size: {hex(addr)}, {size}")
            return
        
        io_result = {
            "operation": "write",
            "address_space": asp.name,
            "address": addr,
            "data": data,
            "cycles": [],
            "start_ns": get_sim_time()
        }
        
        bytes_left = size
        bytes_written = 0
        
        while bytes_left > 0:
            io_cycle_result = {
                "ack_size": 0,
                "sync": False,
                "clocks": 0,
                "wait_states": 0
            }
            
            await RisingEdge(self.dut.o_clk)  # Beginning of S0
            self.dut.i_a.value = LogicArray(addr + bytes_written, range=Range(31, "downto", 0))
            self.dut.io_d.value = Release()
            self.dut.i_fc.value = LogicArray(asp.value, range=Range(2, "downto", 0))
            self.dut.i_r_nw.value = Logic('0')
            self.dut.i_size.value = LogicArray(["01", "10", "11", "00"][bytes_left - 1])
            
            await FallingEdge(self.dut.o_clk)  # Beginning of S1
            self.dut.i_nas.value = Logic('0')
            io_cycle_result["clocks"] += 1
            
            await RisingEdge(self.dut.o_clk)  # Beginning of S2
            self.dut.io_d.value = Freeze()
            data_mask = (1 << (bytes_left * 8)) - 1
            data_out = (data & data_mask) << ((4 - bytes_left - bytes_written) * 8)
            data_out &= 0xFFFFFFFF
            self.dut.io_d.value = LogicArray(data_out, range=Range(31, "downto", 0))
            
            await FallingEdge(self.dut.o_clk)  # Beginning of S3 or Sw
            io_cycle_result["clocks"] += 1
            
            if str(self.dut.o_nsterm.value) == '0':  # No wait states, sync
                port_size = 4
            else:
                self.dut.i_nds.value = Logic('0')
                
                while str(self.dut.o_ndsack.value) == "ZZ" and str(self.dut.o_nsterm.value) == 'Z':
                    await RisingEdge(self.dut.o_clk)  # wait state
                    await FallingEdge(self.dut.o_clk)  # wait state
                    io_cycle_result["clocks"] += 1
                    io_cycle_result["wait_states"] += 1
                    
                if str(self.dut.o_nsterm.value) == '0':  # sync
                    port_size = 4
                else:  # async
                    if str(self.dut.o_ndsack.value) == "00":  # 32-bit port
                        port_size = 4
                    elif str(self.dut.o_ndsack.value) == "0Z":  # 16-bit port
                        port_size = 2
                    elif str(self.dut.o_ndsack.value) == "Z0":  # 8-bit port
                        port_size = 1
            
                    await RisingEdge(self.dut.o_clk)  # Beginning of S4
                    await FallingEdge(self.dut.o_clk)  # Beginning of S5
                    io_cycle_result["clocks"] += 1
                    
                self.dut.io_d.value = Release()
                
            io_cycle_result["ack_size"] = port_size
            io_result["cycles"] = io_cycle_result

            if bytes_left < port_size:
                bytes_left -= size
                bytes_written += size
            else:
                bytes_left -= port_size
                bytes_written += port_size
            
            self.dut.i_nas.value = Logic('1')
            self.dut.i_nds.value = Logic('1')
        
        self.dut.io_d.value = Release()
        io_result["end_ns"] = get_sim_time("ns")
        
        return io_result
        
    async def check_irq(self):
        ipl_status = str(self.dut.o_nipl.value).replace('Z', '1')
        ipl_status = ~int(ipl_status, base=2) & 0x07
        self.ipl_status = ipl_status
        
        if ipl_status != 0 and self.ipl_status < ipl_status:
            return await self.read(MC68030.AddressSpace.CPU_SPACE, 0xFFFFFFF1 | (ipl_status << 1), 1)
        else:
            return None
        

@cocotb.test
async def test_basic(dut):
    init_signal(dut)
    cpu = MC68030(dut)
    await cpu.reset()
    
    results = []
    
    with open('io_list.txt', 'r') as io_list:
        for line_num, line in enumerate(io_list.readlines()):
            line = line.rstrip(' \n')
            if len(line) == 0 or line[0] == ';':
                continue
            line = line.split(' ')
            
            if line[0] == 'R':
                result = await cpu.read(MC68030.AddressSpace.SUPER_DATA, int(line[2], base=16), int(line[1]))
            elif line[0] == 'B':
                result = await cpu.read(MC68030.AddressSpace.SUPER_DATA, int(line[1], base=16), burst=True)
            elif line[0] == 'W':
                result = await cpu.write(MC68030.AddressSpace.SUPER_DATA, int(line[2], base=16), int(line[1]), int(line[3], base=16))
            else:
                continue
            
            result["line"] = line_num
            results.append(result)
            
            result = await cpu.check_irq()
            if result != None:
                results.append(result)
            
                
    with open('report.json', 'w') as report:
        report.write(json.dumps(results, indent=4))

