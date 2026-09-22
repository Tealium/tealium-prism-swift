A `Module` is the generic protocol that any plugin added to tealium must conform. 

Each module, then, can conform to each of the following protocols as well to add extra functionality:
- `Collector`: To enrich the collected `Dispatch`es with extra data.
- `Dispatcher`: To send the `Dispatch`es and their data outside of this SDK, potentially the Tealium Platform or a 3rd party Vendor.
- `Transformer`: The underlying protocol for modules that implement [Transformations](Transformations.html) — data modifications applied to dispatches before they reach dispatchers.

A module can also reach the other modules, by type or by protocol, through the `ModuleManager` it receives as `context.moduleManager`. See [Creating Custom Modules](CustomModules.html) for how to resolve one without assuming it has been created yet.
