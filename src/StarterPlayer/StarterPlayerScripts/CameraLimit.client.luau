-- Камеру нельзя отвести слишком далеко: сверху было видно край океана Meadow и соседние миры.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
player.CameraMaxZoomDistance = 55
player.CameraMinZoomDistance = 0.5
