# SettingsView & ESPView – iOS Tweak Libraries

## Table of Contents
1. [Setup & Installation](#1-setup--installation)  
2. [Using SettingsView](#2-using-settingsview)  
    - [2.1 Initialization & Display](#21-initialization--display)  
    - [2.2 Creating Tabs](#22-creating-tabs)  
    - [2.3 Adding Components](#23-adding-components)  
    - [2.4 Retrieving Setting Values](#24-retrieving-setting-values)  
    - [2.5 Credit](#25-credit)  
    - [2.6 Example: Tweak Menu Setup](#26-example-tweak-menu-setup)  
3. [Using ESPView](#3-using-espview)  
    - [3.1 Drawing Loop Concept](#31-drawing-loop-concept)  
    - [3.2 Initialization](#32-initialization)  
    - [3.3 Drawing Primitives](#33-drawing-primitives)  
    - [3.4 Clearing the Canvas](#34-clearing-the-canvas)  

---

## 1. Setup & Installation

1. Add the `Settings/` and `Esp/` folders to your tweak's source directory.
2. Import the following headers in your `Tweak.xm` file:

```
#import "Settings/SettingsView.m"
#import "Esp/ESPView.h"
```

---

## 2. Using SettingsView

### 2.1 Initialization & Display

```
SettingsView *menu = [SettingsView shared];
[menu show];

[menu setupCustomGestureToShow];
```

### 2.2 Creating Tabs

```
[[SettingsView shared] addTabWithTitle:@"General"];
[[SettingsView shared] addTabWithTitle:@"Interface"];
[[SettingsView shared] addTabWithTitle:@"About"];
```

### 2.3 Adding Components

#### Switch

```
MenuComponent *espSwitch = [MenuComponent switchComponentWithTitle:@"Enable ESP"
                                                               key:@"kEnableESP"
                                                           initial:YES];
[[SettingsView shared] addComponent:espSwitch toTab:0];
```

#### Slider

```
MenuComponent *slider = [MenuComponent sliderComponentWithTitle:@"Line Width"
                                                            key:@"kLineWidth"
                                                             min:1.0
                                                             max:10.0
                                                         initial:2.0];
[[SettingsView shared] addComponent:slider toTab:1];
```

#### Slider with Switch

```
MenuComponent *combo = [MenuComponent sliderWithSwitchComponentWithTitle:@"Glow Effect"
                                                                     key:@"kGlowEffect"
                                                                     min:0.0
                                                                     max:1.0
                                                                 initial:0.5
                                                           switchInitial:NO];
[[SettingsView shared] addComponent:combo toTab:1];
```

#### Label

```
MenuComponent *label = [MenuComponent labelComponentWithText:@"ESP Options"
                                                    fontSize:16.0
                                                   alignment:NSTextAlignmentCenter
                                                  fontWeight:UIFontWeightBold];
[[SettingsView shared] addComponent:label toTab:1];
```

#### Dropdown

```
NSArray *options = @[@"Low", @"Medium", @"High"];
MenuComponent *dropdown = [MenuComponent dropdownComponentWithTitle:@"Graphics"
                                                                key:@"kGraphicsQuality"
                                                            options:options
                                                    initialSelected:1];
[[SettingsView shared] addComponent:dropdown toTab:0];
```

#### Theme Selector

```
MenuComponent *themeSelector = [MenuComponent themeSelectorComponentWithTitle:@"Theme"
                                                                          key:@""
                                                              initialSelected:ThemeIdentifierDefault];
[[SettingsView shared] addComponent:themeSelector toTab:1];
```

### 2.4 Retrieving Setting Values

```
BOOL enabled = [[SettingsView shared] boolValueForKey:@"kEnableESP"];
CGFloat lineWidth = [[SettingsView shared] floatValueForKey:@"kLineWidth"];
```

### 2.5 Credit

```
[[SettingsView shared] setCreditsText:@"Made by YourName"];
```

### 2.6 Example: Tweak Menu Setup

```
SettingsView *settings = [SettingsView shared];
[settings setCreditsText:@"Made by Doan Tien"];

[settings addTabWithTitle:@"General"];
[settings addTabWithTitle:@"Interface"];
[settings addTabWithTitle:@"About"];

[settings addComponent:[MenuComponent switchComponentWithTitle:@"Enable Features"
                                                           key:@"enabled"
                                                       initial:YES] toTab:0];

[settings addComponent:[MenuComponent switchComponentWithTitle:@"Enable ESP"
                                                           key:@"drawEsp"
                                                       initial:YES] toTab:0];

[settings addComponent:[MenuComponent switchComponentWithTitle:@"Show Minimap"
                                                           key:@"drawMinimap"
                                                       initial:YES] toTab:0];

[settings addComponent:[MenuComponent sliderComponentWithTitle:@"Map X Offset"
                                                           key:@"mapLeft"
                                                            min:30
                                                            max:200
                                                        initial:47] toTab:0];

[settings addComponent:[MenuComponent sliderComponentWithTitle:@"Map Y Offset"
                                                           key:@"mapTop"
                                                            min:20
                                                            max:100
                                                        initial:37] toTab:0];

[settings addComponent:[MenuComponent sliderComponentWithTitle:@"Map Size"
                                                           key:@"mapSize"
                                                            min:50
                                                            max:200
                                                        initial:130] toTab:0];

[settings addComponent:[MenuComponent switchComponentWithTitle:@"Show Enemy Info"
                                                           key:@"drawInfo"
                                                       initial:YES] toTab:0];

[settings addComponent:[MenuComponent themeSelectorComponentWithTitle:@"Select Theme"
                                                                  key:@""
                                                      initialSelected:ThemeIdentifierDefault] toTab:1];

[settings addComponent:[MenuComponent labelComponentWithText:@"Custom Game Tweak"
                                                    fontSize:14.0
                                                   alignment:NSTextAlignmentCenter
                                                  fontWeight:UIFontWeightLight] toTab:2];

[settings addComponent:[MenuComponent labelComponentWithText:@"Developed by tien0246"
                                                    fontSize:14.0
                                                   alignment:NSTextAlignmentCenter
                                                  fontWeight:UIFontWeightLight] toTab:2];

[settings addComponent:[MenuComponent labelComponentWithText:@"Version: 1.58.11379483"
                                                    fontSize:12.0
                                                   alignment:NSTextAlignmentRight
                                                  fontWeight:UIFontWeightSemibold] toTab:2];
```

---

## 3. Using ESPView

### 3.1 Drawing Loop Concept

Each frame should follow this sequence:
1. Clear previous shapes
2. Read current state or data
3. Draw updated shapes/texts

### 3.2 Initialization

```
ESPView *esp = [ESPView shared];
```

### 3.3 Drawing Primitives

#### Line

```
[[ESPView shared] addLineFrom:CGPointMake(10, 10)
                           to:CGPointMake(100, 100)
                        color:UIColor.redColor
                    lineWidth:2.0];
```

#### Rectangle

```
[[ESPView shared] addRect:CGRectMake(50, 50, 100, 80)
                    color:UIColor.greenColor
                lineWidth:1.5
                fillColor:nil];

[[ESPView shared] addRect:CGRectMake(200, 50, 100, 80)
                    color:UIColor.whiteColor
                lineWidth:1.0
                fillColor:[UIColor.blueColor colorWithAlphaComponent:0.5]];
```

#### Circle

```
[[ESPView shared] addCircleAt:CGPointMake(100, 200)
                       radius:40
                        color:UIColor.yellowColor
                    lineWidth:3.0
                    fillColor:nil];
```

#### Dot

```
[[ESPView shared] addDotAt:CGPointMake(150, 250)
                     radius:5
                     color:UIColor.cyanColor];
```

#### Text

```
[[ESPView shared] addText:@"Player"
                       at:CGPointMake(200, 200)
                    color:UIColor.whiteColor
                 fontSize:14.0
                alignment:NSTextAlignmentCenter
               fontWeight:UIFontWeightSemibold];
```

### 3.4 Clearing the Canvas

```
[[ESPView shared] clearShapes];
```

---
