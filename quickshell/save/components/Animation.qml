import QtQuick

QtObject {
    id: root

  
    readonly property int instant: 0
    readonly property int fast: 150
    readonly property int normal: 250
    readonly property int slow: 450
    readonly property int verySlow: 700

   
    readonly property int islandWidthMinimal: 90
    readonly property int islandWidthIdle: 160
    readonly property int islandWidthExpanded: 250
    readonly property int islandWidthMedia: 420

    readonly property int islandHeightMinimal: 32
    readonly property int islandHeightIdle: 40
    readonly property int islandHeightExpanded: 50
    readonly property int islandHeightMedia: 56

    
    
    readonly property int radiusSmall: 16
    readonly property int radiusNormal: 22
    readonly property int radiusLarge: 30

    
    
    readonly property int paddingSmall: 8
    readonly property int paddingNormal: 12
    readonly property int paddingLarge: 18

   
   
    readonly property int visualizerBars: 12
    readonly property int visualizerBarWidth: 3
    readonly property int visualizerSpacing: 2

    
    
    readonly property real hoverScale: 1.03

   
   
    readonly property int topMargin: 17
}