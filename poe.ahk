#include <GDIP>
#include <Gdip_ImageSearch>

#SingleInstance Force
#IfWinActive Path of Exile
SendMode Input
CoordMode, Mouse, Client

RandomSleep(min, max)
{
    Sleep myRandom(min, max)
    return
}
myRandom(min, max)
{
    Random, r, Floor(min), Floor(max)
    return r
}
myTooltip(text)
{
    ToolTip % text
    SetTimer, RemoveToolTip, -5000
    return
    RemoveToolTip:
        ToolTip
    return
}

F6::
    MouseGetPos, xpos, ypos
    myTooltip("The cursor is at X" xpos " Y" ypos)
Return

; left \
SC056::
    SendInput {Ctrl Down}
    while GetKeyState("SC056", "P") {
        SendInput {LButton}
        myUI.humanDelay()
    }
    SendInput {Ctrl Up}
Return

class Inventory {
    static PIXELS := { top: { x:1269, y: 585 }, bot: { x: 1905, y: 853 } }
    ; static PIXELS.delta := 53
    static PIXELS.delta := Round((((Inventory.PIXELS.bot.x - Inventory.PIXELS.top.x) / 12) + ((Inventory.PIXELS.bot.y - Inventory.PIXELS.top.y) / 5)) / 2)
   
    class Cell {
        __New(row, col) {
            this.isEmpty := 0
            this.pItem :=
            this.row := row
            this.col := col

            if (col == 1) {
                if (row == 1 or row == 2)
                    this.isEmpty := 1
            }
        }

        topLeft() {
            coords := { x: Inventory.PIXELS.top.x + ((this.col - 1) * Inventory.PIXELS.delta), y: Inventory.PIXELS.top.y + ((this.row - 1) * Inventory.PIXELS.delta) }
            return coords
        }
        fuzzyCenter() {       
            coords := this.topLeft()  
            coords.x := coords.x + myRandom(0.15 * Inventory.PIXELS.delta, 0.85 * Inventory.PIXELS.delta)
            coords.y := coords.y + myRandom(0.15 * Inventory.PIXELS.delta, 0.85 * Inventory.PIXELS.delta)
            
            return coords
        }
        fuzzyTopLeft() {       
            coords := this.topLeft()  
            coords.x := coords.x + myRandom(0.05 * Inventory.PIXELS.delta, 0.2 * Inventory.PIXELS.delta)
            coords.y := coords.y + myRandom(0.05 * Inventory.PIXELS.delta, 0.2 * Inventory.PIXELS.delta)
            
            return coords
        }
    }

    class Item {
        __New(info) {
            this.pAnchorCell :=
            this.tab := "dump"
            this.isUnidentified := 0
            this.size := {rows: 1, cols: 1}

            parts := StrSplit(info, "--------")
            if (InStr(info, "Unidentified") > 0) {
                this.isUnidentified := 1
            }
            if (InStr(info, "Map Tier:") > 0) {
                this.tab := "map"
            }
            else if (InStr(parts[1], "Currency") > 0) {
                if (InStr(parts[1], "Essence") > 0) {
                    this.tab := "essence"
                }
                else if ((InStr(parts[1], "Fossil") > 0)) {
                    this.tab := "delve"
                }
                else if (InStr(parts[1], "Resonator") > 0) {
                    this.tab := "delve"
                    ; size unknown
                    this.size := {rows: 0, cols: 0}
                }
                else if ((InStr(parts[1], "Splinter") > 0 and InStr(parts[1], "Simulacrum") == 0)
                    or InStr(parts[1], "Divine Vessel") > 0) {
                    this.tab := "fragment"
                }
                else if (InStr(parts[3], "Can be exchanged") > 0) {
                    ; heist crap, size unknown
                    this.tab := ""
                    this.size := {rows: 0, cols: 0}
                }
                else {
                    this.tab := "currency"
                }
            }
            else if (InStr(parts[1], "Rarity: Divination Card") > 0) {
                this.tab := "divination"
            }
            else if (InStr(parts[1], "Sacrifice at") > 0) {
                this.tab := "fragment"
            }
            else {
                ; random item, size unknown
                this.size := {rows: 0, cols: 0}
            }
        }
    }

