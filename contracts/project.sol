// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title TimeLockedMultisigWill
/// @notice A multisig will contract that automatically executes inheritance transfers if the owner fails to "check in" within a given interval.
contract TimeLockedMultisigWill {
    address public owner;
    uint256 public lastCheckIn;
    uint256 public checkInInterval; // e.g., seconds
    address[] public executors;
    mapping(address => bool) public isExecutor;
    bool public executed;

    // Inheritance plan: heir => percentage (out of 100)
    mapping(address => uint8) public inheritance;

    event CheckIn(address indexed who, uint256 timestamp);
    event ExecutorAdded(address indexed executor);
    event ExecutorRemoved(address indexed executor);
    event WillExecuted(uint256 timestamp);

    /// @param _executors initial list of executors (must be at least one)
    /// @param _interval seconds between required check‑ins
    constructor(address[] memory _executors, uint256 _interval) {
        require(_executors.length >= 1, "Need at least 1 executor");
        owner = msg.sender;
        checkInInterval = _interval;
        lastCheckIn = block.timestamp;
        for (uint256 i = 0; i < _executors.length; i++) {
            executors.push(_executors[i]);
            isExecutor[_executors[i]] = true;
            emit ExecutorAdded(_executors[i]);
        }
    }

    /// @notice Owner calls this periodically to reset the timer
    function checkIn() external {
        require(msg.sender == owner, "Only owner");
        lastCheckIn = block.timestamp;
        emit CheckIn(msg.sender, block.timestamp);
    }

    /// @notice Add a new executor (only owner)
    function addExecutor(address _exec) external {
        require(msg.sender == owner, "Only owner");
        require(!isExecutor[_exec], "Already executor");
        executors.push(_exec);
        isExecutor[_exec] = true;
        emit ExecutorAdded(_exec);
    }

    /// @notice Remove an executor (only owner)
    function removeExecutor(address _exec) external {
        require(msg.sender == owner, "Only owner");
        require(isExecutor[_exec], "Not executor");
        isExecutor[_exec] = false;
        // remove from array
        for (uint i = 0; i < executors.length; i++) {
            if (executors[i] == _exec) {
                executors[i] = executors[executors.length - 1];
                executors.pop();
                break;
            }
        }
        emit ExecutorRemoved(_exec);
    }

    /// @notice Set inheritance plan (only owner)
    function setInheritance(address heir, uint8 percent) external {
        require(msg.sender == owner, "Only owner");
        require(percent > 0 && percent <= 100, "Invalid percent");
        inheritance[heir] = percent;
    }

    /// @notice Anyone can trigger execution after timeout
    function executeWill() external {
        require(!executed, "Already executed");
        require(block.timestamp > lastCheckIn + checkInInterval, "Still active");
        executed = true;
        emit WillExecuted(block.timestamp);

        uint256 totalBalance = address(this).balance;
        for (uint i = 0; i < executors.length; i++) {
            address heir = executors[i];
            uint8 pct = inheritance[heir];
            if (pct > 0) {
                uint256 amount = totalBalance * pct / 100;
                payable(heir).transfer(amount);
            }
        }
    }

    /// @notice Fallback to receive ETH for inheritance
    receive() external payable {}
}
