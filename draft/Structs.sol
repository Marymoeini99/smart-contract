// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Enums.sol";

    struct Stakeholder {
        mapping (address => Manufactury) _manufactury;
        mapping (address => Branch) _branch;
        mapping (address => _3pl) _3pl;
        mapping (address => Retailer) _retailer;
    }

    struct Manufactury {
        mapping (uint productID => Product) products;
        mapping (uint branchID => Branch) validBranch;
        mapping (uint _3plID => _3pl) trusted3pl;
        mapping (uint orderID => Order) orderState;
    }

    struct Branch {
        uint id;
        uint minOrderVolume;
        uint maxOrderVolume;
        address wallet;
        bool received;
        uint orderCount;
        uint orderLimit;
        string location;
        mapping (uint _3plID => _3pl) trusted3pl;
    }

    struct _3pl {
        uint id;
        bool received;
        address wallet;
        trusted_3pl who;
    }

    struct Retailer {
        uint id;
        address wallet;
        uint orderCount;
        string location;
    }

    struct Order {
        uint id;
        OrderStatus status;
        _3pl the3pl;
        Branch theBranch;
        uint orderVolume;
        uint orderValue;
    }

    struct Product {
        uint id;
        uint price;
        uint inStock;
    }
