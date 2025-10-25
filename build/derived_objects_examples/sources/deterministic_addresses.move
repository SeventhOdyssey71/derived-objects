/// Provides a registry system where user accounts live at deterministic addresses
/// derived from their wallet addresses. Enables direct peer-to-peer messaging
/// without central storage.
module derived_objects_examples::deterministic_addresses;

use std::string::String;
use sui::derived_object;
use sui::transfer::Receiving;

/// User attempted to register when already registered
const EAlreadyRegistered: u64 = 0;
/// Recipient is not registered in the system  
const ENotRegistered: u64 = 1;
/// Caller is not authorized to perform this action
const ENotAuthorized: u64 = 2;

/// Shared registry that manages user registration and address derivation
public struct Registry has key {
    id: UID,
    name: String,
    total_registered: u64,
}

/// User account stored at a deterministic address
public struct Account has key {
    id: UID,
    owner: address,
    username: String,
    created_at: u64,
}

/// Message that can be sent between accounts
public struct Message has key, store {
    id: UID,
    from: address,
    content: String,
}

fun init(ctx: &mut TxContext) {
    let registry = Registry {
        id: object::new(ctx),
        name: std::string::utf8(b"Account Registry"),
        total_registered: 0,
    };
    transfer::share_object(registry);
}

/// Creates a new account at the sender's deterministic address.
/// Fails if the sender is already registered.
entry fun register_account(
    registry: &mut Registry,
    username: String,
    ctx: &mut TxContext
) {
    let sender = ctx.sender();
    assert!(!is_registered(registry, sender), EAlreadyRegistered);
    
    let account = Account {
        id: object::new(ctx),
        owner: sender,
        username,
        created_at: ctx.epoch(),
    };
    
    // Claim the derived address slot
    let uid = derived_object::claim(&mut registry.id, sender);
    object::delete(uid);
    
    registry.total_registered = registry.total_registered + 1;
    
    let account_address = get_account_address(registry, sender);
    transfer::transfer(account, account_address);
}

/// Sends a message to another user's account address.
/// Fails if the recipient is not registered.
entry fun send_message(
    registry: &Registry,
    recipient: address,
    content: String,
    ctx: &mut TxContext
) {
    assert!(is_registered(registry, recipient), ENotRegistered);
    
    let message = Message {
        id: object::new(ctx),
        from: ctx.sender(),
        content,
    };
    
    let recipient_address = get_account_address(registry, recipient);
    transfer::transfer(message, recipient_address);
}

/// Receives a message at the account and transfers it to the owner.
/// Only the account owner can receive messages.
entry fun receive_message(
    account: &mut Account,
    message: Receiving<Message>,
    ctx: &TxContext
) {
    assert!(account.owner == ctx.sender(), ENotAuthorized);
    
    let msg = transfer::public_receive(&mut account.id, message);
    transfer::public_transfer(msg, account.owner);
}

/// Updates the account username. Only the owner can update.
entry fun update_username(
    account: &mut Account,
    new_username: String,
    ctx: &TxContext
) {
    assert!(account.owner == ctx.sender(), ENotAuthorized);
    account.username = new_username;
}

/// Returns the deterministic address for a user's account
public fun get_account_address(registry: &Registry, user: address): address {
    derived_object::derive_address(registry.id.to_inner(), user)
}

/// Checks if a user has registered an account
public fun is_registered(registry: &Registry, user: address): bool {
    derived_object::exists(&registry.id, user)
}

/// Returns account information as a tuple
public fun get_account_info(account: &Account): (address, String, u64) {
    (account.owner, account.username, account.created_at)
}

/// Returns message sender and content
public fun get_message_info(message: &Message): (address, String) {
    (message.from, message.content)
}

/// Returns the total number of registered accounts
public fun get_total_registered(registry: &Registry): u64 {
    registry.total_registered
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}