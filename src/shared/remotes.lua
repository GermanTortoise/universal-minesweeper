--!strict
-- Stolen from Nidoxs from ROSS server

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"
local IS_CLIENT = RunService:IsClient()

local remoteFolder = if IS_CLIENT
	then ReplicatedStorage:WaitForChild(FOLDER_NAME)
	else ReplicatedStorage:FindFirstChild(FOLDER_NAME)

remoteFolder = remoteFolder or Instance.new("Folder")
remoteFolder.Name = FOLDER_NAME
remoteFolder.Parent = ReplicatedStorage

local function _getRemoteInstance(
	remoteName: string,
	type: "RemoteEvent" | "RemoteFunction"
): RemoteEvent | RemoteFunction
	local remote

	if IS_CLIENT then
		remote = remoteFolder:WaitForChild(remoteName)
	else
		remote = remoteFolder:FindFirstChild(remoteName)
	end

	if not remote then
		remote = Instance.new(type)
		remote.Name = remoteName
		remote.Parent = remoteFolder
	end

	return remote
end

local function _getBindableInstance(remoteName: string, type: "BindableEvent" | "BindableFunction")
	local bindable = remoteFolder:FindFirstChild(remoteName)
	if not bindable then
		bindable = Instance.new(type)
		bindable.Name = remoteName
		bindable.Parent = remoteFolder
	end

	return bindable
end

local function getEvent(eventName: string): RemoteEvent
	return _getRemoteInstance(eventName, "RemoteEvent") :: RemoteEvent
end

local function getFunction(functionName: string): RemoteFunction
	return _getRemoteInstance(functionName, "RemoteFunction") :: RemoteFunction
end

local function getBindableEvent(functionName: string): BindableEvent
	return _getBindableInstance(functionName, "BindableEvent") :: BindableEvent
end

local function getBindableFunction(functionName: string): BindableFunction
	return _getBindableInstance(functionName, "BindableFunction") :: BindableFunction
end

return {
	getEvent = getEvent,
	getFunction = getFunction,
	getBindableEvent = getBindableEvent,
	getBindableFunction = getBindableFunction,
}
-- so this IS a ModuleScript!
