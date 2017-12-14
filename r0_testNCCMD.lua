-- coding:utf-8
-- File Name: r0_testNCCMD.lua
-- Author: kht
-- Created Time: 2017/5/27 10:03:38

current_send_pluse_sn = 0x00000000
current_recive_pluse_sn = 0x00000000
current_interrupt_time_1 = 0
current_interrupt_time_2 = 0
send_cmd = {}

-- 测试时所有ncc_cmd除sn号段数据外，都定死
cmd_phoenix_mii_nc_cmds =
{
    --    | CMD | Len |        SN             | MF  | CF  |        1_pos         |       2_pos           |
    --   | - - | - - | - - = - - = - - = - - | - - | - - |- - = - - = - - = - - | - - = - - = - - = - - |
    [1] = {0xcc, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
    [2] = {0xcc, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
    [3] = {0xcc, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
    [4] = {0xcc, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
    [5] = {0xcc, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
    [6] = {0xcc, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
}

-- 测试时使用两个轴,mii_start指令
cmd_phoenix_mii_start_cmd = {0x06, 0x7, 0x16, 0x20, 0x2, 0x41, 0x42}
-- 连接下级控制器，打开中断
cmd_phoenix_connect_next_on = {0x05, 0x05, 0x80, 0x0, 0x01}


function write_nccmd_sn(nc_cmd, pos)
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

    if pos ~= nil then
        pos1 = pos - pos / 2 ^ 8
        pos2 = pos / 2 ^ 8 - pos / 2 ^ 16
        pos3 = pos / 2 ^ 16 - pos / 2 ^ 24
        pos4 = pos / 2 ^ 24
        px_cmd[9] = pos1
        px_cmd[10] = pos2
        px_cmd[11] = pos3
        px_cmd[12] = pos4
    end

    return px_cmd
end


function initialize()
    adapter.create_fifo(0, 0)
end


function before_connect_interrupt()
    adapter.clear_downfifo(0, 0)
    adapter.clear_upfifo(0, 0)

    adapter.write_downdata(0, 0, cmd_phoenix_mii_start_cmd)
    adapter.write_downdata(0, 0, cmd_phoenix_connect_next_on)
end


function on_interrupt()
    current_interrupt_time_1 = current_interrupt_time_1 + 1
    current_interrupt_time_2 = current_interrupt_time_2 + 2
    if current_interrupt_time_1 == 7 then
        current_interrupt_time_1 = 0
    end

    if current_interrupt_time_2 == 4000 then
        current_interrupt_time_2 = 0
    end
    current_pos = (current_interrupt_time_2 / 1000) * 100

    send_cmd = write_nccmd_sn(cmd_phoenix_mii_nc_cmds[current_interrupt_time_1], current_pos)
    adapter.write_downfifo(0, 0, send_cmd)
    current_send_pluse_sn = current_send_pluse_sn + 1

    ret_data = adapter.read_upfifo(0, 0)
    while ret_data ~= nil do
        if adapter.read_elem(ret_data, 0) == 0xcc then
            current_recive_pluse_sn = adapter.read_elem_uint(ret_data, 2)
        end
        ret_data = adapter.read_upfifo(0, 0)
    end
end


initialize()
