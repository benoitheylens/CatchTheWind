local Addon = CreateFrame("FRAME");

--Main UI Frame
local letterBox;
--Variable Quest Text Speed
local factorTextSpeed = 1;

--TODO
--CatchTheWind
--
-- Cinematic Quests AddOn
--x * GetTitleText + GetProgressText + GetObjectiveText + GetRewardText
-- * Set a close-plan to player when deciding "ACCEPT/DECLINE" and choosing rewards. (check for libCameras)
--x * Mouse-Click shows all the message (if it's still animating). Another click passes to the next line.
-- * SpaceBar shows all the message. This may bring problems because we have to enable keyboard.
-- * Set buttons in the middle
-- * PrevQuestText shouldn't fadeIn everytime you click
--
--
-- * Start to think in moving GUI (frames and buttons) to a XML file

-- BUGS:
--x * SaveView cancels auto-follow cam. Disable it and use default cams. Add an option in the future for players who want to enable it.

--x = Done/Fixed

--------------------
--UTILS
--------------------


-------------------------------------
--
-- Prints the given string at yellow.
-- If it contains "CatchTheWind" then it colors it in a gray gradient.
-- Used in SlashCommands.
-- @param #string msg : the message that will be printed
--
-------------------------------------
local function printMessage(msg)
	if(string.find(msg, "CatchTheWind")) then
		local msg = string.sub(msg, string.find(msg, "CatchTheWind")+12, -1);
		print("|cff777777Ca|cffaaaaaatc|cffcccccchTh|cffccccccW|cffaaaaaain|cff777777d|cffffff66"..msg);
	else
		print("|cffffff66"..msg);
	end
end


--Timer Frame
local timer = CreateFrame("FRAME");
-------------------------------------
--
-- Creates a timer. After the specified time, it will execute the given function.
-- @param #number after : the message that will be printed
-- @param #function func : the message that will be printed
--
-------------------------------------
local function createTimer(after, func)
	local total = 0;
	timer:SetScript("OnUpdate", function(self, elapsed)
		total = total + elapsed;
		if(total > after) then
			self:SetScript("OnUpdate", nil);
			func();
		end
	end);
end


-------------------------------------
--
-- Cancels the timer.
--
-------------------------------------
local function cancelTimer()
	timer:SetScript("OnUpdate", nil);
end


-------------------------------------
--
-- Splits the given text (string with \n (aka "Enter")).
-- It returns a table, in each entry is paragraph from the text.
-- @param #string text : the string that will be splitted
-- @return #table tableLines: the table with the lines from the text
--
-------------------------------------
local function splitText(text)
	local tableLines, nextLine = {};
	while string.find(text,"\n") do
		nextLine = string.sub(text,0, string.find(text, "\n"));
		if not (strtrim(nextLine) == "") then
			table.insert(tableLines, nextLine);
		end
		text = string.sub(text, string.find(text, "\n")+1, -1);	
	end
	if not (strtrim(text) == "") then
		table.insert(tableLines, string.sub(text, 0, string.find(text, "\n")));
	end
	return tableLines;
end


-------------------------------------
--
-- Creates a button with the given values.
-- This button is a "FRAME" with a "FontString".
-- Used to create the "Accept"/"Decline" buttons.
-- @param #string name : the button's name
-- @param #frame parent : the frame that will be attached
-- @param #function onClickFunc : the function that will be executed whenever this button is pressed
-- @return #frame buttonFrame: the button itself
--
-------------------------------------
local function createButton(name, parent, text, onClickFunc)
	local buttonFrame = CreateFrame("FRAME", name, parent);
	buttonFrame:SetSize(200,50);
	
	buttonFrame.fontString = buttonFrame:CreateFontString();
	buttonFrame.fontString:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE");
	buttonFrame.fontString:SetText(text);
	buttonFrame.fontString:SetTextColor(0.45, 0.45, 0.45, 1);
	buttonFrame.fontString:SetPoint("CENTER");
	
	buttonFrame:EnableMouse(true);
	buttonFrame:SetScript("OnMouseUp", onClickFunc);
	buttonFrame:SetScript("OnEnter", function(self)
		self.fontString:SetTextColor(1, 1, 1, 1);
	end);
	buttonFrame:SetScript("OnLeave", function(self)
		self.fontString:SetTextColor(0.45, 0.45, 0.45, 1);
	end);
	
	buttonFrame:SetScript("OnShow", function(self)
		UIFrameFadeIn(self, 0.5, 0, 1);
	end);
	
	buttonFrame:Hide();
	
	return buttonFrame;
end


--Frame, Boolean
local animationFrame, isAnimating = CreateFrame("FRAME");
-------------------------------------
--
-- Animates the given fontString.
-- Uses "SetAlphaGradient" in order to fade in the text.
-- @param #fontString fontString : the fontString that will be animated
--
-------------------------------------
local function animateText(fontString)
	local total, numChars = 0, 0;
	fontString:SetAlphaGradient(0,20);
	isAnimating = true;
	animationFrame:SetScript("OnUpdate", function(self, elapsed)
		numChars = numChars + 0.25*factorTextSpeed;
		fontString:SetAlphaGradient(numChars,20);
		if(numChars >= string.len(fontString:GetText() or "")) then
			isAnimating = false;
			self:SetScript("OnUpdate", nil);
		end
	end);
end


-------------------------------------
--
-- Checks if the text is being animated.
-- If the text is "full-shown" then it will return false.
-- @return #boolean isAnimating : true, if the animation is ON
--
-------------------------------------
local function isTextAnimating()
	return isAnimating;
end


--Storing SetView function (Blizzard's function)
local blizz_SetView = SetView;
--Current view
local currentView = -1;
-------------------------------------
--
-- Sets a view.
-- It checks first, if the view that will be set is the current one.
-- This prevents instant changes (i.e. no smooth movement).
-- @param #number view: the desired view [1-5]
--
-------------------------------------
local function SetView(view)
	if not (view == currentView) then
		currentView = view;
		blizz_SetView(view);
	end
end


-------------------------------
--/UTILS
-------------------------------



--Frame Fader
local frameFader = CreateFrame("FRAME");

-------------------------------------
--
-- Hides the letterbox and its containers.
-- It fades out the frame and its containers.
-- Also, it fades in the UIParent.
--
-------------------------------------
local function hideLetterBox()
	if(not letterBox:IsShown()) then
		return;
	end
	--UIFrameFadeIn(UIParent, 0.25, 0, 1);	It's not advised to use UIFrameFade on "UIParent" because it taints the code
	local alpha = UIParent:GetAlpha();
	MinimapCluster:Show();
	WorldFrame:SetFrameStrata("WORLD");
	frameFader:SetScript("OnUpdate", function(self, elapsed)
		if(alpha < 1) then
			alpha = alpha + 0.05;
			UIParent:SetAlpha(alpha);
		else
			frameFader:SetScript("OnUpdate", nil);
		end
	
	end);
	
	UIFrameFadeOut(letterBox, 0.25, 1, 0);
	local total = 0;
	letterBox:SetScript("OnUpdate", function(self, elapsed)
		total = total + elapsed;
		if(total > 0.25) then
			letterBox:SetScript("OnUpdate", nil);
			letterBox:Hide();
		end
	end);
	letterBox:EnableKeyboard(false);
end


-------------------------------------
--
-- Shows the letterbox and its containers.
-- It also sets the UIParent's alpha to 0.
--
-------------------------------------
local function showLetterBox()
	if(IsModifierKeyDown()) then
		return;
	end
	UIParent:SetAlpha(0);
	WorldFrame:SetFrameStrata("FULLSCREEN");
	MinimapCluster:Hide(); --Minimap icons aren't affected with "SetAlpha"
	
	UIFrameFadeIn(letterBox, 0.25, 0, 1);
	letterBox.selectedButton = nil;
	letterBox:EnableKeyboard(true);
end


-------------------------------------
--
-- Inits the interaction with the NPC after choosing a quest.
-- Used when QuestEvents triggers.
--
-------------------------------------
local function startInteraction()
	letterBox.acceptButton:Hide();
	letterBox.declineButton:Hide();
	
	letterBox.rewardPanel:Hide();
	
	letterBox.text = splitText(letterBox.text);
	letterBox.textIndex = 1;
	letterBox.prevQuestText:SetText("");
	letterBox.questText:SetText(letterBox.text[letterBox.textIndex]);
	animateText(letterBox.questText);
end


--In the next update, this will be moved to XML
-------------------------------------
--
-- Creates Quest Reward Panel and all its containers.
-- Used in "setUpLetterBox" function.
--
-------------------------------------
local function createQuestRewardPanel()

	--quest reward panel
	letterBox.rewardPanel = CreateFrame("FRAME", "CTWrewardPanel", letterBox);
	local rewardPanel = letterBox.rewardPanel;	--referencing to smaller name
	rewardPanel:SetSize(600,100);
	rewardPanel:SetPoint("TOP", letterBox.bottomPanel, 0, 100);
	
	--creating background textures (some a gradient that fades in and out)
	rewardPanel.textureCenter = rewardPanel:CreateTexture(nil, "BACKGROUND");
	rewardPanel.textureCenter:SetSize(200,100);
	rewardPanel.textureCenter:SetTexture(0,0,0);
	rewardPanel.textureCenter:SetAlpha(0.9);
	rewardPanel.textureCenter:SetPoint("CENTER");
	
	rewardPanel.textureLeft = rewardPanel:CreateTexture(nil, "BACKGROUND");
	rewardPanel.textureLeft:SetSize(200,100);
	rewardPanel.textureLeft:SetTexture(0,0,0);
	rewardPanel.textureLeft:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0, 0, 0, 0, 0.9);
	rewardPanel.textureLeft:SetPoint("LEFT");
	
	rewardPanel.textureRight = rewardPanel:CreateTexture(nil, "BACKGROUND");
	rewardPanel.textureRight:SetSize(200,100);
	rewardPanel.textureRight:SetTexture(0,0,0);
	rewardPanel.textureRight:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0.9, 0, 0, 0, 0);
	rewardPanel.textureRight:SetPoint("RIGHT");
	
		
	--quest reward panel title
	letterBox.rewardPanel.title = letterBox.rewardPanel:CreateFontString();
	letterBox.rewardPanel.title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE");
	letterBox.rewardPanel.title:SetTextColor(1, 1, 1, 1);
	letterBox.rewardPanel.title:SetText("Choose your reward");
	letterBox.rewardPanel.title:SetPoint("TOP", 0, -12);
	
	--quest reward items buttons(blizz has 10 buttons)
	--refactor > extract code
	
	for i=1, 10 do
		CreateFrame("BUTTON", "CTWrewardPanelItem"..i, letterBox.rewardPanel, "CTWItemButtonTemplate");
	end
	
	letterBox.rewardPanel:Hide();
