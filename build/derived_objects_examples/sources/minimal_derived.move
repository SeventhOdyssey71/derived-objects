/// Minimal derived objects example showing core concepts
module derived_objects_examples::minimal_derived;

use sui::derived_object;

/// Parent registry object
public struct Parent has key {
    id: UID,
    counter: u64,
}

/// Child at derived address
public struct Child has key {
    id: UID,
    value: u64,
    parent_ref: address,
}

fun init(ctx: &mut TxContext) {
    transfer::share_object(Parent {
        id: object::new(ctx),
        counter: 0,
    });
}

/// Create child at derived address for given key
entry fun create_child(
    parent: &mut Parent,
    key: u64,
    value: u64,
    ctx: &mut TxContext
) {
    // Claim and delete derived UID
    let uid = derived_object::claim(&mut parent.id, key);
    object::delete(uid);
    
    let child = Child {
        id: object::new(ctx),
        value,
        parent_ref: parent.id.to_address(),
    };
    
    let derived_addr = get_child_address(parent, key);
    transfer::transfer(child, derived_addr);
    
    parent.counter = parent.counter + 1;
}

/// Get deterministic child address
public fun get_child_address(parent: &Parent, key: u64): address {
    derived_object::derive_address(parent.id.to_inner(), key)
}

/// Check if child exists at key
public fun child_exists(parent: &Parent, key: u64): bool {
    derived_object::exists(&parent.id, key)
}

/// Get parent counter
public fun get_counter(parent: &Parent): u64 {
    parent.counter
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}