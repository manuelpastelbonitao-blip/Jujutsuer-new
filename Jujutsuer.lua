--[[
  JUJUTSUER v2.0 - Jujutsu Shenanigans
  Menu completo com Hit Kill, Hitbox Bug, Invisibilidade,
  Anti-Defesa, God Mode e mais.
  Pressione INSERT para abrir/fechar o menu.
]]

-- ==========================================
-- CONFIGURAÇÕES DE ABRIR/FECHAR
-- ==========================================
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

-- ToggleKeybind: INSERT para abrir/fechar
local Window = OrionLib:MakeWindow({
    Name = "Jujutsuer 🗡️ | Jujutsu Shenanigans",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "Jujutsuer",
    IntroEnabled = true,
    IntroText = "Jujutsuer v2.0"
})

-- ==========================================
-- VARIÁVEIS GLOBAIS
-- ==========================================
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Atualizar character ao respawnar
player.CharacterAdded:Connect(function(char)
    character = char
    humanoidRootPart = char:WaitForChild("HumanoidRootPart")
    humanoid = char:WaitForChild("Humanoid")
end)

-- ==========================================
-- FUNÇÕES AUXILIARES
-- ==========================================
local function getTargets(range)
    local targets = {}
    for _, otherPlayer in pairs(game.Players:GetPlayers()) do
        if otherPlayer ~= player then
            local char = otherPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                local dist = (char.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
                if dist <= range then
                    table.insert(targets, otherPlayer)
                end
            end
        end
    end
    return targets
end

local function killTarget(target)
    if not target or not target.Character then return end
    local hum = target.Character:FindFirstChild("Humanoid")
    local hrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    
    -- Bug de animação: força estado Physics (anula block/parry)
    hum:ChangeState(Enum.HumanoidStateType.Physics)
    
    -- Bug de hitbox: teletransporta o alvo pra dentro de você
    local oldPos = hrp.CFrame
    hrp.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -2.5, 0)
    
    -- Remove vida
    hum.Health = 0
    
    -- Restaura posição visual depois
    task.delay(0.12, function()
        if hrp and hrp.Parent then
            hrp.CFrame = oldPos
        end
    end)
end

