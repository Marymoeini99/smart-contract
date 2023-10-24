// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

enum trusted_3pl {
    None,
    Manufactury,
    Branch
}

enum OrderStatus {
    None,
    Proposed,
    Accepted,
    Pending,
    Delivering,
    Fulfilled
}
