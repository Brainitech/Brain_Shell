import QtQuick
import "../../"
import "../../components"
import "../../services/"

Item {
    id: root

    property real localScale: 1.0

    CpuService         { id: cpu;     active: root.visible }
    MemService         { id: mem;     active: root.visible }
    NetService         { id: net;     active: root.visible }
    ThermalService     { id: thermal; active: root.visible }
    FanControl         { id: fan }
    DiskService        { id: disk;    active: root.visible }
    EnvyControlService { id: envy }
    CpuFreqService     { id: cpuFreq }
    GpuService {
        id:       gpu
        active:   root.visible
        envyMode: envy.currentMode
    }

    Column {
        anchors {
            fill:          parent
            bottomMargin:  Math.round(8 * localScale)
            topMargin:     Math.round(8 * localScale)
        }
        spacing: Math.round(8 * localScale)

        // Speedometers
        Row {
            id:      speedoRow
            width:   parent.width
            anchors.topMargin: Math.round(4 * localScale)
            height:  Math.round(160 * localScale)
            spacing: Math.round(8 * localScale)

            StatCard {
                localScale: root.localScale
                width:  (parent.width - parent.spacing * 3) / 4
                height: parent.height
                Speedometer {
                    anchors.centerIn: parent
                    size:        localScale
                    label:       "CPU"
                    percent:     cpu.usagePercent
                    centerText:  cpu.usagePercent + "%"
                    bottomText:  cpuFreq.curFreqStr
                    active:      true
                    accentColor: Theme.active
                }
            }

            StatCard {
                localScale: root.localScale
                width:  (parent.width - parent.spacing * 3) / 4
                height: parent.height
                Speedometer {
                    anchors.centerIn: parent
                    size:        localScale
                    label:       "RAM"
                    percent:     mem.usagePercent
                    centerText:  mem.usagePercent + "%"
                    bottomText:  mem.usedStr + " / " + mem.totalStr
                    active:      true
                    accentColor: "#cba6f7"
                }
            }

            StatCard {
                localScale: root.localScale
                width:  (parent.width - parent.spacing * 3) / 4
                height: parent.height
                Speedometer {
                    anchors.centerIn: parent
                    size:        localScale
                    label:       "iGPU"
                    percent:     gpu.igpu.freqPercent
                    centerText:  gpu.igpu.freqPercent + "%"
                    bottomText:  gpu.igpu.curMhz
                    active:      true
                    accentColor: "#89dceb"
                }
            }

            StatCard {
                localScale: root.localScale
                width:  (parent.width - parent.spacing * 3) / 4
                height: parent.height
                Speedometer {
                    anchors.centerIn: parent
                    size:        localScale
                    label:       "dGPU"
                    percent:     gpu.dgpu.active ? gpu.dgpu.usagePercent : 0
                    centerText:  gpu.dgpu.active ? (gpu.dgpu.usagePercent + "%") : "0%"
                    bottomText:  gpu.dgpu.active ? (gpu.dgpu.usedVram + " / " + gpu.dgpu.totalVram) : ""
                    active:      gpu.dgpu.active
                    accentColor: "#a6e3a1"
                }
            }
        }
        
        Row{
            width:   parent.width
            height:  Math.round(100 * localScale)
            spacing: Math.round(8 * localScale)
            // Thermal strip
            StatCard {
                localScale: root.localScale
                width:   (parent.width-parent.spacing)/2
                height:  parent.height
                padding: Math.round(6 * localScale)
    
                TempPanel {
                    anchors.fill: parent
                    localScale:   root.localScale
                    service:      thermal
                    dgpuActive:   gpu.dgpu.active
                }
            }
            
            // Fan control strip
            StatCard {
                localScale: root.localScale
                width:   (parent.width-parent.spacing)/2
                height:  parent.height
                padding: Math.round(6 * localScale)
                
                FanPanel {
                    anchors.fill: parent
                    localScale:   root.localScale
                    service:      fan
                }
            }
        }
        // Net | Disk | Power
        Row {
            width:   parent.width
            height:  parent.height - speedoRow.height - Math.round(100 * localScale) - parent.spacing 
            spacing: Math.round(8 * localScale)

            // Network — narrow, only 3 rows
            StatCard {
                localScale: root.localScale
                width:  Math.round(parent.width * 0.20)
                height: parent.height
                NetStatsPanel {
                    anchors.fill: parent
                    localScale:   root.localScale
                    service:      net
                }
            }

            // Disks — moderate, horizontal bars stack vertically
            StatCard {
                localScale: root.localScale
                width:  Math.round(parent.width * 0.35)
                height: parent.height
                DiskPanel {
                    anchors.fill: parent
                    localScale:   root.localScale
                    service:      disk
                }
            }

            // Power — widest, two button rows need space
            StatCard {
                localScale: root.localScale
                width:  parent.width - Math.round(parent.width * 0.20) - Math.round(parent.width * 0.35) - parent.spacing * 2
                height: parent.height
                PowerPanel {
                    anchors.fill:   parent
                    localScale:     root.localScale
                    cpuFreqService: cpuFreq
                    envyService:    envy
                }
            }
        }
    }
}
