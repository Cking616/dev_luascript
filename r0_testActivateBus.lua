-- coding:utf-8
-- File Name: r0_testActivateBus.lua
-- Author: kht
-- Created Time: 2017/6/22 0:48:19

-- ���ӵ��¼����ݰ�
phoenix_connect_next_cmd = {0x05, 0x05, 0x80, 0x00, 0x01}
-- �ر��¼��������ݰ�
phoenix_disconnect_next_cmd = {0x05, 0x05, 0x80, 0x00, 0x00}
-- ��ȡinmap_info��
phoenix_get_inmap_info_cmd = {0x05, 0x04, 0x03, 0x00}

-- is_next_controller_connected������ͨ��inmap���ݰ��ж��Ƿ�ɹ����ӵ���һ��
function is_next_controller_connected(inmap_data)
    if adapter.read_elem(inmap_data, 0) ~= 0x21 then
        return false
    end
    -- inmap �� �������ݵĵ�һ���ֽڵڶ���λ��ʾ�Ƿ���������
    -- inmap �� �������ݵĵ�һ���ֽڵ�һ��λ��ʾ�Ƿ���¼�����
    first_data = adapter.read_elem(inmap_data, 2)

    -- ��ʱֻ�õ�һ��bit�ж�,�����ǻ�ȡ��һλ������
    first_bit = first_data - (first_data / 2) * 2
    second_bit = first_data / 2 - (first_data / 2 ^ 2) * 2
    if first_bit ~= 0 then
        return true
    end

    return false
end

function is_inmap_info_cmd(inmap_info_data)
    -- �ж�cmd��
    if adapter.read_elem(inmap_info_data, 0) ~= 0x05 then
        return false
    end
    -- �ж�pnn��
    if adapter.read_elem_ushort(inmap_info_data, 2) ~= 0x0003 then
        return false
    end
    return true
end

-- һֱ�ȴ�ĳ������֡���أ�judge_functionΪ�жϺ�����overtimeΪ��ʱʱ��
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
        -- ��ʱ�˳�����ʱ���ó�200ms�������˳���ʾ������δ����������
        if now_l_ticktime - l_ticktime > overtime then
            ret_status = false
            break
        end
    end
    return ret_status
end

-- �˿ڿ������ܶ˿�
function close_phoenix_bus(bus_id)
    -- д�˿ڶϿ�����
    port_base = adapter.get_base_port()
    -- ����0x03�˿�0�Ŷ˿�
    if bus_id == 0 then
    	outb(port_base + 0x0013, 0x03)
    else
    	outb(port_base + 0x0013, 2 * bus_id + 0x06)
    end
end

function open_phoenix_bus(bus_id)
    -- д�˿ڴ�����
    port_base = adapter.get_base_port()
    -- ����0x03�˿�0�Ŷ˿�
    if bus_id == 0 then
    	outb(port_base + 0x0013, 0x02)
    else
    	outb(port_base + 0x0013, 2 * bus_id + 0x05)
    end
end

-- ���ӵ��ض����ߣ�����ֵΪ���ӵ������߿�������
function activate_phoenix_bus(bus_id)
    -- �ȶϿ�һ�����ӣ�ȷ��û�����й���ʵʱ���ݰ���Ӱ��
    close_phoenix_bus(bus_id)
    sleep(100)
		open_phoenix_bus(bus_id)
		
    connect_status = true
    num_of_active_controller = 0
    -- ��0�ſ�������һ���Ե�7�ſ�����
    for i = 0,7 do
        adapter.create_fifo(bus_id, i)
        -- ���Խ���һ�·�ʵʱ���ݰ����ж�һ�µ�ǰ�������Ƿ�����
        -- ��ֹ���ʱ��������ж��Ѵ򿪣�����һ�»�����
        adapter.clear_upfifo(bus_id, i)
        adapter.write_downdata(bus_id, i, phoenix_get_inmap_info_cmd)

        -- �ȴ�����ĳ������֡
        if wait_for_target_data(bus_id, i, is_inmap_info_cmd, 200) ~= true then
            break
        end

        -- ������ʾ��ǰ������������
        num_of_active_controller = num_of_active_controller + 1

        -- �����¼�������
        adapter.write_downdata(bus_id, i, phoenix_connect_next_cmd)
        adapter.clear_upfifo(bus_id, i)
        if wait_for_target_data(bus_id, i, is_next_controller_connected, 200) ~= true then
            break
        end
        -- ע��������˿������жϣ������ʵʱ�����ݣ�������upfifo�ᱻ1ms�������Ϸ�������֡����
        -- ����֮�������ʱʹ�ã�һ��Ҫ��clear_upfifo�ȶ�����Щ���õ�ʵʱ����֡
    end

    return num_of_active_controller
end

-- 1���������˹̶�2��������壬������������һ������ű�
num_of_ctrl = activate_phoenix_bus(0)
str = string.format("number of bus0's ctrl: %d", num_of_ctrl)
print(str)

-- ������ߴ�������״̬��������ʵʱ���ݰ�Ӱ�죬�����ڲ����ж��������������ó���׼ȷ�Ľ��
-- �����˳�ʱ���Ͽ��������ӣ�ȷ�����������ű��������ǰ������
close_phoenix_bus(0)
sleep(100)
open_phoenix_bus(0)