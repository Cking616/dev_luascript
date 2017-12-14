-- coding:utf-8
-- File Name: r0_testinterrupt.lua
-- Author: kht
-- Created Time: 2017/3/16 10:34:44

adapter.create_fifo(4, 0)
adapter.write_downdata(4, 0, {0x5, 0x4, 0x1, 0x0})

function show_controller_baseinfo(ret_data)
    --返回数据中，包含了CRC，但是已由底层校验，此处不需要校验

    --判断返回数据,命令头是否是CMD_BASEINFO,长度是否为27
    if adapter.read_elem(ret_data, 0) ~= 0x5 and adapter.read_elem(ret_data, 1) ~= 27 then
        return false
    end

    --判断pnn号
    if  adapter.read_elem_ushort(ret_data, 2) ~= 0x0001  then
        return false
    end

    --打印设备名
    ctrl_name = ""
    for i = 0, 11 do
        data = adapter.read_elem(ret_data, 4 + i)
        if data == 0 then
            break
        end
        ctrl_name = ctrl_name..string.format("%c", data)
    end
    print("Ctrl_name:"..ctrl_name)


    data = adapter.read_elem(ret_data, 16)
    str = string.format("%d", data)
    print("FirmwareMinorVersion:"..str)


    data = adapter.read_elem(ret_data, 17)
    str = string.format("%d", data)
    print("NccmdFifoLength:"..str)

    peroid_num = adapter.read_elem_ushort(ret_data, 18)
    str = string.format("%d", peroid_num)
    print("Peroid:"..str)

    data = adapter.read_elem(ret_data, 20)
    str = string.format("%d", data)
    print("NumofAxis:"..str)

    data = adapter.read_elem(ret_data, 21)
    str = string.format("%d", data)
    print("Flag:"..str)
    
    max_ppc = adapter.read_elem_ushort(ret_data, 22)
    str = string.format("%d", max_ppc)
    print("MaxPPC:"..str)

    data = adapter.read_elem(ret_data, 24)
    str = string.format("%d", data)
    print("FirmwareMinorVersion:"..str)

    data = adapter.read_elem(ret_data, 25)
    str = string.format("%d", data)
    print("FirmwareBuildNo:"..str)

    return true
end

interrupt_time = 0

function on_interrupt()
    interrupt_time = interrupt_time + 1
    ret_data = adapter.read_upfifo(4, 0)
    if ret_data ~= nil then
        show_controller_baseinfo(ret_data)
    end

    if interrupt_time == 2000 then
        adapter.write_downdata(4, 0, {0x5, 0x4, 0x1, 0x0})
        interrupt_time = 0
    end
end
