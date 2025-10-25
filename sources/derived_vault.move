/// Vault system utilizing derived objects for deterministic addressing.
/// Each user can have one vault at a predictable address derived from their wallet.
module derived_objects_examples::derived_vault;

use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::derived_object;
use sui::sui::SUI;
use sui::transfer::Receiving;

/// Vault already exists for this user
const EVaultAlreadyExists: u64 = 0;
/// Insufficient balance for withdrawal
const EInsufficientBalance: u64 = 1;
/// Caller is not the vault owner
const ENotAuthorized: u64 = 2;
/// Vault does not exist for recipient
const EVaultDoesNotExist: u64 = 3;

/// Registry tracking all vaults
public struct VaultRegistry has key {
    id: UID,
    total_vaults: u64,
}

/// User vault storing SUI balance
public struct Vault has key {
    id: UID,
    owner: address,
    balance: Balance<SUI>,
}

fun init(ctx: &mut TxContext) {
    transfer::share_object(VaultRegistry {
        id: object::new(ctx),
        total_vaults: 0,
    });
}

/// Creates a vault at the sender's deterministic address
entry fun create_vault(registry: &mut VaultRegistry, ctx: &mut TxContext) {
    let sender = ctx.sender();
    assert!(!vault_exists(registry, sender), EVaultAlreadyExists);
    
    // Claim derived address
    let uid = derived_object::claim(&mut registry.id, sender);
    object::delete(uid);
    
    let vault = Vault {
        id: object::new(ctx),
        owner: sender,
        balance: balance::zero(),
    };
    
    registry.total_vaults = registry.total_vaults + 1;
    
    let vault_address = get_vault_address(registry, sender);
    transfer::transfer(vault, vault_address);
}

/// Deposits SUI directly to a vault's derived address
entry fun deposit_to_derived(
    registry: &VaultRegistry,
    recipient: address,
    payment: Coin<SUI>,
) {
    assert!(vault_exists(registry, recipient), EVaultDoesNotExist);
    
    let vault_address = get_vault_address(registry, recipient);
    transfer::public_transfer(payment, vault_address);
}

/// Receives and adds a deposit to the vault balance
entry fun receive_deposit(
    vault: &mut Vault,
    payment: Receiving<Coin<SUI>>,
    ctx: &TxContext
) {
    assert!(vault.owner == ctx.sender(), ENotAuthorized);
    
    let coin = transfer::public_receive(&mut vault.id, payment);
    balance::join(&mut vault.balance, coin.into_balance());
}

/// Withdraws SUI from the vault
entry fun withdraw(
    vault: &mut Vault,
    amount: u64,
    ctx: &mut TxContext
) {
    assert!(vault.owner == ctx.sender(), ENotAuthorized);
    assert!(vault.balance.value() >= amount, EInsufficientBalance);
    
    let withdrawn = coin::from_balance(
        vault.balance.split(amount),
        ctx
    );
    
    transfer::public_transfer(withdrawn, ctx.sender());
}

/// Returns the deterministic vault address for a user
public fun get_vault_address(registry: &VaultRegistry, user: address): address {
    derived_object::derive_address(registry.id.to_inner(), user)
}

/// Checks if a vault exists for the user
public fun vault_exists(registry: &VaultRegistry, user: address): bool {
    derived_object::exists(&registry.id, user)
}

/// Returns the vault's current balance
public fun get_balance(vault: &Vault): u64 {
    vault.balance.value()
}

/// Returns the total number of vaults created
public fun get_total_vaults(registry: &VaultRegistry): u64 {
    registry.total_vaults
}

/// Returns the vault owner
public fun get_owner(vault: &Vault): address {
    vault.owner
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}