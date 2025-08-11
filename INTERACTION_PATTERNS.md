# Overview

With `StorageManager` enabled in SSUs - inventory interaction can be broken down into 3 types:
- Primary Inventory - The location that owner of SSU deposits into by default. 
	- Primary Inventory can be further subdivided into "Aggregated StorageManager Inventory" (the allocation of Primary Inventory to all `StorageManager` buckets - (checkable via `InventoryBalance[smartStorageId][itemId].quantity` for the relevant `smartStorageId`) and "Owner inventory" (whatever is left when checking the quantity for `InventoryItem[smartStorageId][itemId].quantity - InventoryBalance[smartStorageId][itemId].quantity`)
- Ephemeral Inventory - The location that non-owner of SSU deposits into by default.
- Bucket Inventory - Allocated primary inventory.

#### High level note
- `Primary Inventory <=> Bucket` && `Bucket <=> Bucket` interactions don't actually /move/ items around. They just change allocation of display within primary inventory. As such - they're cheaper, gas-wise than moving things back and forth to ephemeral (which require a lot of WorldContext checks)
- In the `StorageManager` contract - `deposit` and `withdraw` functions can `deposit/withdraw` to the bucket from both the ephemeral inventory AND the primary inventory. Which one it should pull from depends on the `useOwnerInventory` boolean parameter.
### Permissions
- On initial setup - a UI should ask the **SSU OWNER** to grant permissions for interactions with the SSU to a `StoreProxySystem` contract which exposes some `proxy` interactions with primitive `ephemeralInteracySystem` and `inventoryInteractSystem` . This is necessary, because it allows us to in-place upgrade the `StorageManager` and `StoreLogic` systems without needing to have users re-authorize the `StorageManager` contracts every time it's re-deployed.

# Design Overview
<img width="3104" height="1396" alt="image" src="https://github.com/user-attachments/assets/1fdc06b3-d259-4989-b6e7-2eaa95ffd5da" />


*(in a `StorageManager` world)*
## Source Inventory:
### Owner Inventory
#### Transfer to a different Owner Inventory (primary => primary)
*Uses `world-chain-v2` contracts directly*
- *May throw if no permission: `AccessSystemLib.Access*NotDirectOwnerOrCanTransferToInventory`. To set permissions (callable by owner of source primary inventory): `inventoryInteractSystem.setTransferToInventoryAccess()`*

To invoke: `inventoryInteractSystem.transferToInventory()`
#### Transfer to Ephemeral Inventory (primary => ephemeral)
- *Uses `world-chain-v2` contracts directly*
- *Currently, this is not possible for the owner of the primary inventory.*

To invoke: `ephemeralInteractSystem.transferToEphemeral()`
#### Transfer to Bucket Inventory (primary => bucket)
Uses `StorageManager` contracts

- *May throw if no permissions: `UnauthorizedDeposit`.  To set deposit permissions (callable by owner of recipient bucket): `storeAuthSystem.setAccessSystemId()` for the recipient bucket that points at a system with a `canDeposit()` function that allows you deposit


To Invoke: `StorageSystem.deposit()` (you will need to invoke with the the `bool useOwnerInventory` property as `true`)

### Ephemeral Inventory
#### Transfer to Owner Inventory (ephemeral => primary)
*Uses `world-chain-v2` contracts directly*
- *May throw if no permission: `AccessSystemLib.Access*CannotTransferFromEphemeral`. To set permissions (callable by owner of ephemeral inventory): `ephemeralInteractSystem.setTransferToInventoryAccess()`

To Invoke: `ephemeralInteractSystem.transferFromEphemeral()`

#### Transfer to a different Ephemeral Inventory (ephemeral => ephemeral)
*Uses `world-chain-v2` contracts directly*
*May throw if no permission: `AccessSystemLib.Access*CannotTransferFromEphemeral`. To set permissions (callable by owner of ephemeral inventory): `ephemeralInteractSystem.setTransferFromEphemeralAccess()`*

To Invoke: `ephemeralInteractSystem.crossTransferToEphemeral()`

#### Transfer to Bucket Inventory (ephemeral => bucket)
*Uses `StorageManager` contracts

- *May throw if no permissions: `UnauthorizedDeposit`.  To set deposit permissions (callable by owner of recipient bucket): `storeAuthSystem.setAccessSystemId()` for the recipient bucket that points at a system with a `canDeposit()` function that allows you deposit

- *May throw if no permission: `AccessSystemLib.Access*CannotTransferFromEphemeral`. To set permissions (callable by owner of ephemeral inventory): `ephemeralInteractSystem.setTransferFromEphemeralAccess()`*


To Invoke: `StorageSystem.deposit()` (you will need to invoke with the the `bool useOwnerInventory` property as `false`)

### Bucket Inventory

#### Transfer to Owner Inventory (bucket => primary)
*Uses `StorageManager` contracts*

- *May throw if no permissions: `UnauthorizedWithdraw`.  To set withdraw permissions (callable by owner of recipient bucket): `storeAuthSystem.setAccessSystemId()` for the sender bucket that points at a system with a `canWithdraw()` function that allows you withdraw.*

To invoke: `StorageSystem.withdraw()` (you will need to invoke with the the `bool useOwnerInventory` property as `true`)

#### Transfer to Ephemeral Inventory (bucket => ephemeral)
*Uses `StorageManager` contracts*

- *May throw if no permissions: `UnauthorizedWithdraw`.  To set withdraw permissions (callable by owner of recipient bucket): `storeAuthSystem.setAccessSystemId()` for the sender bucket that points at a system with a `canWithdraw()` function that allows you withdraw.*
- *May throw if no permission: `AccessSystemLib.Access*CannotTransferToEphemeral`. To set permissions (callable by owner of ephemeral inventory): `ephemeralInteractSystem.setTransferToEphemeralAccess()

To invoke: `StorageSystem.withdraw()`  (you will need to invoke with the the `bool useOwnerInventory` property as `false`)

#### Transfer to a different Bucket Inventory (bucket => bucket)
*Uses `StorageManager` contracts*

- *May throw if no permissions: `UnauthorizedWithdraw`.  To set withdraw permissions (callable by owner of recipient bucket): `storeAuthSystem.setAccessSystemId()` for the sender bucket that points at a system with a `canWithdraw()` function that allows you withdraw.*

- *May throw if no permissions: `UnauthorizedDeposit`.  To set deposit permissions (callable by owner of recipient bucket): `storeAuthSystem.setAccessSystemId()` for the recipient bucket that points at a system with a `canDeposit()` function that allows you deposit

To invoke: `StorageSystem.internalTransfer()`



