local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

return function(UI)
    local player = Players.LocalPlayer
    local C = UI.Colors
    local enabled = false
    local generation = 0
    local delaySeconds = 1

    local function update()
        UI.Toggle.BackgroundColor3 = enabled
            and C.pink
            or Color3.fromRGB(65, 45, 65)

        UI.Knob.Position = UDim2.fromOffset(
            enabled and 36 or 4, 4
        )

        UI.Status.Text = enabled and "STATUS: ON" or "STATUS: OFF"
        UI.Status.TextColor3 = enabled and C.green or C.muted

        UI.Description.Text = enabled
            and "Auto Roll is running."
            or "Automatically request card rolls."
    end

    local function stop(reason)
        if not enabled then return end

        enabled = false
        generation += 1
        update()

        UI.Status.Text = "STATUS: STOPPED"
        UI.Status.TextColor3 = C.green
        UI.Hint.Text = reason
    end

    local function matches(text)
        if typeof(text) ~= "string" then return false end
        local clean = text:lower():gsub("[%s_%-]", "")
        return clean:find("magepack", 1, true) ~= nil
    end

    local function check(inst)
        if not UI.GUI.Parent or not enabled then return end
        if inst:IsDescendantOf(UI.GUI) then return end

        local found = matches(inst.Name)

        if not found and (
            inst:IsA("TextLabel") or inst:IsA("TextButton")
        ) then
            found = matches(inst.Text)
        elseif not found and inst:IsA("StringValue") then
            found = matches(inst.Value)
        end

        if found then
            stop("Mage Pack found! Auto Roll stopped.")
        end
    end

    local function watch(root)
        for _, inst in ipairs(root:GetDescendants()) do
            check(inst)
        end

        root.DescendantAdded:Connect(function(inst)
            check(inst)

            if inst:IsA("TextLabel") or inst:IsA("TextButton") then
                inst:GetPropertyChangedSignal("Text"):Connect(function()
                    check(inst)
                end)
            elseif inst:IsA("StringValue") then
                inst:GetPropertyChangedSignal("Value"):Connect(function()
                    check(inst)
                end)
            end
        end)
    end

    watch(workspace)
    watch(player:WaitForChild("PlayerGui"))

    UI.Toggle.Activated:Connect(function()
        enabled = not enabled
        generation += 1
        local myGeneration = generation

        if not enabled then
            UI.Hint.Text = "Auto Roll has been stopped."
            update()
            return
        end

        UI.Hint.Text = "Auto Roll requests every 1 second."
        update()

        task.spawn(function()
            while enabled
            and generation == myGeneration
            and UI.GUI.Parent do

                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                local remote = remotes
                    and remotes:FindFirstChild("RequestConveyorRoll")

                if not remote or not remote:IsA("RemoteEvent") then
                    enabled = false
                    generation += 1
                    update()

                    UI.Status.Text = "STATUS: REMOTE NOT FOUND"
                    UI.Status.TextColor3 = C.red
                    UI.Hint.Text = "Check the game's remote configuration."
                    break
                end

                local ok = pcall(function()
                    remote:FireServer()
                end)

                if not ok then
                    stop("Roll request failed.")
                    break
                end

                task.wait(delaySeconds)
            end
        end)
    end)

    UI.GUI.Destroying:Connect(function()
        enabled = false
        generation += 1
    end)
end
