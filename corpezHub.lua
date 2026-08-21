-- ╔══════════════════════════════╗
-- ║       corpez Hub v1          ║
-- ║       by corpez              ║
-- ╚══════════════════════════════╝

local sg = Instance.new("ScreenGui", game.CoreGui)
local lbl = Instance.new("TextLabel", sg)
lbl.Size = UDim2.new(0, 280, 0, 35)
lbl.Position = UDim2.new(0.5,-140,0,8)
lbl.BackgroundColor3 = Color3.fromRGB(10,10,10)
lbl.TextColor3 = Color3.fromRGB(255,70,70)
lbl.Text = "corpez Hub — Loading..."
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 16
lbl.BorderSizePixel = 0

task.wait(2)
lbl.Text = "corpez Hub — Ready ✓"
task.wait(1)
lbl:Destroy()

loadstring(game:HttpGet("https://raw.githubusercontent.com/huy384/redzHub/refs/heads/main/redzHub.lua"))()
