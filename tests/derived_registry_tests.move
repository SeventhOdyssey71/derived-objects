#[test_only]
module derived_objects_examples::derived_registry_tests {
    use derived_objects_examples::derived_registry::{Self, Registry, UserEntry};
    use sui::test_scenario::{Self as ts};

    const ALICE: address = @0xA11CE;
    const BOB: address = @0xB0B;

    #[test]
    fun test_init() {
        let mut scenario = ts::begin(ALICE);
        
        // Initialize
        derived_registry::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, ALICE);
        
        // Check registry exists
        let registry = ts::take_shared<Registry>(&scenario);
        assert!(derived_registry::get_total_registered(&registry) == 0, 0);
        
        ts::return_shared(registry);
        ts::end(scenario);
    }

    #[test]
    fun test_register() {
        let mut scenario = ts::begin(ALICE);
        
        // Initialize
        derived_registry::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, ALICE);
        
        // Register Alice
        let mut registry = ts::take_shared<Registry>(&scenario);
        let data = b"alice_data";
        
        assert!(!derived_registry::is_registered(&registry, ALICE), 0);
        
        derived_registry::register(&mut registry, data, ts::ctx(&mut scenario));
        
        assert!(derived_registry::is_registered(&registry, ALICE), 1);
        assert!(derived_registry::get_total_registered(&registry) == 1, 2);
        
        ts::return_shared(registry);
        ts::end(scenario);
    }

    #[test]
    fun test_derived_addresses() {
        let mut scenario = ts::begin(ALICE);
        
        // Initialize
        derived_registry::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, ALICE);
        
        let registry = ts::take_shared<Registry>(&scenario);
        
        // Get derived addresses
        let alice_addr = derived_registry::get_user_address(&registry, ALICE);
        let bob_addr = derived_registry::get_user_address(&registry, BOB);
        
        // Should be different for different users
        assert!(alice_addr != bob_addr, 0);
        
        // Should be deterministic
        let alice_addr2 = derived_registry::get_user_address(&registry, ALICE);
        assert!(alice_addr == alice_addr2, 1);
        
        ts::return_shared(registry);
        ts::end(scenario);
    }

    #[test]
    fun test_multiple_registrations() {
        let mut scenario = ts::begin(ALICE);
        
        // Initialize
        derived_registry::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, ALICE);
        
        // Register Alice
        let mut registry = ts::take_shared<Registry>(&scenario);
        derived_registry::register(&mut registry, b"alice", ts::ctx(&mut scenario));
        ts::return_shared(registry);
        
        // Register Bob
        ts::next_tx(&mut scenario, BOB);
        let mut registry = ts::take_shared<Registry>(&scenario);
        derived_registry::register(&mut registry, b"bob", ts::ctx(&mut scenario));
        
        // Check both are registered
        assert!(derived_registry::is_registered(&registry, ALICE), 0);
        assert!(derived_registry::is_registered(&registry, BOB), 1);
        assert!(derived_registry::get_total_registered(&registry) == 2, 2);
        
        ts::return_shared(registry);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = derived_registry::EAlreadyRegistered)]
    fun test_cannot_register_twice() {
        let mut scenario = ts::begin(ALICE);
        
        // Initialize
        derived_registry::init_for_testing(ts::ctx(&mut scenario));
        ts::next_tx(&mut scenario, ALICE);
        
        // Register once
        let mut registry = ts::take_shared<Registry>(&scenario);
        derived_registry::register(&mut registry, b"data1", ts::ctx(&mut scenario));
        ts::return_shared(registry);
        
        // Try to register again (should fail)
        ts::next_tx(&mut scenario, ALICE);
        let mut registry = ts::take_shared<Registry>(&scenario);
        derived_registry::register(&mut registry, b"data2", ts::ctx(&mut scenario));
        
        ts::return_shared(registry);
        ts::end(scenario);
    }

    #[test]
    fun test_update_data() {
        let mut scenario = ts::begin(ALICE);
        
        // Create a test entry
        let mut entry = derived_registry::test_create_entry(
            ALICE,
            b"initial",
            ts::ctx(&mut scenario)
        );
        
        // Update data
        derived_registry::update_data(&mut entry, b"updated", ts::ctx(&mut scenario));
        
        // Verify update
        let data = derived_registry::get_user_data(&entry);
        assert!(data == &b"updated", 0);
        
        // Clean up
        sui::test_utils::destroy(entry);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = derived_registry::ENotOwner)]
    fun test_cannot_update_others_data() {
        let mut scenario = ts::begin(ALICE);
        
        // Create entry owned by Alice
        let mut entry = derived_registry::test_create_entry(
            ALICE,
            b"alice_data",
            ts::ctx(&mut scenario)
        );
        
        // Bob tries to update (should fail)
        ts::next_tx(&mut scenario, BOB);
        derived_registry::update_data(&mut entry, b"hacked", ts::ctx(&mut scenario));
        
        sui::test_utils::destroy(entry);
        ts::end(scenario);
    }
}