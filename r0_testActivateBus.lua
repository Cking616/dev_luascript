-- coding:utf-8
-- File Name: r0_testActivateBus.lua
-- Author: kht
-- Created Time: 2017/6/22 0:48:19

-- 连接到下级数据包
phoenix_connect_next_cmd = {0x05, 0x05, 0x80, 0x00, 0x01}
-- 关闭下级连接数据包
phoenix_disconnect_next_cmd = {0x05, 0x05, 0x80, 0x00, 0x00}
-- 获取inmap_info包
phoenix_get_inmap_info_cmd = {0x05, 0x04, 0x03, 0x00}

-- is_next_controller_connected函数，通过inmap数据包判断是否成功连接到下一级
function is_next_controller_connected(inmap_data)
    if adapter.read_elem(inmap_data, 0) ~= 0x21 then
        return false
    end
    -- inmap 包 返回数据的第一个字节第二个位表示是否自身正常
    -- inmap 包 返回数据的第一个字节第一个位表示是否打开下级连接
    first_data = adapter.read_elem(inmap_data, 2)

    -- 暂时只用第一个bit判断,下面是获取第一位的做法
    first_bit = first_data - (first_data / 2) * 2
    second_bit = first_data / 2 - (first_data / 2 ^ 2) * 2
    if first_bit ~= 0 then
        return true
    end

    return false
end

function is_inmap_info_cmd(inmap_info_data)
    -- 判断cmd号
    if adapter.read_elem(inmap_info_data, 0) ~= 0x05 then
        return false
    end
    -- 判断pnn号
    if adapter.read_elem_ushort(inmap_info_data, 2) ~= 0x0003 then
        return false
    end
    return true
end

-- 一直等待某个数据帧返回，judge_function为判断函数，overtime为超时时间
function wait_for_target_data(bus_id, ctrl_id, judge_function, overtime)
    local ret_status = true
    l_ticktime, h_ticktime = get_tickcount()
    while true do
        adapter.read_updata(bus_id, ctrl_id)
        ret_data = adapter.read_upfifo(bus_id, ctrl_id)
        if ret_data ~= nil then
            if judge_function(ret_data) then
                break
            end
        end
        now_l_ticktime, b = get_tickcount()
        -- 超时退出，暂时设置成200ms，这里退出表示控制器未能正常连接
        if now_l_ticktime - l_ticktime > overtime then
            ret_status = false
            break
        end
    end
    return ret_status
end

-- 端口控制器总端口
function close_phoenix_bus(bus_id)
    -- 写端口断开总线
    port_base = adapter.get_base_port()
    -- 命令0x03端口0号端口
    if bus_id == 0 then
    	outb(port_base + 0x0013, 0x03)
    else
    	outb(port_base + 0x0013, 2 * bus_id + 0x06)
    end
end

function open_phoenix_bus(bus_id)
    -- 写端口打开总线
    port_base = adapter.get_base_port()
    -- 命令0x03端口0号端口
    if bus_id == 0 then
    	outb(port_base + 0x0013, 0x02)
    else
    	outb(port_base + 0x0013, 2 * bus_id + 0x05)
    end
end

-- 连接到特定总线，返回值为连接到该总线控制器数
function activate_phoenix_bus(bus_id)
    -- 先断开一次连接，确保没有运行过程实时数据包的影响
    close_phoenix_bus(bus_id)
    sleep(100)
		open_phoenix_bus(bus_id)
		
    connect_status = true
    num_of_active_controller = 0
    -- 从0号控制器逐一尝试到7号控制器
    for i = 0,7 do
        adapter.create_fifo(bus_id, i)
        -- 尝试接受一下非实时数据包，判断一下当前控制器是否连接
        -- 防止这个时候控制器中断已打开，先清一下缓冲区
        adapter.clear_upfifo(bus_id, i)
        adapter.write_downdata(bus_id, i, phoenix_get_inmap_info_cmd)

        -- 等待接收某个数据帧
        if wait_for_target_data(bus_id, i, is_inmap_info_cmd, 200) ~= true then
            break
        end

        -- 这样表示当前控制器已连接
        num_of_active_controller = num_of_active_controller + 1

        -- 连接下级控制器
        adapter.write_downdata(bus_id, i, phoenix_connect_next_cmd)
        adapter.clear_upfifo(bus_id, i)
        if wait_for_target_data(bus_id, i, is_next_controller_connected, 200) ~= true then
            break
        end
        -- 注意这里打开了控制器中断，如果不实时读数据，控制器upfifo会被1ms周期向上发的数据帧填满
        -- 所以之后如果临时使用，一定要用clear_upfifo先丢弃那些无用的实时数据帧
    end

    return num_of_active_controller
end

-- 1号总线连了固定2块输入面板，采用它来测试一下这个脚本
num_of_ctrl = activate_phoenix_bus(0)
str = string.format("number of bus0's ctrl: %d", num_of_ctrl)
print(str)

-- 如果总线处在连接状态，由于受实时数据包影响，可能在不开中断连续读的条件得出不准确的结果
-- 所以退出时，断开总线连接，确保不对其他脚本运行造成前置条件
close_phoenix_bus(0)
sleep(100)
open_phoenix_bus(0)