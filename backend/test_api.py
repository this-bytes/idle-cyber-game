#!/usr/bin/env python3
"""
Test script for the Cyberspace Tycoon Flask API.
Run this to validate all endpoints are working correctly.
"""

import requests
import json
import time
import sys

BASE_URL = "http://localhost:5000"

def test_endpoint(method, endpoint, data=None, expected_status=200):
    """Test a single API endpoint."""
    url = f"{BASE_URL}{endpoint}"
    
    try:
        if method == "GET":
            response = requests.get(url)
        elif method == "POST":
            response = requests.post(url, json=data, headers={'Content-Type': 'application/json'})
        elif method == "PUT":
            response = requests.put(url, json=data, headers={'Content-Type': 'application/json'})
        else:
            print(f"❌ Unsupported method: {method}")
            return False
        
        if response.status_code == expected_status:
            print(f"✅ {method} {endpoint} - Status: {response.status_code}")
            if response.headers.get('content-type', '').startswith('application/json'):
                result = response.json()
                if result.get('success', True):
                    return True
                else:
                    print(f"   Response: {result}")
                    return True
            return True
        else:
            print(f"❌ {method} {endpoint} - Expected: {expected_status}, Got: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ {method} {endpoint} - Connection error: {e}")
        return False

def main():
    """Run all API tests."""
    print("🧪 Testing Cyberspace Tycoon API endpoints...")
    print("Make sure the Flask server is running on localhost:5000")
    print()
    
    tests_passed = 0
    total_tests = 0
    
    # Test 1: Health check
    total_tests += 1
    if test_endpoint("GET", "/health"):
        tests_passed += 1
    
    # Test 2: Create player
    total_tests += 1
    if test_endpoint("POST", "/api/player/create", {
        "username": "apitest_player",
        "current_currency": 1500,
        "reputation": 10
    }, 201):
        tests_passed += 1
    
    # Test 3: Get player data
    total_tests += 1
    if test_endpoint("GET", "/api/player/apitest_player"):
        tests_passed += 1
    
    # Test 4: Save player data
    total_tests += 1
    if test_endpoint("POST", "/api/player/save", {
        "username": "apitest_player",
        "current_currency": 3000,
        "reputation": 50,
        "xp": 1000,
        "mission_tokens": 2
    }):
        tests_passed += 1
    
    # Test 5: List players (admin)
    total_tests += 1
    if test_endpoint("GET", "/admin/players"):
        tests_passed += 1
    
    # Test 6: Get global state (admin)
    total_tests += 1
    if test_endpoint("GET", "/admin/global"):
        tests_passed += 1
    
    # Test 7: Update global state (admin)
    total_tests += 1
    if test_endpoint("PUT", "/admin/global", {
        "base_production_rate": 1.2,
        "global_multiplier": 1.8,
        "max_players": 500
    }):
        tests_passed += 1
    
    # Test 8: Edit player (admin)
    total_tests += 1
    if test_endpoint("PUT", "/admin/player/1", {
        "current_currency": 5000,
        "prestige_level": 1
    }):
        tests_passed += 1
    
    # Test 9: Error handling - non-existent player
    total_tests += 1
    if test_endpoint("GET", "/api/player/nonexistent", expected_status=404):
        tests_passed += 1
    
    # Test 10: Error handling - duplicate player creation
    total_tests += 1
    if test_endpoint("POST", "/api/player/create", {
        "username": "apitest_player"
    }, 409):
        tests_passed += 1
    
    print()
    print(f"📊 Test Results: {tests_passed}/{total_tests} tests passed")
    
    if tests_passed == total_tests:
        print("🎉 All tests passed! API is working correctly.")
        return True
    else:
        print("⚠️  Some tests failed. Check the API implementation.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)