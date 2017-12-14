-- coding:gbk
-- File Name: r0_testControllerBaseInfo.lua
-- Author: kht
-- Created Time: 2017/5/18 15:16:39

function initialize()
    --adapter.create_fifo(0, 0)
    adapter.create_fifo(4, 0)
end

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

function print_controller_baseinfo(bus_id, controller_id)
    --BASE_INFO 数据帧为{CMD_BASEINFO, length, PNN低位， PNN高位，CRC}
    --这里CRC在发送数据时由底层添加，所以此处没有CRC，长度为为表的实际长度
    cmd_get_controller_baseinfo = {0x5, 0x4, 0x1, 0x0}
    ret = adapter.write_downdata(bus_id, controller_id, cmd_get_controller_baseinfo)
    if not ret then
        return
    end
    --这里实际上get_tickcount返回的是64位数据，而l_ticktime是其低32位的
    --形如a,b = get_tickcount()，a是低32位，b是高32位的
    --这里实际隐藏了一个bug,在还剩100ms就要向高位进位时判断是不准确的。
    --但是考虑概率比较小，在脚本中不处理这个bug
    l_ticktime,h_ticktime = get_tickcount()
    -- 读 1000次，如果没有读到就超时退出
    while true do
        -- 这个函数会读端口，并把收到的数据包发到控制器的upfifo上去
        adapter.read_updata(bus_id, controller_id)
        -- 从upfifo中拿数据
        return_data = adapter.read_upfifo(bus_id, controller_id)
        if return_data ~= nil then
            if show_controller_baseinfo(return_data) then
                break
            end
        end

        --等待200ms，超时则退出
        now_l_ticktime, b = get_tickcount()
        if now_l_ticktime - l_ticktime > 200 then
            break
        end
    end
end

--初始化lambda缓冲区和适配器缓冲区
initialize()

--打印适配器控制器信息
print_controller_baseinfo(4, 0)

print("  ")

--打印Lambda控制器信息
--print_controller_baseinfo(0, 0)