    __New() {
        this.grid := []
        this.items := []
        this.rows := 5
        this.cols := 12

		Loop % this.rows {
            row := A_Index
            Loop % this.cols {
                col := A_Index
                this.grid[row, col] := new this.Cell(row, col)
            }
        }
    }
    __Delete() {
    }

    coordsToCell(coords) {
        x := coords[1]
        y := coords[2]
        row := (y - Inventory.PIXELS.top.y) // Inventory.PIXELS.delta
        col := (x - Inventory.PIXELS.top.x) // Inventory.PIXELS.delta

        return [row + 1, col + 1]
    }

    scanEmptyFrom(cell) {
        myUI.moveMouse(myRandom(0, Inventory.PIXELS.top.x), myRandom(0, Inventory.PIXELS.top.y))
        pHaystack := Gdip_BitmapFromScreen()
        coords := cell.topLeft()
        safety_margin := Round(Inventory.PIXELS.delta * 0.20)
        x := coords.x + safety_margin
        y := coords.y + safety_margin
        w := Inventory.PIXELS.delta - safety_margin * 2
        h := Inventory.PIXELS.delta - safety_margin * 2
        pNeedle := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
        pBrush := Gdip_BrushCreateSolid(0xffff0000)
        pGraphics := Gdip_GraphicsFromImage(pHaystack)

        i := 0
        Loop {
            i := i + 1
            found := Gdip_ImageSearch(pHaystack, pNeedle, coords, Inventory.PIXELS.top.x, Inventory.PIXELS.top.y, Inventory.PIXELS.bot.x, Inventory.PIXELS.bot.y, 8, "", 1, 1)
            coords := StrSplit(coords, ",")
            Gdip_FillRectangle(pGraphics, pBrush, coords[1], coords[2], w, h)
            coords := this.coordsToCell(coords)
            this.grid[coords[1], coords[2]].isEmpty := 1

            if (i > 60) {
                MsgBox % "infinite loop"
                Gdip_SaveBitmapToFile(pHaystack, "haystack.png")
                Gdip_SaveBitmapToFile(pNeedle, "needle.png")
                break
            }

        } Until (found = 0)

        Gdip_DisposeImage(pHaystack)
        Gdip_DisposeImage(pNeedle)
        Gdip_DeleteGraphics(pGraphics)
        Gdip_DeleteBrush(pBrush)
        return
    }

    addItem(item, pAnchorCell) {
        this.items.Push(item)

        Loop % item.size.rows {
            row := A_Index
            Loop % item.size.cols {
                col := A_Index
                this.grid[pAnchorCell.row + row - 1, pAnchorCell.col + col - 1].isEmpty := 1
            }
        }

        item.pAnchorCell := pAnchorCell
        item.pAnchorCell.pItem := item
        item.pAnchorCell.isEmpty := 0

    }
}

class myUI {
    moveMouse(x, y) {
        SendEvent {Click, %x%, %y%, 0}
    }
    ctrlC() {
        Clipboard := ""
        Send ^c
        ; needs some time to get the data into the clipboard
        myUI.humanDelay()
    }
    ctrlClick() {
        SendInput {Ctrl Down}{LButton}{Ctrl Up}
        myUI.humanDelay()
    }
    wisdomScrolls() {
        return {x: myRandom(120 - 15, 120 + 15), y: myRandom(220 - 15, 220 + 15)}
    }
    humanDelay() {
        RandomSleep(100, 200)
    }
}