end


local function onClickKey(self)
	if(not isTextAnimating() and (self.textIndex == #self.text or #self.text == 0)) then
	
		if(self.acceptButton.fontString:GetText() == "Continue") then
			if(IsQuestCompletable()) then
				self.acceptButton:Show();
			else
				self.acceptButton:Hide();
			end
		else
			self.acceptButton:Show();
		end

		if(self.acceptButton.fontString:GetText() == "Thank you" and 
		self.textIndex == #self.text and GetNumQuestChoices() > 0 and
		not self.rewardPanel:IsShown()) then
			UIFrameFadeIn(self.rewardPanel, 0.5, 0, 1);
		end
		
		self.declineButton:Show();
		
		--checks if the questText is not empty, then hides the text and makes
		if(self.questText:GetText()) then
			--hides questText
			self.questText:SetText("");
			--show oldText
			self.prevQuestText:SetText(self.text[self.textIndex]);
			UIFrameFadeIn(self.prevQuestText, 0.5, 0, 1);
		end
		
		--rearrange buttons
		local screenHeight = GetScreenHeight()*UIParent:GetEffectiveScale();
		if(self.acceptButton:IsShown()) then
			self.acceptButton:SetPoint("BOTTOM", 100, screenHeight/28);
			self.declineButton:SetPoint("BOTTOM", -100, screenHeight/28);
		else
			self.declineButton:SetPoint("BOTTOM", 0, screenHeight/28);
		end
		
		
		return;
	end
	--checks if the text is fading in, if yes, shows the rest.
	if(isTextAnimating()) then
		self.questText:SetAlphaGradient(string.len(self.questText:GetText()),1);
		isAnimating = false;
		animationFrame:SetScript("OnUpdate", nil);
	else
		self.prevQuestText:SetText(self.text[self.textIndex]);
		UIFrameFadeIn(self.prevQuestText, 0.5, 0, 1);
		self.textIndex = self.textIndex + 1;
		self.questText:SetText(self.text[self.textIndex]);
		animateText(self.questText);
	end
end

-------------------------------------
--
-- Sets up all the frames for letterbox.
--
-------------------------------------
local function setUpLetterBox()
	local screenWidth = GetScreenWidth()*UIParent:GetEffectiveScale();
	local screenHeight = GetScreenHeight()*UIParent:GetEffectiveScale();
	
	letterBox = CreateFrame("FRAME", "CatchTheWind", WorldFrame);
	letterBox:SetAllPoints();
	
	letterBox:SetFrameStrata("FULLSCREEN_DIALOG");
	letterBox:SetFrameLevel(10);
	
	letterBox.bottomPanel = letterBox:CreateTexture();
	letterBox.bottomPanel:SetTexture(0,0,0);
	letterBox.bottomPanel:SetSize(screenWidth, screenHeight/7);
	letterBox.bottomPanel:SetPoint("BOTTOM");
	
	letterBox.topPanel = letterBox:CreateTexture();
	letterBox.topPanel:SetTexture(0,0,0);
	letterBox.topPanel:SetSize(screenWidth, screenHeight/7);
	letterBox.topPanel:SetPoint("TOP");
	
	
	letterBox.questText = letterBox:CreateFontString(nil, "OVERLAY");
	letterBox.questText:SetSize(screenWidth*0.75, screenHeight/7)
	letterBox.questText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE"); --WoW Font
	letterBox.questText:SetTextColor(0.9, 0.9, 0.9, 1);
	letterBox.questText:SetPoint("BOTTOM", 0, 0);
	
	--fontString that shows the previous quest text, the previous line that the player read
	letterBox.prevQuestText = letterBox:CreateFontString(nil, "OVERLAY");
	letterBox.prevQuestText:SetSize(screenWidth*0.75, screenHeight/7)
	letterBox.prevQuestText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE"); --WoW Font
	letterBox.prevQuestText:SetTextColor(0.5, 0.5, 0.5, 1);
	letterBox.prevQuestText:SetPoint("TOP", 0, 0);
	
	
	createQuestRewardPanel();
	
	
	letterBox.acceptButton = createButton("CTWacceptButton", letterBox, "Accept", "BOTTOMRIGHT", function(self, button)
		QuestDetailAcceptButton_OnClick();
	end);

	letterBox.declineButton = createButton("CTWdeclineButton", letterBox, "Decline", "BOTTOMLEFT", function(self, button)
		QuestDetailDeclineButton_OnClick();
	end);
	
	
	letterBox:Hide();
	
	--set up script for mouse clicks
	letterBox:SetScript("OnMouseUp", function(self, button)		
		onClickKey(self);
	end);
	

	letterBox:SetScript("OnKeyUp", function(self, key)
		--SPACE, ESCAPE, A, D
		if(key == "SPACE") then
			if(self.selectedButton and (self.acceptButton:IsShown() or self.declineButton:IsShown())) then
				self.selectedButton:GetScript("OnMouseUp")();
			else
				onClickKey(self);
			end
		elseif(key == "ESCAPE") then
			securecall("CloseAllWindows");
		elseif(key == "D" and self.acceptButton:IsShown()) then
			self.selectedButton = self.acceptButton;
			self.acceptButton.fontString:SetTextColor(1, 1, 1, 1);
			self.declineButton.fontString:SetTextColor(0.45, 0.45, 0.45, 1);
		elseif(key == "A" and self.declineButton:IsShown()) then
			self.selectedButton = self.declineButton;
			self.declineButton.fontString:SetTextColor(1, 1, 1, 1);
			self.acceptButton.fontString:SetTextColor(0.45, 0.45, 0.45, 1);
		elseif(key == "F10") then
			ReloadUI();
		end
	end);
	
	
	--DECRECATED (events will now handle visibility) - Still gonna keep this if future bugs arise.
	--[[
	QuestFrame:HookScript("OnHide", function()
		--hideLetterBox();
	end);
	]]--
	
end


-------------------------------------
--
-- Load SavedVariables.
-- If there is no SVs, then it creates them.
--
-------------------------------------
local function loadSavedVariables()
	if(not CatchTheWindSV) then
		CatchTheWindSV = {};
		CatchTheWindSV[UnitName("player")] = {};
		CatchTheWindSV[UnitName("player")]["FactorTextSpeed"] = 1;
	elseif(CatchTheWindSV[UnitName("player")]) then
		factorTextSpeed = CatchTheWindSV[UnitName("player")]["FactorTextSpeed"];
	else
		CatchTheWindSV[UnitName("player")] = {};
		CatchTheWindSV[UnitName("player")]["FactorTextSpeed"] = 1;
	end
end



------------
--ADDON SCRIPTS
--
--Some funcitons that will be used later for events.

local function onPlayerLogin()
	--SaveView(5);		--SaveView completely disables the auto-follow camera
	--Very strange, I need to do reset all views in order for the camera to follow the player.
	--Even if I don't use Set/Save_View, I still need to do this...
	--Also, sometimes new characters are "born" with this bug.
	
	--From what I've seen (and a player also confirmed it), only deleting the folder will fix the issue.
	
	--PROGRESS:
	--ResetView(i), only reset the view, it doesn't really saves it in the end. So, a SaveView() must be done after.
	
	
--	for i=1,5 do
--		ResetView(i);
--	end
	setUpLetterBox();
	loadSavedVariables();
end

local function onGossipShow()
	cancelTimer();
	SetView(2);
end


local function onQuestDetail()
	cancelTimer();
	SetView(2);
	letterBox.text = GetQuestText();
	
	letterBox.acceptButton.fontString:SetText("Accept");
	letterBox.acceptButton:SetScript("OnMouseUp", function(self, button)
		QuestDetailAcceptButton_OnClick();
		--hideLetterBox();
	end);
	letterBox.declineButton.fontString:SetText("Decline");
	letterBox.declineButton:SetScript("OnMouseUp", function(self, button)
		QuestDetailDeclineButton_OnClick();
		--hideLetterBox();
	end);
	
	showLetterBox();
	
	startInteraction();
end


local function onQuestProgress()
	cancelTimer();
	SetView(2);
	letterBox.text = GetProgressText();
	
	letterBox.acceptButton.fontString:SetText("Continue");
	letterBox.acceptButton:SetScript("OnMouseUp", QuestProgressCompleteButton_OnClick);
	
	letterBox.declineButton.fontString:SetText("Goodbye");
	
	showLetterBox();
	
	startInteraction();
end


local function onQuestComplete()
	cancelTimer();
	if(not letterBox:IsShown()) then
		showLetterBox();
	end
	
	letterBox.text = GetRewardText();
	
	startInteraction();
	
	letterBox.acceptButton.fontString:SetText("Thank you");
	letterBox.acceptButton:SetScript("OnMouseUp", function(self, button)
		if(QuestInfoFrame.itemChoice == 0 and GetNumQuestChoices() > 0 ) then
			UIFrameFlash(letterBox.rewardPanel, 0.5, 0.5, 1.5, true, 0, 0);
		else
			QuestRewardCompleteButton_OnClick();
			--hideLetterBox();
		end
	end);
	
	letterBox.declineButton.fontString:SetText("Goodbye");
	
	--if there is quest rewards to choose > show quest rewards
	if(GetNumQuestChoices() > 0) then
		local btn;
		
		--show icons of quests rewards
		for i=1, GetNumQuestChoices() do
			btn = _G["CTWrewardPanelItem"..i];
			
			local name, texture, numItems, quality, isUsable = GetQuestItemInfo(btn.type, i);
			SetItemButtonTexture(btn, texture);
			_G[btn:GetName().."IconTexture"]:SetVertexColor(0.35,0.35,0.35,1);

			btn:SetPoint("CENTER", (i-1)*64-(GetNumQuestChoices()/2*64)+32, -12)

			btn:SetID(i);
			btn:Show();
		end
		
		--hide remain unused frames
		for i=GetNumQuestChoices()+1, 10 do
			_G["CTWrewardPanelItem"..i]:Hide();
		end
		
		--letterBox.rewardPanel:Show();
	else
		letterBox.rewardPanel:Hide();
	end
end


--Table with the scripts
Addon.scripts = {
	["PLAYER_LOGIN"] = onPlayerLogin,
	["GOSSIP_SHOW"] = onGossipShow,
	["QUEST_DETAIL"] = onQuestDetail,
	["QUEST_PROGRESS"] = onQuestProgress,
	["QUEST_COMPLETE"] = onQuestComplete,
};


--/ADDON SCRIPTS
------------


--Slash Commands available to players
SLASH_CatchTheWind1, SLASH_CatchTheWind2 = "/catchthewind", "/ctw";

-------------------------------------
--
-- SlashCommand function.
-- Commands implemented:
-- 						- textSpeed
-- @param #string cmd : the command that the player inputs
--
-------------------------------------
local function SlashCmd(cmd)
    if (cmd:match"textSpeed") then
        local factor = tonumber(strtrim(cmd:sub(cmd:find("textSpeed")+9, -1)));
		factorTextSpeed = factor;
		CatchTheWindSV[UnitName("player")]["FactorTextSpeed"] = factor;
		printMessage("CatchTheWind: The text speed is now "..factor.."x faster than the default speed.");
    else
    	printMessage("CatchTheWind Commands:");
    	printMessage("      /ctw textSpeed x -> where x is the factor.");
    end
end

SlashCmdList["CatchTheWind"] = SlashCmd;


-------------------------------------
--
-- Addon SetScript OnEvent
-- Starts up the addOn.
-- Handled events can be checked right after this function.
--
-------------------------------------
Addon:SetScript("OnEvent", function(self, event)
	if(Addon.scripts[event]) then
		Addon.scripts[event]();
	elseif(event == "GOSSIP_CLOSED" or event == "MERCHANT_CLOSED" or event == "TRAINER_CLOSED" or event == "TAXIMAP_CLOSED" or event == "QUEST_FINISHED") then
		--a timer is needed because when interacting with merchants/trainers or choosing quests, "GOSSIP_CLOSED" will be
		--triggered and right after a "MERCHANT_SHOW" will pop up and cancel this timer.
		letterBox.rewardPanel:Hide();
		hideLetterBox();
		createTimer(0.05, function()
			SetView(5);
		end);
	elseif(event == "MERCHANT_SHOW" or event == "TRAINER_SHOW" or event == "TAXIMAP_OPENED") then
		cancelTimer();
	end
end);


--NOTES (How quest events works):
--Accepting a quest:
--QUEST_DETAIL > QUEST_FINISHED > QUEST_ACCEPTED (in the end, it doesn't show the quest frame)

--Declining a quest:
--QUEST_DETAIL > QUEST_FINISHED > GOSSIP_SHOW (in the end, it shows the quest frame)

--Declining a quest by pressing ESC:
--QUEST_DETAIL > QUEST_FINISHED (in the end, it doesn't show the quest frame)

--Checking an accepted quest and cancel it:
--QUEST_PROGRESS > QUEST_FINISHED > GOSSIP_SHOW (in the end, it shows the quest frame)


Addon:RegisterEvent("GOSSIP_SHOW");
Addon:RegisterEvent("MERCHANT_SHOW");
Addon:RegisterEvent("TRAINER_SHOW");
Addon:RegisterEvent("TAXIMAP_OPENED");

Addon:RegisterEvent("GOSSIP_CLOSED");
Addon:RegisterEvent("MERCHANT_CLOSED");
Addon:RegisterEvent("TRAINER_CLOSED");
Addon:RegisterEvent("TAXIMAP_CLOSED");

Addon:RegisterEvent("QUEST_DETAIL");
Addon:RegisterEvent("QUEST_PROGRESS");
Addon:RegisterEvent("QUEST_COMPLETE");
Addon:RegisterEvent("QUEST_ACCEPTED");
Addon:RegisterEvent("QUEST_FINISHED");

Addon:RegisterEvent("PLAYER_LOGIN");