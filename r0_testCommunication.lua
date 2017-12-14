-- coding:utf-8
-- File Name: r0_testCommunication.lua
-- Author: kht
-- Created Time: 2017/5/19 11:33:34

current_send_pluse_sn = 0x00000000
--全部变量，用于中断循环打印，降低打印频率防止字符串过多丢失
tick_time = 0
--当前收到的feedback包的计数,lua数据都是32位的，可能溢出
num_of_feedback_package = 0
--当前收到的inmap_package包计数
num_of_inmap_package = 0
--当前收到的最新sn号
current_pulse_sn = 0
--零脉冲数据包
pheonix_cmd_zero_pluse={0x99, 0x10, 0x00, 0x00, 0x00, 0x00}

function write_nccmd_sn(nc_cmd)
    -- 当前sn拆分成四段
    sn1 = current_send_pluse_sn - (current_send_pluse_sn / 2 ^ 8) * 2 ^ 8
    sn2 = current_send_pluse_sn / 2 ^ 8 - (current_send_pluse_sn / 2 ^ 16) * 2 ^ 8
    sn3 = current_send_pluse_sn / 2 ^ 16 - (current_send_pluse_sn / 2 ^ 24) * 2 ^ 8
    sn4 = current_send_pluse_sn / 2 ^ 24
    px_cmd = nc_cmd
    px_cmd[3] = sn1
    px_cmd[4] = sn2
    px_cmd[5] = sn3
    px_cmd[6] = sn4
    return px_cmd
end

function initialize()
    --创建Lambda缓冲区
    adapter.create_fifo(0, 0)
end

--连接中断之前，向Lambda发送connect_next命令连接打开连接
--按pheonix协议，connect_next后，Lambda会实时反馈端口信息包
function before_connect_interrupt()
    --初始化数据
    tick_time = 0
    num_of_feedback_package = 0
    num_of_inmap_package = 0
    current_pulse_sn = 0

    adapter.clear_downfifo(0, 0)
    adapter.clear_upfifo(0, 0)
    --CMD = SYSINFO, length = 5, pnn = 0x0080, on = 1
    cmd_connect_next_on = {0x5, 0x5, 0x80, 0x0, 0x1}
    adapter.write_downdata(0, 0, cmd_connect_next_on)
end

--断开中断后，关闭connect_next命令的连接
function after_disconnect_interrupt()
    --CMD = SYSINFO, length = 5, pnn = 0x0080, on = 0
    cmd_connect_next_off = {0x5, 0x5, 0x80, 0x0, 0x0}
    adapter.write_downdata(0, 0, cmd_connect_next_off)

    adapter.clear_downfifo(0, 0)
    adapter.clear_upfifo(0, 0)
end

function on_interrupt()
    tick_time = tick_time + 1
    if tick_time == 5000 then
        tick_time = 0
        str = "num_of_feedback_package:"..tostring(num_of_feedback_package)
        print(str)
        str = "num_of_inmap_package:"..tostring(num_of_inmap_package)
        print(str)
        str = string.format("current_pulse_sn:%08X", current_pulse_sn)
        print(str)
    end
    
		px_cmd = write_nccmd_sn(pheonix_cmd_zero_pluse)
		adapter.write_downdata(0, 0, px_cmd)
		current_send_pluse_sn = current_send_pluse_sn + 1
    ret_data = adapter.read_upfifo(0, 0)
    while ret_data ~= nil do
        if adapter.read_elem(ret_data, 0) == 0x21 then
            num_of_inmap_package = num_of_inmap_package + 1
        end
        if adapter.read_elem(ret_data, 0) == 0x20 then
            num_of_feedback_package = num_of_feedback_package + 1
            current_pulse_sn = adapter.read_elem_uint(ret_data, 2)
        end
        ret_data = adapter.read_upfifo(0, 0)
    end
end

initialize()

