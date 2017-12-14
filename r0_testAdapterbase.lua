-- coding:utf-8
-- File Name: r0_testAdapterbase.lua
-- Author: kht
-- Created Time: 2017/3/14 10:46:06

function show_adapter_baseinfo(out_port, in_port)
    bprint = true
    outb(out_port, 0x0)

    g = inb(in_port)
    s = string.format("Length:%d", g)
    if bprint then
        print(s)
    end

    g = inb(in_port)

    Descriptor  = ""
    for i = 0, 1 do
        g = inb(in_port)
        Descriptor = Descriptor .. string.format("%c", g)
    end
    if bprint then
        print("Descriptor:" .. Descriptor)
    end

    Name  = ""
    for i = 0, 7 do
        g = inb(in_port)
        Name = Name .. string.format("%c", g)
    end
    if bprint then
        print("Name:" .. Name)
    end

    g = inb(in_port)
    s = string.format("FirmwareMajorVersion:%d", g)
    if bprint then
        print(s)
    end

    g = inb(in_port)
    s = string.format("NumberofAuxiliary:%d", g)
    if bprint then
        print(s)
    end

    g = inb(in_port)
    s = string.format("FirmwareMinorVersion:%d", g)
    if bprint then
        print(s)
    end

    g = inb(in_port)
    s = string.format("FirmwareBuildNo:%d", g)
    if bprint then
        print(s)
    end

    l = inb(in_port)
    v = inb(in_port)
    g = v * 2 ^ 8 + l
    s = string.format("AdapterFifoPort:0x%04X", g)
    if bprint then
        print(s)
    end

    l = inb(in_port)
    v = inb(in_port)
    g = v * 2 ^ 8 + l
    s = string.format("AdapterFifoLength:0x%04X", g)
    if bprint then
        print(s)
    end

    for i =0, 3 do
        if bprint then
            print(tostring(i))
        end
        l = inb(in_port)
        v = inb(in_port)
        g = v * 2 ^ 8 + l
        s = string.format("DownFifoPort:0x%04X", g)
        if bprint then
            print(s)
        end

        l = inb(in_port)
        v = inb(in_port)
        g = v * 2 ^ 8 + l
        s = string.format("DownFifoLength:0x%04X", g)
        if bprint then
            print(s)
        end

        l = inb(in_port)
        v = inb(in_port)
        g = v * 2 ^ 8 + l
        s = string.format("UpFifoPort:0x%04X", g)
        if bprint then
            print(s)
        end

        l = inb(in_port)
        v = inb(in_port)
        g = v * 2 ^ 8 + l
        s = string.format("UpFifoLength:0x%04X", g)
        if bprint then
            print(s)
        end
    end

    l = inb(in_port)
    v = inb(in_port)
    g = v * 2 ^ 8 + l
    AdapterDownFifoPort = g
    s = string.format("AdapterDownFifoPort:0x%04X", g)
    if bprint then
        print(s)
    end

    l = inb(in_port)
    v = inb(in_port)
    g = v * 2 ^ 8 + l
    s = string.format("AdapterDownFifoLength:0x%04X", g)
    if bprint then
        print(s)
    end

    l = inb(in_port)
    v = inb(in_port)
    g = v * 2 ^ 8 + l
    AdapterUpFifoPort = g
    s = string.format("AdapterUpFifoPort:0x%04X", g)
    if bprint then
        print(s)
    end

    l = inb(in_port)
    v = inb(in_port)
    g = v * 2 ^ 8 + l
    s = string.format("AdapterUpFiroLength:0x%04X", g)
    if bprint then
        print(s)
    end
end

port_base = adapter.get_base_port()
show_adapter_baseinfo(port_base + 0x0013, port_base + 0x0012)