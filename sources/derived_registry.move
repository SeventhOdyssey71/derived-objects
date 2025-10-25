/// Registry pattern using derived objects for deterministic addressing.
/// Demonstrates how to create user entries at predictable addresses.
module derived_objects_examples::derived_registry;

use sui::derived_object;

/// User already registered
const EAlreadyRegistered: u64 = 0;
/// Not the owner of entry
const ENotOwner: u64 = 2;
/// Data exceeds size limit
const EDataTooLarge: u64 = 3;

/// Maximum data size: 10KB
const MAX_DATA_SIZE: u64 = 10000;

/// Global registry managing derived addresses
public struct Registry has key {
    id: UID,
    total_registered: u64,
}

/// User entry at derived address
public struct UserEntry has key {
    id: UID,
    owner: address,
    data: vector<u8>,
    created_at: u64,
}

fun init(ctx: &mut TxContext) {
    transfer::share_object(Registry {
        id: object::new(ctx),
        total_registered: 0,
    });
}

/// Register user entry at derived address
entry fun register(
    registry: &mut Registry, 
    data: vector<u8>,
    ctx: &mut TxContext
) {
    let sender = ctx.sender();
    
    assert!(!is_registered(registry, sender), EAlreadyRegistered);
    assert!(data.length() <= MAX_DATA_SIZE, EDataTooLarge);
    
    // Claim and delete derived UID
    let uid = derived_object::claim(&mut registry.id, sender);
    object::delete(uid);
    
    let entry = UserEntry {
        id: object::new(ctx),
        owner: sender,
        data,
        created_at: ctx.epoch(),
    };
    
    let derived_addr = get_user_address(registry, sender);
    transfer::transfer(entry, derived_addr);
    
    registry.total_registered = registry.total_registered + 1;
}

/// Update entry data
entry fun update_data(
    entry: &mut UserEntry,
    new_data: vector<u8>,
    ctx: &TxContext
) {
    assert!(entry.owner == ctx.sender(), ENotOwner);
    assert!(new_data.length() <= MAX_DATA_SIZE, EDataTooLarge);
    
    entry.data = new_data;
}

/// Remove entry from registry
entry fun unregister(
    registry: &mut Registry,
    entry: UserEntry,
    ctx: &TxContext
) {
    assert!(entry.owner == ctx.sender(), ENotOwner);
    
    let UserEntry { id, owner: _, data: _, created_at: _ } = entry;
    object::delete(id);
    
    registry.total_registered = registry.total_registered - 1;
}

/// Get derived address for user
public fun get_user_address(registry: &Registry, user: address): address {
    derived_object::derive_address(registry.id.to_inner(), user)
}

/// Check if user is registered
public fun is_registered(registry: &Registry, user: address): bool {
    derived_object::exists(&registry.id, user)
}

/// Get user data reference
public fun get_user_data(entry: &UserEntry): &vector<u8> {
    &entry.data
}

/// Get entry owner
public fun get_owner(entry: &UserEntry): address {
    entry.owner
}

/// Get total registered users
public fun get_total_registered(registry: &Registry): u64 {
    registry.total_registered
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}

#[test_only]
public fun test_create_entry(owner: address, data: vector<u8>, ctx: &mut TxContext): UserEntry {
    UserEntry {
        id: object::new(ctx),
        owner,
        data,
        created_at: ctx.epoch(),
    }
}