-- coding:utf-8
-- File Name: r0_testOutmapInfo.lua
-- Author: kht
-- Created Time: 2017/5/26 14:19:25
function Initialize(bus_id, ctrl_id)
    adapter.create_fifo(bus_id, ctrl_id)
end

function show_controller_outmapinfo(ret_data)
    if adapter.read_elem(ret_data, 0) ~= 0x05 then
        return false
    end

    if adapter.read_elem(ret_data, 2) ~= 0x4 or adapter.read_elem(ret_data, 3) ~= 0 then
        return false
    end

    length = adapter.read_elem(ret_data, 1)
    str = ""
    for i = 1,(length - 5) do
        data = adapter.read_elem(ret_data, 3 + i)
        str = str..string.format("%c", data)
    end
    print(str)
    return true
end

function print_controller_outmapinfo(bus_id, ctrl_id)
    adapter.clear_upfifo(bus_id, ctrl_id)

    cmd_get_controller_outmapinfo = {0x5, 0x4, 0x04, 0x00}
    ret = adapter.write_downdata(bus_id, ctrl_id, cmd_get_controller_outmapinfo)
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
            if show_controller_outmapinfo(return_data) then
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
print_controller_outmapinfo(4, 0)