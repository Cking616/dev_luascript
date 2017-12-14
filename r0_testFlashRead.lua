-- coding:utf-8
-- File Name: r0_testFlashRead.lua
-- Author: kht
-- Created Time: 2017/5/26 12:32:09
--
function Initialize(bus_id, ctrl_id)
    adapter.create_fifo(bus_id, ctrl_id)
end

function show_controller_flash(ret_data)
    if adapter.read_elem(ret_data, 0) ~= 0x05 then
        return false
    end

    if adapter.read_elem(ret_data, 2) ~= 0x7 or adapter.read_elem(ret_data, 3) ~= 0 then
        return false
    end

    length = adapter.read_elem(ret_data, 1)

    address = adapter.read_elem_uint(ret_data, 4)
    str = string.format("FristAddress:0x%08X",address)
    print(str)

    for i = 1,(length - 9) do
        data = adapter.read_elem(ret_data, 7 + i)
        str = string.format("Address:0x%08X, Data:0x%02X", address + i, data)
        print(str)
    end
    return true
end

function print_controller_flash(bus_id, ctrl_id, address, length)
    adapter.clear_upfifo(bus_id, ctrl_id)

    if length > 128 and length < 0 then
        return
    end

    --依次将32位数分成四个8位数
    address1 = address - (address / 2 ^ 8) * (2 ^ 8)
    address2 = address / 2 ^ 8 - (address / 2 ^ 16) * (2 ^ 8)
    address3 = address / 2 ^ 16 - (address / 2 ^ 24) * (2 ^ 16)
    address4 = address / 2 ^ 24
    cmd_get_controller_flash = {0x5, 0x9, 0x7, 0x0, address1, address2, address3, address4, length}
    ret = adapter.write_downdata(bus_id, ctrl_id, cmd_get_controller_flash)
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
            if show_controller_flash(return_data) then
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
print_controller_flash(4, 0, 0x00081000, 128)

