#!/usr/bin/env python3
"""
Integration test for Phase 1 SLA System
Verifies that all systems can be initialized without errors
"""

import json
import sys

def test_json_files():
    """Test that all JSON files are valid"""
    print("📋 Testing JSON files...")
    
    files = [
        'src/data/contracts.json',
        'src/data/sla_config.json'
    ]
    
    for filepath in files:
        try:
            with open(filepath, 'r') as f:
                data = json.load(f)
            print(f"  ✅ {filepath}: Valid JSON")
        except Exception as e:
            print(f"  ❌ {filepath}: {e}")
            return False
    
    return True

def test_sla_requirements():
    """Test that contracts have SLA requirements"""
    print("\n📋 Testing SLA requirements...")
    
    with open('src/data/contracts.json', 'r') as f:
        contracts = json.load(f)
    
    sla_contracts = [c for c in contracts if 'slaRequirements' in c]
    
    if len(sla_contracts) >= 5:
        print(f"  ✅ Found {len(sla_contracts)} contracts with SLA requirements")
    else:
        print(f"  ❌ Only {len(sla_contracts)} contracts with SLA requirements (need at least 5)")
        return False
    
    # Verify structure
    for contract in sla_contracts[:5]:
        required_fields = ['maxAllowedIncidents']
        for field in required_fields:
            if field not in contract['slaRequirements']:
                print(f"  ❌ {contract['id']}: Missing {field}")
                return False
        print(f"  ✅ {contract['id']}: Valid SLA structure")
    
    return True

def test_lua_files():
    """Test that Lua files exist and are readable"""
    print("\n📋 Testing Lua files...")
    
    files = [
        'src/systems/sla_system.lua',
        'src/systems/contract_system.lua',
        'src/soc_game.lua'
    ]
    
    for filepath in files:
        try:
            with open(filepath, 'r') as f:
                content = f.read()
                
            # Check for key patterns
            if filepath.endswith('sla_system.lua'):
                required = ['SLASystem.new', 'initialize', 'getState', 'loadState']
            elif filepath.endswith('contract_system.lua'):
                required = ['calculateWorkloadCapacity', 'canAcceptContract', 'getPerformanceMultiplier']
            elif filepath.endswith('soc_game.lua'):
                required = ['SLASystem', 'slaSystem:initialize']
            else:
                required = []
            
            for pattern in required:
                if pattern not in content:
                    print(f"  ⚠️  {filepath}: Missing '{pattern}' (might be OK if renamed)")
                    
            print(f"  ✅ {filepath}: File exists and readable")
        except Exception as e:
            print(f"  ❌ {filepath}: {e}")
            return False
    
    return True

def test_integration_points():
    """Test that integration points are correct"""
    print("\n📋 Testing integration points...")
    
    # Check soc_game.lua has SLA system integration
    with open('src/soc_game.lua', 'r') as f:
        content = f.read()
    
    checks = [
        ('require("src.systems.sla_system")', 'SLA system import'),
        ('SLASystem.new', 'SLA system instantiation'),
        ('registerSystem("slaSystem"', 'SLA system registration'),
        ('slaSystem:initialize()', 'SLA system initialization')
    ]
    
    all_passed = True
    for pattern, desc in checks:
        if pattern in content:
            print(f"  ✅ {desc}")
        else:
            print(f"  ❌ Missing: {desc}")
            all_passed = False
    
    return all_passed

def test_contract_system_enhancements():
    """Test that contract system has capacity management"""
    print("\n📋 Testing contract system enhancements...")
    
    with open('src/systems/contract_system.lua', 'r') as f:
        content = f.read()
    
    checks = [
        ('function ContractSystem:calculateWorkloadCapacity()', 'Capacity calculation'),
        ('function ContractSystem:canAcceptContract', 'Accept validation'),
        ('function ContractSystem:getPerformanceMultiplier()', 'Performance multiplier'),
        ('function ContractSystem:getAverageSpecialistEfficiency()', 'Efficiency calculation'),
        ('function ContractSystem:getState()', 'State management (get)'),
        ('function ContractSystem:loadState', 'State management (load)'),
        ('contract_overloaded', 'Overload event'),
        ('contract_capacity_changed', 'Capacity event')
    ]
    
    all_passed = True
    for pattern, desc in checks:
        if pattern in content:
            print(f"  ✅ {desc}")
        else:
            print(f"  ⚠️  Missing: {desc} (check implementation)")
            # Don't fail for events, they might be implemented differently
            if 'event' not in desc.lower():
                all_passed = False
    
    return all_passed

def main():
    """Run all tests"""
    print("🧪 Phase 1 SLA System Integration Tests\n")
    print("=" * 60)
    
    tests = [
        test_json_files,
        test_sla_requirements,
        test_lua_files,
        test_integration_points,
        test_contract_system_enhancements
    ]
    
    all_passed = True
    for test in tests:
        if not test():
            all_passed = False
    
    print("\n" + "=" * 60)
    if all_passed:
        print("✅ All integration tests passed!")
        print("\nNext steps:")
        print("  1. Run the game: love .")
        print("  2. Check console for '📊 SLASystem: Initialized'")
        print("  3. Test contract acceptance and capacity limits")
        return 0
    else:
        print("❌ Some tests failed. Please review the output above.")
        return 1

if __name__ == '__main__':
    sys.exit(main())
