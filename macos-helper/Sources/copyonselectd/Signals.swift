import Dispatch

/// Signal sources must stay alive for the life of the process.
var signalSources: [DispatchSourceSignal] = []
