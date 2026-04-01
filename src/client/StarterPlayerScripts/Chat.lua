local TextChatService = game:GetService("TextChatService")

local Chat = {}

function Chat.init()
	TextChatService.OnIncomingMessage = Chat.BlockTeamMessage
end

-- by Haystees
function Chat.BlockTeamMessage(TextChatMessage: TextChatMessage): TextChatMessageProperties?
	local MessageProperties = Instance.new("TextChatMessageProperties")

	local MessageContent = TextChatMessage.Text
	local Source = TextChatMessage.TextSource

	-- // Check if a player sent it, if they did, then dont block it.
	if Source then
		return nil
	end

	-- // Is this system message the team message?
	local TeamMatch = string.match(MessageContent, `You are now on the '[%w]+' team.`)

	-- // If it is, just... dont show it.
	if TeamMatch then
		MessageProperties.Text = " "
	end

	return MessageProperties
end

return Chat