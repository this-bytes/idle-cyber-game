#!/usr/bin/env python3
"""
Test script for the Cyberspace Tycoon Flask API CRUD endpoints.
Tests all game mechanics CRUD operations: Skills, Specialists, Achievements, Items.
"""

import requests
import json
import sys

BASE_URL = "http://localhost:5001"

def test_endpoint(method, endpoint, data=None, expected_status=200):
    """Test a single API endpoint."""
    url = f"{BASE_URL}{endpoint}"
    
    try:
        if method == "GET":
            response = requests.get(url)
        elif method == "POST":
            response = requests.post(url, json=data)
        elif method == "PUT":
            response = requests.put(url, json=data)
        elif method == "DELETE":
            response = requests.delete(url)
        else:
            print(f"❌ {method} {endpoint} - Unknown method")
            return False
        
        if response.status_code == expected_status:
            print(f"✅ {method} {endpoint} - Status: {response.status_code}")
            return True
        else:
            print(f"❌ {method} {endpoint} - Expected: {expected_status}, Got: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ {method} {endpoint} - Connection error: {e}")
        return False

def main():
    """Run all CRUD API tests."""
    print("🧪 Testing Cyberspace Tycoon CRUD API endpoints...")
    print("Make sure the Flask server is running on localhost:5001")
    print()
    
    tests_passed = 0
    total_tests = 0
    
    # Test Skills CRUD
    print("🛠️ Testing Skills CRUD Operations:")
    
    # Test 1: List skills (should be empty initially for new ones)
    total_tests += 1
    if test_endpoint("GET", "/api/skills"):
        tests_passed += 1
    
    # Test 2: Create a skill
    total_tests += 1
    skill_data = {
        "id": "test_skill",
        "name": "Test Skill",
        "description": "A test skill for API validation",
        "category": "testing",
        "maxLevel": 5,
        "baseXpCost": 50,
        "xpGrowth": 1.5,
        "prerequisites": [],
        "unlockRequirements": {},
        "effects": {"efficiency": 0.1}
    }
    if test_endpoint("POST", "/api/skills", skill_data, 201):
        tests_passed += 1
    
    # Test 3: Get specific skill
    total_tests += 1
    if test_endpoint("GET", "/api/skills/test_skill"):
        tests_passed += 1
    
    # Test 4: Update skill
    total_tests += 1
    update_data = {"description": "Updated description", "maxLevel": 8}
    if test_endpoint("PUT", "/api/skills/test_skill", update_data):
        tests_passed += 1
    
    # Test 5: Delete skill
    total_tests += 1
    if test_endpoint("DELETE", "/api/skills/test_skill"):
        tests_passed += 1
    
    print()
    print("👥 Testing Specialists CRUD Operations:")
    
    # Test 6: List specialists
    total_tests += 1
    if test_endpoint("GET", "/api/specialists"):
        tests_passed += 1
    
    # Test 7: Create a specialist
    total_tests += 1
    specialist_data = {
        "specialistType": "test_specialist",
        "name": "Test Specialist",
        "description": "A test specialist for API validation",
        "efficiency": 1.5,
        "speed": 1.2,
        "trace": 1.1,
        "defense": 1.3,
        "cost": {"money": 10000, "reputation": 5},
        "abilities": ["test_ability", "another_ability"],
        "tier": 2
    }
    if test_endpoint("POST", "/api/specialists", specialist_data, 201):
        tests_passed += 1
    
    # Test 8: Get specific specialist (ID 1 should exist from creation)
    total_tests += 1
    if test_endpoint("GET", "/api/specialists/1"):
        tests_passed += 1
    
    # Test 9: Update specialist
    total_tests += 1
    update_data = {"efficiency": 2.0, "description": "Updated specialist"}
    if test_endpoint("PUT", "/api/specialists/1", update_data):
        tests_passed += 1
    
    print()
    print("🏆 Testing Achievements CRUD Operations:")
    
    # Test 10: List achievements
    total_tests += 1
    if test_endpoint("GET", "/api/achievements"):
        tests_passed += 1
    
    # Test 11: Create an achievement
    total_tests += 1
    achievement_data = {
        "id": "test_achievement",
        "name": "Test Achievement",
        "description": "A test achievement for API validation",
        "requirement": {"type": "test", "value": 10},
        "reward": {"type": "money", "value": 500},
        "unlocked": False,
        "hidden": False
    }
    if test_endpoint("POST", "/api/achievements", achievement_data, 201):
        tests_passed += 1
    
    # Test 12: Get specific achievement
    total_tests += 1
    if test_endpoint("GET", "/api/achievements/test_achievement"):
        tests_passed += 1
    
    # Test 13: Update achievement
    total_tests += 1
    update_data = {"unlocked": True, "description": "Updated achievement"}
    if test_endpoint("PUT", "/api/achievements/test_achievement", update_data):
        tests_passed += 1
    
    print()
    print("📦 Testing Items CRUD Operations:")
    
    # Test 14: List items
    total_tests += 1
    if test_endpoint("GET", "/api/items"):
        tests_passed += 1
    
    # Test 15: Create an item
    total_tests += 1
    item_data = {
        "itemId": "test_item",
        "name": "Test Item",
        "description": "A test item for API validation",
        "category": "testing",
        "rarity": "rare",
        "cost": {"money": 1000},
        "sellValue": 500,
        "effects": {"efficiency": 0.2, "speed": 0.1},
        "stackable": True,
        "consumable": False,
        "maxStack": 10
    }
    if test_endpoint("POST", "/api/items", item_data, 201):
        tests_passed += 1
    
    # Test 16: Get specific item (ID 1 should exist from creation)
    total_tests += 1
    if test_endpoint("GET", "/api/items/1"):
        tests_passed += 1
    
    # Test 17: Update item
    total_tests += 1
    update_data = {"sellValue": 750, "description": "Updated item"}
    if test_endpoint("PUT", "/api/items/1", update_data):
        tests_passed += 1
    
    print()
    print("🚫 Testing Error Handling:")
    
    # Test 18: Get non-existent skill
    total_tests += 1
    if test_endpoint("GET", "/api/skills/nonexistent", expected_status=404):
        tests_passed += 1
    
    # Test 19: Create skill with duplicate ID
    total_tests += 1
    if test_endpoint("POST", "/api/skills", {
        "id": "basic_analysis",  # This should already exist
        "name": "Duplicate",
        "category": "test"
    }, expected_status=409):
        tests_passed += 1
    
    # Test 20: Create skill with missing required field
    total_tests += 1
    if test_endpoint("POST", "/api/skills", {
        "name": "No ID"
        # Missing required 'id' field
    }, expected_status=400):
        tests_passed += 1
    
    print()
    print(f"📊 Test Results: {tests_passed}/{total_tests} tests passed")
    
    if tests_passed == total_tests:
        print("🎉 All CRUD tests passed! API is working correctly.")
        return True
    else:
        print("⚠️  Some tests failed. Check the API implementation.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)