-- ==========================================
-- TAB: HIT KILL
-- ==========================================
local TabHitKill = Window:MakeTab({
    Name = "Hit Kill",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local hitKillEnabled = false
local hitKillRange = 50

TabHitKill:AddToggle({
    Name = "Hit Kill Automático",
    Default = false,
    Callback = function(value)
        hitKillEnabled = value
    end
})

TabHitKill:AddSlider({
    Name = "Alcance do Hit Kill",
    Min = 10,
    Max = 300,
    Default = 50,
    Color = Color3.fromRGB(255, 0, 0),
    Increment = 5,
    ValueName = "studs",
    Callback = function(value)
        hitKillRange = value
    end
})

TabHitKill:AddButton({
    Name = "Kill All (Instantâneo)",
    Callback = function()
        for _, otherPlayer in pairs(game.Players:GetPlayers()) do
            if otherPlayer ~= player then
                killTarget(otherPlayer)
            end
        end
    end
})

TabHitKill:AddButton({
    Name = "Kill Todos no Alcance",
    Callback = function()
        for _, target in pairs(getTargets(hitKillRange)) do
            killTarget(target)
        end
    end
})

-- Loop Hit Kill
coroutine.wrap(function()
    while task.wait(0.15) do
        if hitKillEnabled and humanoidRootPart and humanoidRootPart.Parent then
            for _, target in pairs(getTargets(hitKillRange)) do
                killTarget(target)
            end
        end
    end
end)()

-- ==========================================
-- TAB: HITBOX BUG
-- ==========================================
local TabHitbox = Window:MakeTab({
    Name = "Hitbox Bug",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local hitboxExpanded = false
local hitboxSize = 15
local originalSizes = {}

local function expandHitbox()
    originalSizes = {}
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            originalSizes[part] = part.Size
            part.Size = part.Size * hitboxSize
            part.Transparency = 0.9
            part.CanCollide = false
            part.Massless = true
        end
    end
end

local function restoreHitbox()
    for part, origSize in pairs(originalSizes) do
        if part and part.Parent then
            part.Size = origSize
            part.Transparency = 0
            part.CanCollide = true
            part.Massless = false
        end
    end
    originalSizes = {}
end

TabHitbox:AddToggle({
    Name = "Expandir Hitbox (Bug)",
    Default = false,
    Callback = function(value)
        hitboxExpanded = value
        if value then expandHitbox() else restoreHitbox() end
    end
})

TabHitbox:AddSlider({
    Name = "Multiplicador da Hitbox",
    Min = 2,
    Max = 100,
    Default = 15,
    Color = Color3.fromRGB(255, 255, 0),
    Increment = 1,
    ValueName = "x",
    Callback = function(value)
        hitboxSize = value
        if hitboxExpanded then
            restoreHitbox()
            expandHitbox()
        end
    end
})

-- ==========================================
-- TAB: INVISIBILIDADE
-- ==========================================
local TabInvis = Window:MakeTab({
    Name = "Invisibilidade",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local invisEnabled = false
local originalTransparencies = {}

local function makeInvisible()
    originalTransparencies = {}
    
    -- Deixa o personagem transparente (bug visual)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            originalTransparencies[part] = part.Transparency
            part.Transparency = 1
        end
        if part:IsA("Decal") or part:IsA("Texture") then
            originalTransparencies[part] = part.Transparency
            part.Transparency = 1
        end
    end
    
    -- Remove acessórios (hats, etc) que podem ficar visíveis
    for _, accessory in pairs(character:GetChildren()) do
        if accessory:IsA("Accessory") or accessory:IsA("Hat") or accessory:IsA("Hair") then
            accessory:Destroy()
        end
    end
    
    -- Remove o nome do player
    if character:FindFirstChild("Head") then
        local head = character.Head
        if head:FindFirstChildOfClass("BillboardGui") then
            head:FindFirstChildOfClass("BillboardGui"):Destroy()
        end
    end
    
    -- Usa bug de animação: força estado Swimming debaixo do mapa
    -- No JJS, o estado Swimming com transparency = 1 faz o jogo não renderizar o personagem
    humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
    
    -- Move o root part pra baixo do mapa levemente (bug de render)
    humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.new(0, -5, 0)
end

local function restoreVisibility()
    for part, origTrans in pairs(originalTransparencies) do
        if part and part.Parent then
            part.Transparency = origTrans
        end
    end
    originalTransparencies = {}
    
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

TabInvis:AddToggle({
    Name = "Invisibilidade (Bug)",
    Default = false,
    Callback = function(value)
        invisEnabled = value
        if value then makeInvisible() else restoreVisibility() end
    end
})

TabInvis:AddParagraph({
    Title = "Sobre o Bug",
    Content = "Usa técnica de transparency total + estado Swimming\npara esconder o personagem dos outros jogadores.\nBaseado nos glitches reais do JJS."
})

-- ==========================================
-- TAB: ANIMAÇÃO BUG
-- ==========================================
local TabAnim = Window:MakeTab({
    Name = "Anti-Defesa",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local antiDefenseEnabled = false

TabAnim:AddToggle({
    Name = "Bug de Animação (Anti-Block/Parry)",
    Default = false,
    Callback = function(value)
        antiDefenseEnabled = value
    end
})

TabAnim:AddParagraph({
    Title = "Como funciona",
    Content = "Força constantemente o estado GettingUp\nnos inimigos, anulando qualquer animação\nde defesa (block, parry, dodge)."
})

-- Loop Anti-Defesa
coroutine.wrap(function()
    while task.wait(0.08) do
        if antiDefenseEnabled then
            for _, otherPlayer in pairs(game.Players:GetPlayers()) do
                if otherPlayer ~= player then
                    local char = otherPlayer.Character
                    if char then
                        local hum = char:FindFirstChild("Humanoid")
                        if hum and hum.Health > 0 then
                            hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
                            task.wait(0.03)
                            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                        end
                    end
                end
            end
        end
    end
end)()

-- ==========================================
-- TAB: EXTRAS
-- ==========================================
local TabExtras = Window:MakeTab({
    Name = "Extras",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- God Mode
local godModeEnabled = false

TabExtras:AddToggle({
    Name = "God Mode (Vida Infinita)",
    Default = false,
    Callback = function(value)
        godModeEnabled = value
        local hum = character:FindFirstChild("Humanoid")
        if hum then
            if value then
                hum.MaxHealth = 9e9
                hum.Health = 9e9
            else
                hum.MaxHealth = 100
                hum.Health = 100
            end
        end
    end
})

-- Anti-Stun
local antiStunEnabled = false

TabExtras:AddToggle({
    Name = "Anti-Stun (Sem Stunlock)",
    Default = false,
    Callback = function(value)
        antiStunEnabled = value
    end
})

coroutine.wrap(function()
    while task.wait(0.05) do
        if antiStunEnabled and humanoid and humanoid.Parent then
            if humanoid:GetState() == Enum.HumanoidStateType.Freefall or
               humanoid:GetState() == Enum.HumanoidStateType.Physics then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
end)()

-- WalkSpeed
local wsSlider

TabExtras:AddSlider({
    Name = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Color = Color3.fromRGB(0, 255, 200),
    Increment = 1,
    ValueName = "WS",
    Callback = function(value)
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end
})

-- JumpPower
TabExtras:AddSlider({
    Name = "JumpPower",
    Min = 50,
    Max = 300,
    Default = 50,
    Color = Color3.fromRGB(200, 0, 255),
    Increment = 5,
    ValueName = "JP",
    Callback = function(value)
        if humanoid then
            humanoid.JumpPower = value
        end
    end
})

-- Teleport para Jogador
TabExtras:AddButton({
    Name = "Teleportar para Jogador...",
    Callback = function()
        local playerList = {}
        for _, v in pairs(game.Players:GetPlayers()) do
            if v ~= player then
                table.insert(playerList, v.Name)
            end
        end
        
        if #playerList == 0 then
            OrionLib:MakeNotification({Name = "Erro", Content = "Nenhum jogador no servidor!", Time = 3})
            return
        end
        
        local chosen = OrionLib:PromptList("Selecione o Jogador", playerList, 0)
        task.wait(0.5)
        
        if chosen and game.Players:FindFirstChild(chosen) then
            local targetChar = game.Players[chosen].Character
            if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                humanoidRootPart.CFrame = targetChar.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
                OrionLib:MakeNotification({
                    Name = "Teleportado",
                    Content = "Teleportado para " .. chosen,
                    Time = 2
                })
            end
        end
    end
})

-- ==========================================
-- TAB: INFO
-- ==========================================
local TabInfo = Window:MakeTab({
    Name = "Info",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

TabInfo:AddParagraph({
    Title = "Jujutsuer v2.0",
    Content = "Menu completo para Jujutsu Shenanigans\n\nControles:\nINSERT = Abrir/Fechar menu\n\nFuncionalidades:\n- Hit Kill Automático\n- Hitbox Expander (Bug)\n- Invisibilidade (Bug)\n- Anti-Defesa (Bug de Animação)\n- God Mode\n- Anti-Stun\n- WalkSpeed / JumpPower\n- Teleport para Jogador\n- Kill All\n\nPara testes de segurança autorizados."
})

TabInfo:AddButton({
    Name = "Fechar Menu",
    Callback = function()
        OrionLib:Destroy()
    end
})

-- ==========================================
-- INICIALIZAÇÃO
-- ==========================================
OrionLib:Init()

-- Notificação de boas-vindas
OrionLib:MakeNotification({
    Name = "Jujutsuer Carregado!",
    Content = "Pressione INSERT para abrir/fechar o menu",
    Time = 4
})

-- Toggle por tecla INSERT
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        if OrionLib and OrionLib.Flags then
            OrionLib:Toggle()
        end
    end
end)
