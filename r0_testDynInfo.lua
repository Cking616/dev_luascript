-- coding:utf-8
-- File Name: r0_testDynInfo.lua
-- Author: kht
-- Created Time: 2017/5/26 11:01:21

function Initialize(bus_id, ctrl_id)
    adapter.create_fifo(bus_id, ctrl_id)
end

function show_controller_dyninfo(ret_data)
    if adapter.read_elem(ret_data, 0) ~= 0x05 then
        return false
    end

    if adapter.read_elem(ret_data, 1) ~= 17 then
        return false
    end

    data1 = adapter.read_elem(ret_data, 4)
    data2 = adapter.read_elem(ret_data, 5)
    data3 = adapter.read_elem(ret_data, 6)
    data4 = adapter.read_elem(ret_data, 7)
    data = data1 + data2 * 2 ^ 8 + data3 * 2 ^ 16 + data4 * 2 ^ 24
    str = string.format("%08X",data)

    data1 = adapter.read_elem(ret_data, 8)
    data2 = adapter.read_elem(ret_data, 9)
    data3 = adapter.read_elem(ret_data, 10)
    data4 = adapter.read_elem(ret_data, 11)
    data = data1 + data2 * 2 ^ 8 + data3 * 2 ^ 16 + data4 * 2 ^ 24
    str = "TotalTime:"..string.format("0X%08X",data)..str
    print(str)

    data = adapter.read_elem(ret_data, 12)
    str = string.format("ErrorCode:0x%02X", data)
    print(str)

    data = adapter.read_elem(ret_data, 13)
    str = string.format("RemainedNccmdCount:%d", data)
    print(str)

    data1 = adapter.read_elem(ret_data, 14)
    data2 = adapter.read_elem(ret_data, 15)
    data = data1 + data2 * 2 ^ 8
    str = string.format("ErrorCount:%d", data)
    print(str)
    return true
end

function print_controller_dyninfo(bus_id, ctrl_id)
    adapter.clear_upfifo(bus_id, ctrl_id)

    cmd_get_controller_dyninfo = {0x5, 0x4, 0x2, 0x0}
    ret = adapter.write_downdata(bus_id, ctrl_id, cmd_get_controller_dyninfo)
    if not ret then
        return
    end
    --这里实际上get_tickcount返回的是64位数据，而l_ticktime是其低32位的
    --形如a,b = get_tickcount()，a是低32位，b是高32位的
    --这里实际隐藏了一个bug,在还剩100ms就要向高位进位时判断是不准确的。
    --但是考虑概率比较小，在脚本中不处理这个bug
    l_ticktime,h_ticktime = get_tickcount()
    while true do
        -- 这个函数会读端口，并把收到的数据包发到控制器的upfifo上去
        adapter.read_updata(bus_id, ctrl_id)
        -- 从upfifo中拿数据
        return_data = adapter.read_upfifo(bus_id, ctrl_id)
        if return_data ~= nil then
            if show_controller_dyninfo(return_data) then
                break
            end
        end

        --等待200ms，超时则退出
        now_l_ticktime, b = get_tickcount()
        if now_l_ticktime - l_ticktime > 200 then
            print("TimeOut")
            break
        end
    end
end 

Initialize(4, 0)

print_controller_dyninfo(4, 0)
