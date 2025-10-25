# Sui Derived Objects Examples

A comprehensive repository demonstrating the use of derived objects in Sui Move, showcasing deterministic address generation and various practical use cases.

## What are Derived Objects?

Derived objects in Sui provide a way to create deterministic addresses based on a parent object and a key. This enables:

- **Predictable Addresses**: Generate addresses that can be computed off-chain before object creation
- **One-per-key Uniqueness**: Ensure only one object exists per key for a given parent
- **Efficient Discovery**: Easily find objects without querying or maintaining indices
- **Parallel Processing**: Avoid bottlenecks by not requiring parent object modifications

## Repository Structure

```
sui-derived-objects/
├── sources/
│   ├── derived_vault.move         # Vault with deterministic addresses
│   └── deterministic_addresses.move # User accounts at predictable addresses
├── tests/
│   └── derived_vault_tests.move   # Test suite
├── scripts/
│   └── deploy.sh                  # Deployment script
└── Move.toml                      # Package manifest
```

## Examples

### 1. Derived Vault (`derived_vault.move`)

A vault system where each user has a vault at a deterministic address derived from their account address.

**Key Features:**
- One vault per user at a predictable address
- Deposit and withdrawal functionality
- Balance tracking using Sui's native Balance type
- Transfer-to-derived-address pattern for receiving funds

**Usage:**
```move
// Create a vault (transfers to derived address)
derived_vault::create_vault(registry, ctx);

// Get vault address (can be computed off-chain)
let vault_addr = derived_vault::get_vault_address(registry, user);

// Send funds to vault's derived address
derived_vault::deposit_to_derived(registry, recipient, payment);

// Withdraw from vault
derived_vault::withdraw(vault, amount, ctx);
```

### 2. Deterministic Addresses (`deterministic_addresses.move`)

A registry system for user accounts that live at deterministic addresses, enabling direct messaging and interactions.

**Key Features:**
- User registration with unique usernames
- Deterministic account addresses based on user address
- Direct messaging between accounts
- Account discovery without database queries

**Usage:**
```move
// Register an account at deterministic address
deterministic_addresses::register_account(registry, username, ctx);

// Get account address (computable off-chain)
let account_addr = deterministic_addresses::get_account_address(registry, user);

// Send message to another user's account
deterministic_addresses::send_message(registry, recipient, content, ctx);

// Receive messages at your account
deterministic_addresses::receive_message(account, message, ctx);
```

## Key Concepts

### Deriving Addresses

Addresses are derived using a parent object's ID and a key:
```move
let address = derived_object::derive_address(parent_id, key);
```

This creates a deterministic address that:
- Is unique for each parent-key combination
- Can be computed without on-chain state access
- Remains constant across time

### Claiming Derived Objects

To mark a derived object as "claimed" and prevent duplicates:
```move
let uid = derived_object::claim(&mut parent.id, key);
// In current Sui version, we delete the UID if using transfer pattern
object::delete(uid);
```

### Transfer Pattern

Since Sui's verifier requires fresh UIDs from `object::new()`, we use a transfer pattern:
1. Create object with fresh UID from `object::new()`
2. Transfer it to the derived address
3. Mark the derived address as claimed

## Building and Testing

### Prerequisites

- Sui CLI installed ([Installation Guide](https://docs.sui.io/build/install))
- Git for cloning the repository

### Build the Package

```bash
sui move build
```

### Run Tests

```bash
sui move test
```

### Deploy to Network

```bash
# Make script executable
chmod +x scripts/deploy.sh

# Deploy to active network
./scripts/deploy.sh
```

## Common Use Cases

### 1. Per-User Configuration
Store user preferences at predictable addresses without maintaining a central index.

### 2. Soulbound Tokens
Create non-transferable tokens at derived addresses tied to user identities.

### 3. Pre-funded Accounts
Send funds to addresses before accounts are created, enabling gasless onboarding.

### 4. Cross-chain Bridging
Use deterministic addresses for bridge contracts to enable predictable cross-chain transfers.

### 5. Efficient Registries
Build registries where each entry lives at a predictable address based on its key.

## Design Patterns

### Pattern 1: Transfer to Derived
```move
// Create object and transfer to derived address
let obj = Object { id: object::new(ctx), ... };
let derived_addr = derived_object::derive_address(parent_id, key);
transfer::transfer(obj, derived_addr);
```

### Pattern 2: Receive at Derived
```move
// Receive objects sent to derived address
public entry fun receive_at_derived(
    obj: &mut Object,
    receiving: Receiving<Item>,
    ctx: &TxContext
) {
    let item = transfer::public_receive(&mut obj.id, receiving);
    // Process item...
}
```

### Pattern 3: Check Existence
```move
// Check if derived object exists before creation
if (!derived_object::exists(&parent.id, key)) {
    // Create new object...
}
```

## Best Practices

1. **Use Unique Keys**: Ensure keys are unique to prevent ID collisions
2. **Document Derived Addresses**: Make it clear which addresses are derived
3. **Handle Missing Objects**: Always check existence before assuming objects exist
4. **Consider Discovery**: Derived addresses improve discoverability
5. **Plan for Immutability**: Derived addresses cannot be changed once created

## Advantages of Derived Objects

- **No Central Registry**: Objects are discoverable without maintaining indices
- **Parallel Processing**: No bottleneck on parent object access
- **Gas Efficiency**: Reduced storage and computation costs
- **Composability**: Easy integration with other protocols
- **Predictability**: Addresses can be computed off-chain

## Security Considerations

- Derived addresses are deterministic - anyone can compute them
- Ensure proper access controls on derived objects
- Consider privacy implications of predictable addresses
- Validate ownership before allowing operations

## Contributing

Contributions are welcome! Please ensure:
- Code follows Sui Move best practices
- Tests are included for new features
- Documentation is updated

## License

This project is provided as-is for educational purposes. Use at your own risk.

## Resources

- [Sui Derived Objects Documentation](https://docs.sui.io/concepts/sui-move-concepts/derived-objects)
- [Sui Move Book](https://docs.sui.io/build/move)
- [Sui Developer Portal](https://sui.io/developers)

## Contact

For questions or feedback, please open an issue in this repository.