F1::
    pGdip := Gdip_Startup()
    BlockInput On
    inv := new Inventory()

    ; load on id scrolls
    t := myUI.wisdomScrolls()
    myUI.moveMouse(t.x, t.y)
    myUI.ctrlClick()
    pSnapshot := Gdip_BitmapFromScreen()
    empty_scanned := 0
    Loop % inv.rows {
        row := A_Index
        Loop % inv.cols {
            col := A_Index
            if (inv.grid[row, col].isEmpty == 1) {
                continue
            }
            
            coords := inv.grid[row, col].fuzzyCenter()
            myUI.moveMouse(coords.x, coords.y)
            myUI.ctrlC()
            
            if (Clipboard == "") {
                inv.grid[row, col].isEmpty := 1
            }
            else {
                item := new Inventory.Item(Clipboard)
                if (item.tab == "currency") {
                    myUI.ctrlClick()
                    inv.grid[row, col].isEmpty := 1
                }
                else {

                    ; detecting unknown item size
                    if (item.size.rows == 0) {
                        size := {rows: 1, cols: 1}
                        coords := inv.grid[row, col].fuzzyTopLeft()
                        myUI.moveMouse(coords.x, coords.y)

                        while (inv.cols >= col + size.cols) {
                            coords := inv.grid[row, col + size.cols].topLeft()
                            safety_margin := Round(Inventory.PIXELS.delta * 0.20)
                            x := coords.x + safety_margin
                            y := coords.y + safety_margin
                            w := Inventory.PIXELS.delta - safety_margin * 2
                            h := Inventory.PIXELS.delta - safety_margin * 2
                            pNeedle := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
                            found := Gdip_ImageSearch(pSnapshot, pNeedle, coords, x, y, x + w, y + h , 0, "", 1, 1)
                            Gdip_DisposeImage(pNeedle)
                            if (found == 0) {
                                ; susednoto kvadrat4e se e promenilo, t.e. highlightnalo
                                ; zna4i e 4ast ot itema
                                size.cols := size.cols + 1
                            }
                            else {
                                break
                            }
                        }

                        while (inv.rows >= row + size.rows) {
                            coords := inv.grid[row  + size.rows, col].topLeft()
                            safety_margin := Round(Inventory.PIXELS.delta * 0.20)
                            x := coords.x + safety_margin
                            y := coords.y + safety_margin
                            w := Inventory.PIXELS.delta - safety_margin * 2
                            h := Inventory.PIXELS.delta - safety_margin * 2
                            pNeedle := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
                            found := Gdip_ImageSearch(pSnapshot, pNeedle, coords, x, y, x + w, y + h , 0, "", 1, 1)
                            Gdip_DisposeImage(pNeedle)
                            if (found == 0) {
                                ; susednoto kvadrat4e se e promenilo, t.e. highlightnalo
                                ; zna4i e 4ast ot itema
                                size.rows := size.rows + 1
                            }
                            else {
                                break
                            }
                        }

                        item.size := size
                    }

                    
                    if (item.tab != "") {
                        inv.addItem(item, inv.grid[row, col])
                    }
                }
            }

            if (inv.grid[row, col].isEmpty == 1 and empty_scanned == 0) {
                inv.scanEmptyFrom(inv.grid[row, col])
                empty_scanned := 1
            }
        }
    }
    Gdip_DisposeImage(pSnapshot)
    Gdip_Shutdown(pGdip)

    ; identify items
    t := myUI.wisdomScrolls()
    myUI.moveMouse(t.x, t.y)
    SendInput {Shift Down}
    SendInput {RButton}
    myUI.humanDelay() 
    For item_index, item in inv.items {
        if (item.isUnidentified == 1) {
            coords := item.pAnchorCell.fuzzyCenter()
            myUI.moveMouse(coords.x, coords.y)
            SendInput {LButton}
            myUI.humanDelay() 
        }
    }
    SendInput {Shift Up}

    ; transfer the other tabs
    tabs := ["divination", "map", "essence", "fragment", "delve"]
    For tab_index, tab_name in tabs {
        SendInput {Ctrl Down}{WheelDown}{Ctrl Up}
        myUI.humanDelay()
        For item_index, item in inv.items {
            if (item.tab == tab_name) {
                coords := item.pAnchorCell.fuzzyCenter()
                myUI.moveMouse(coords.x, coords.y)
                myUI.ctrlClick()
            }
        }
    }
    ; return to top
    SendInput {Ctrl Down}
    For tab_index, tab_name in tabs {
        SendInput {WheelUp}
        RandomSleep(30, 40) 
    }
    SendInput {Ctrl Up}
    BlockInput Off
return
