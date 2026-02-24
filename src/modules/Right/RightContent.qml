import QtQuick
import Quickshell
import "../../components"
import "../../windows"
import "../../"

Row{
    id: root
    spacing: 8
    
    Row{
        spacing: 6
        
        Network{}
        
        Audio{}
        
        Battery{}
        
        Clock{}
        
        SysTray{}
        
        Notifications{}
    
    }
}
