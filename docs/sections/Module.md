A `Module` is the generic protocol that any plugin added to tealium must conform. 

Each module, then, can conform to each of the following protocols as well to add extra functionality:
- `Collector`: To enrich the collected `Dispatch`es with extra data.
- `Dispatcher`: To send the `Dispatch`es and their data outside of this SDK, potentially the Tealium Platform or a 3rd party Vendor.
- `Transformer`: To change or drop the `Dispatch`es and their data before reaching the `Dispatcher`s.
